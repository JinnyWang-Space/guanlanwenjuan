import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import {
  AppStorageV2,
  LengthMetrics,
  LengthUnit,
  promptAction,
  SymbolGlyphModifier,
  TipsDialogV2,
  window
} from "@kit.ArkUI";
import {
  AnswerCloud,
  AppTmpViewModel,
  DistributedDB,
  Question,
  QuestionCloud,
  QuestionType,
  Survey,
  SurveyCloud,
  SurveyDescription,
  SurveyStatus,
  SurveyTemplate,
  WidthBreakpointType,
  WindowUtil
} from "common";
import { common } from "@kit.AbilityKit";
import { QuestionItem } from "../components/QuestionItem";
import { cloudDatabase } from "@kit.CloudFoundationKit";
import { McBarChart, Options } from '@mcui/mccharts'
import { image } from "@kit.ImageKit";
import { generateBarcode, scanCore } from "@kit.ScanKit";
import Logger from "common/src/main/ets/utils/Logger";
import { util } from "@kit.ArkTS";
import { BusinessError } from "@kit.BasicServicesKit"

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct CheckSurveyView {
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 用于监听侧边栏当前所选item对应的索引值
  @Consumer('sideBarMainIndex') sideBarMainIndex: number = 0;
  // 获取参数 —— 问卷 id
  private surveyId: number = this.pageInfos.getParamByName('CheckSurveyView')[0] as number;
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);
  // 创建问卷实例
  @Local survey: Survey | null = new Survey();
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  // 操作框
  @Local operationBox: string[] = ['预览', '编辑', '数据统计'];
  // 操作框索引值
  @Local operationIndex: number = 0;
  @Local description: string = '';
  @Local selectedValue: number = 0;
  // 菜单栏创建问卷图标
  @Local menuIconModifier1: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier2: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_on_circle_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier3: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_clipboard_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier4: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.doc_plaintext_fill')).fontSize('24vp').fontColor([Color.Gray]);
  // 创建滑动器实例
  private qScroller: Scroller = new Scroller();
  // 用于监听是否正在使用添加问题功能
  @Local isAdd: boolean = false;
  // 创建变量作为一个临时选项，用于嵌套数据的防抖（输入法的抖动），question中含有option字符串数组，不能直接在onChange()中更新组件状态
  @Local option: string = '';

  // 创建问题菜单
  @Builder
  createMenu() {
    Menu() {
      MenuItem({ symbolStartIcon: this.menuIconModifier1, content: "单选" })
        .onClick(() => {
          this.addNewQuestion(QuestionType.SINGLE_CHOICE, '', []);
          this.qScroller.scrollEdge(Edge.Bottom);
        })
      MenuItem({ symbolStartIcon: this.menuIconModifier2, content: "多选" })
        .onClick(() => {
          this.addNewQuestion(QuestionType.MULTIPLE_CHOICE, '', []);
          this.qScroller.scrollEdge(Edge.Bottom);
        })
      MenuItem({ symbolStartIcon: this.menuIconModifier3, content: "判断" })
        .onClick(() => {
          this.addNewQuestion(QuestionType.TEXT_ANSWER, '', []);
          this.qScroller.scrollEdge(Edge.Bottom);
        })
      MenuItem({ symbolStartIcon: this.menuIconModifier4, content: "文本" })
    }
  }

  // 划出组件 —— 当前用于删除问题
  @Builder
  itemEnd(questionIndex: number) {
    Row({ space: 16 }) {
      Button() {
        SymbolGlyph($r('sys.symbol.trash_fill'))
          .fontSize(24)
          .fontColor([Color.White])
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.survey!.questions.splice(questionIndex, 1);
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')
    .margin({ left: 24 })
  }

  @Local attributeShow: boolean =
    new WidthBreakpointType(true, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local contentShow: boolean =
    new WidthBreakpointType(false, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local attributeWidth: string = '100%';
  @Local contentWidth: string = '100%';
  @Local answer: AnswerCloud[] = []
  @Local questions: QuestionCloud[] = [];
  @Local answerSingle: number[][] = [];
  @Local answerMultiple: number[][] = [];

  async aboutToAppear(): Promise<void> {

    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.survey = await this.distributedDB.getSurveyById(this.surveyId);

    // console.error('csdjbcv', JSON.stringify(this.survey?.questions))

    this.description = this.survey!.description;
    if (this.survey!.status === SurveyStatus.DRAFT) {
      this.selectedValue = 1;
    }
    if (this.survey!.status === SurveyStatus.COLLECTING) {
      this.selectedValue = 0;
    }

    // if (this.survey?.id_cloud) {
    // 初始化存储区
    let databaseZone = cloudDatabase.zone('guanlanwenjuan');
    // 初始化查询
    let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);
    let questionCondition = new cloudDatabase.DatabaseQuery(QuestionCloud);

    surveyCondition.equalTo('id', this.survey?.id_cloud);
    let surveyCloud = await databaseZone.query(surveyCondition);

    let surveyId = surveyCloud[0].id;

    questionCondition.equalTo('survey_id', surveyId).orderByAsc('id');
    let questionCloud = await databaseZone.query(questionCondition)
    this.questions = questionCloud;

    for (let i = 0; i < this.questions.length; i++) {
      let answerCondition = new cloudDatabase.DatabaseQuery(AnswerCloud);
      answerCondition.equalTo('question_id', questionCloud[i].id)
      let answerCloud = await databaseZone.query(answerCondition)
      for (let u = 0; u < answerCloud.length; u++) {
        this.answer.push(answerCloud[u])
      }
    }

    this.answerSingle = this.calculateSingleChoiceStats(this.questions, this.answer);
    this.answerMultiple = this.calculateMultipleStats(this.questions, this.answer);

    // }


  }

  async aboutToDisappear(): Promise<void> {
    if (this.surveyId !== undefined) {
      this.survey!.id = this.surveyId;
      const success: boolean = await this.distributedDB.updateSurvey(this.survey as Survey);
      if (success) {
        this.refresh = true;
        promptAction.openToast({ message: '更新成功！' });
      } else {
        promptAction.openToast({ message: '更新失败' });
      }
    }
  }

  // 二维码图片
  @Local pixelMap: image.PixelMap | undefined = undefined;

  // 发放后呼出的弹窗
  @Builder
  dialog(title: string) {
    TipsDialogV2({
      imageRes: this.pixelMap,
      imageSize: { width: 200, height: 200 },
      // content: '是否保存该图片至图库',
      content: '请截图该二维码',
      title: title,
    })
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Column() {
          Row({ space: 12 }) {
            Button() {
              SymbolGlyph($r('sys.symbol.chevron_left'))
                .fontSize(24)
                .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            }
            .width(40)
            .height(40)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .onClick(() => {
              this.pageInfos.pop();
            })


            if (this.operationIndex === 1) {
              TextArea({ placeholder: '请输入您的问卷名称', text: this.survey!.title!! })
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            } else {
              Text(this.survey?.title)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .height(40)
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Blank()

          Divider().strokeWidth(0.5).color(Color.Gray)
            .margin({ top: new WidthBreakpointType(4, 4, 6).getValue(this.windowUtil.mainWindowInfo.widthBp) })

          if (this.sideBarMainIndex !== 1 && this.sideBarMainIndex !== 4) {
            Row({ space: 24 }) {
              ForEach(this.operationBox, (item: string, index: number) => {
                // 按中编辑按钮
                if (index === 1) {
                  Row({ space: 8 }) {
                    Button() {
                      Text(item)
                        .fontSize(this.operationIndex === index ? 18 : 16)
                        .fontWeight(FontWeight.Medium)
                    }
                    .backgroundColor(this.operationIndex === index ? $r('app.color.list_on_color') :
                      $r('sys.color.button_background_color_transparent'))
                    .borderRadius(18)
                    .padding({
                      top: 4,
                      bottom: 4,
                      left: 16,
                      right: 16
                    })
                    .onClick(() => {
                      this.operationIndex = index;
                    })

                    if (this.operationIndex === 1) {
                      Button() {
                        SymbolGlyph($r('sys.symbol.doc_plaintext_and_pencil_fill'))
                          .fontSize(24)
                          .fontColor([Color.Gray])
                      }
                      .width(36)
                      .height(36)
                      .borderRadius(18)
                      .backgroundColor(this.isAdd ? $r('app.color.list_on_color') :
                        $r('sys.color.ohos_id_color_background_transparent'))
                      .onClick(() => {
                        this.isAdd = true;
                      })
                      .bindMenu(this.createMenu)
                    }
                  }
                }
                // 按中预览与数据统计按钮
                else {
                  Button() {
                    Text(item)
                      .fontSize(this.operationIndex === index ? 18 : 16)
                      .fontWeight(FontWeight.Medium)
                  }
                  .backgroundColor(this.operationIndex === index ? $r('app.color.list_on_color') :
                    $r('sys.color.button_background_color_transparent'))
                  .borderRadius(18)
                  .padding({
                    top: 4,
                    bottom: 4,
                    left: 16,
                    right: 16
                  })
                  .onClick(() => {
                    this.operationIndex = index;
                  })
                }
              })
            }
            .width('100%')
            .height(40)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .height(
          this.sideBarMainIndex !== 1 && this.sideBarMainIndex !== 4 ?
            this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 32 :
            this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
        .justifyContent(FlexAlign.Start)
        .padding({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
          left: 16, right: 16
        })
        .zIndex(1)
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

        // 主题区域
        if (this.operationIndex < 2) {
          Row() {
            // 左区域
            if (this.attributeShow || this.windowUtil.mainWindowInfo.widthBp > WidthBreakpoint.WIDTH_SM) {
              Column() {
                Scroll() {
                  Column() {
                    // 顶部填充区域
                    Blank()
                      .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                        56 + 40)


                    // 问卷描述
                    Column() {
                      Text('问卷描述')
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                      if (this.operationIndex === 0) {
                        Text(this.survey?.description)
                          .fontSize(18)
                          .lineHeight(24)
                          .letterSpacing(2)
                          .margin({ top: 16, bottom: 16 })
                      } else {
                        TextArea({ placeholder: '请输入您的问卷描述', text: this.survey!.description!! })
                          .fontSize(18)
                          .lineHeight(24)
                          .letterSpacing(2)
                          .margin({ top: 16, bottom: 16 })
                      }
                    }
                    .width('100%')
                    .backgroundColor($r('sys.color.comp_background_primary'))
                    .borderRadius(20)
                    .padding(16)
                    .margin({ bottom: 24 })
                    .clickEffect({ level: ClickEffectLevel.LIGHT })

                    // 问卷问题数量
                    Column() {
                      Text('问题数量')
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                      Text(this.survey?.questions.length.toString())
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontStyle(FontStyle.Italic)
                        .margin({ top: 24, bottom: 6 })
                    }
                    .width('100%')
                    .backgroundColor($r('sys.color.comp_background_primary'))
                    .borderRadius(20)
                    .padding(16)
                    .margin({ bottom: 24 })
                    .clickEffect({ level: ClickEffectLevel.LIGHT })

                    // Text(JSON.stringify(this.questions))
                    // Text(JSON.stringify(this.answerSingle))
                    // Text(JSON.stringify(this.answerMultiple))

                    // 问卷状态
                    Column() {
                      Text('问卷状态')
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)

                      Row() {
                        ForEach(['立即发放', '暂不发放'], (item: string, index: number) => {
                          Column({ space: 6 }) {
                            Text(item)
                              .fontSize(18)
                            Radio({
                              value: item,
                              group: 'statusBox'
                            })
                              .checked(this.selectedValue === index)
                              .onChange(async (isChecked: boolean) => {
                                if (isChecked) {
                                  this.selectedValue = index;
                                  if (this.selectedValue === 0) {
                                    this.survey!.status = SurveyStatus.COLLECTING;
                                    // 当前有网络
                                    if (this.appTmpData.isNetwork) {
                                      // 当前云数据库存在该问卷
                                      if (this.survey!.id_cloud) {
                                        let databaseZone = cloudDatabase.zone('guanlanwenjuan');

                                        // 初始化查询
                                        let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);

                                        surveyCondition.equalTo('id', this.survey!.id_cloud)
                                        let surveyResult = await databaseZone.query(surveyCondition);
                                        let survey = surveyResult[0];
                                        try {
                                          survey.status = 'collecting';
                                          let record = await databaseZone.upsert(survey);
                                          Logger.info('[testTag]',
                                            `Succeeded in upserting a book, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[testTag]',
                                            `Failed to upsert a book, code: ${err.code}, message: ${err.message}`);
                                        }

                                        // 更新本地数据库
                                        this.survey!.status = SurveyStatus.COLLECTING;
                                        const success: boolean =
                                          await this.distributedDB.updateSurvey(this.survey as Survey);
                                        if (success) {
                                          this.refresh = true;
                                          promptAction.openToast({ message: '更新成功！' });
                                        } else {
                                          promptAction.openToast({ message: '更新失败' });
                                        }
                                      }
                                      // 当前云数据库还未存在该问卷
                                      else {
                                        // 以QR码为例，码图生成参数
                                        this.pixelMap = undefined;
                                        let content =
                                          'share_survey_' + Date.now().toLocaleString() + '_' +
                                          Math.floor(Math.random() * 10000).toString();
                                        // 配置信息
                                        let options: generateBarcode.CreateOptions = {
                                          scanType: scanCore.ScanType.QR_CODE,
                                          height: 400,
                                          width: 400
                                        }

                                        let databaseZone = cloudDatabase.zone('guanlanwenjuan');
                                        try {
                                          let survey = new SurveyCloud();
                                          survey.id = content;
                                          survey.title = this.survey!.title;
                                          survey.created_time = new Date(this.survey!.createdTime);
                                          survey.status = 'collecting';
                                          survey.deleted = this.survey!.deleted;
                                          let record = await databaseZone.upsert([survey]);
                                          Logger.info('[testTag]',
                                            `Succeeded in upserting a book, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[testTag]',
                                            `Failed to upsert a book, code: ${err.code}, message: ${err.message}`);
                                        }

                                        this.survey!.id_cloud = content;
                                        // 更新本地数据库
                                        const success: boolean =
                                          await this.distributedDB.updateSurvey(this.survey as Survey);
                                        if (success) {
                                          this.refresh = true;
                                          promptAction.openToast({ message: '更新成功！' });
                                        } else {
                                          promptAction.openToast({ message: '更新失败' });
                                        }

                                        // 进行描述的分片处理
                                        let description_len: number = this.survey!.description.length;
                                        let byteLength: number = 0;
                                        let description: string[] = [];
                                        let description_part: string = '';
                                        for (let i = 0; i < description_len; i++) {
                                          let part = this.survey!.description[i];
                                          let charBytes = new util.TextEncoder().encodeInto(part).length;
                                          if (byteLength + charBytes <= 200) {
                                            byteLength += charBytes;
                                            description_part += part;
                                          } else {
                                            description.push(description_part);
                                            byteLength = charBytes;
                                            description_part = part;
                                          }
                                        }
                                        if (description_part) {
                                          description.push(description_part);
                                        }
                                        description.map(async (des: string) => {
                                          try {
                                            let description = new SurveyDescription();
                                            description.id =
                                              'share_survey_description_' + Date.now().toLocaleString() + '_' +
                                              Math.floor(Math.random() * 10000).toString();
                                            description.description_part = des;
                                            description.survey_id = content;
                                            let record = await databaseZone.upsert([description]);
                                            Logger.info('[testTag]',
                                              `Succeeded in upserting a description, result: ${JSON.stringify(record)}`);
                                          } catch (err) {
                                            Logger.error('[testTag]',
                                              `Failed to upsert a description, code: ${err.code}, message: ${err.message}`);
                                          }
                                        })

                                        let indexx = '1';
                                        for (let i = 0; i < this.survey!.questions.length; i++) {
                                          const question = this.survey!.questions[i];
                                          try {
                                            let questionCloud = new QuestionCloud();
                                            questionCloud.id =
                                              'share_question_' + Date.now().toLocaleString() + '_' + indexx;
                                            questionCloud.survey_id = content;
                                            questionCloud.type = question.type as string;
                                            questionCloud.content = question.content;
                                            questionCloud.options = JSON.stringify(question.options) as string;
                                            questionCloud.required = true;
                                            let record = await databaseZone.upsert([questionCloud]);
                                            indexx += '1';
                                            Logger.info('[question]',
                                              `Succeeded in upserting a question, result: ${JSON.stringify(record)}`);
                                          } catch (err) {
                                            Logger.error('[question]',
                                              `Failed to upsert a question, code: ${err.code}, message: ${err.message}`);
                                          }
                                        }

                                        // 初始化存储区
                                        // let databaseZone = cloudDatabase.zone('guanlanwenjuan');
                                        // 初始化查询
                                        let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);
                                        let questionCondition = new cloudDatabase.DatabaseQuery(QuestionCloud);

                                        surveyCondition.equalTo('id', this.survey?.id_cloud);
                                        let surveyCloud = await databaseZone.query(surveyCondition);

                                        let surveyId = surveyCloud[0].id;

                                        questionCondition.equalTo('survey_id', surveyId).orderByAsc('id');
                                        let questionCloud = await databaseZone.query(questionCondition)
                                        this.questions = questionCloud;

                                        for (let i = 0; i < this.questions.length; i++) {
                                          let answerCondition = new cloudDatabase.DatabaseQuery(AnswerCloud);
                                          answerCondition.equalTo('question_id', questionCloud[i].id)
                                          let answerCloud = await databaseZone.query(answerCondition)
                                          for (let u = 0; u < answerCloud.length; u++) {
                                            this.answer.push(answerCloud[u])
                                          }
                                        }

                                        this.answerSingle =
                                          this.calculateSingleChoiceStats(this.questions, this.answer);
                                        this.answerMultiple = this.calculateMultipleStats(this.questions, this.answer);

                                        // 生成二维码图片
                                        try {
                                          // 码图生成接口，成功返回PixelMap格式图片
                                          generateBarcode.createBarcode(content, options)
                                            .then(async (pixelMap: image.PixelMap) => {
                                              this.pixelMap = pixelMap;
                                              promptAction.openToast({ message: '二维码生成成功' })
                                            })
                                            .catch((error: BusinessError) => {
                                              console.error('[generateBarcode]',
                                                `Failed to get PixelMap by promise with options. Code: ${JSON.stringify(error.code)},message:${error.message}`);
                                            })
                                        } catch (error) {
                                          console.error('[generateBarcode]',
                                            `Failed to createBarcode by promise with options. Code: ${error.code}, message: ${error.message}`);
                                        }

                                        // 呼出弹窗
                                        this.getUIContext().getPromptAction().openCustomDialog({
                                          builder: () => {
                                            this.dialog(this.survey!.title);
                                          },
                                          onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                                            // 三键，手势，esc返回
                                            if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
                                              dismissDialogAction.dismiss();
                                            }
                                            // 关闭按钮返回
                                            if (dismissDialogAction.reason === DismissReason.CLOSE_BUTTON) {
                                              dismissDialogAction.dismiss();
                                            }
                                          }
                                        })

                                      }
                                    }
                                    // 当前无网络
                                    else {
                                      promptAction.openToast({ message: '请先连接网络！', textColor: Color.Red })
                                    }
                                  } else {
                                    // 当前有网络
                                    if (this.appTmpData.isNetwork) {
                                      // 云数据库存在该问卷数据
                                      if (this.survey!.id_cloud) {
                                        let databaseZone = cloudDatabase.zone('guanlanwenjuan');

                                        // 初始化查询
                                        let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);

                                        surveyCondition.equalTo('id', this.survey!.id_cloud)
                                        let surveyResult = await databaseZone.query(surveyCondition);
                                        let survey = surveyResult[0];
                                        try {
                                          survey.status = 'draft';
                                          let record = await databaseZone.upsert(survey);
                                          Logger.info('[testTag]',
                                            `Succeeded in upserting a book, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[testTag]',
                                            `Failed to upsert a book, code: ${err.code}, message: ${err.message}`);
                                        }

                                        // 更新本地数据库
                                        this.survey!.status = SurveyStatus.DRAFT;
                                        const success: boolean =
                                          await this.distributedDB.updateSurvey(this.survey as Survey);
                                        if (success) {
                                          this.refresh = true;
                                          promptAction.openToast({ message: '更新成功！' });
                                        } else {
                                          promptAction.openToast({ message: '更新失败' });
                                        }
                                      }
                                    }
                                    // 当前无网络
                                    else {
                                      promptAction.openToast({ message: '请先连接网络！', textColor: Color.Red })
                                    }
                                  }
                                }
                              })
                              .enabled(this.operationIndex === 0 ? false : true)
                          }
                          .layoutWeight(1)
                        })
                      }
                      .width('100%')
                      .margin({ top: 36, bottom: 16 })
                    }
                    .width('100%')
                    .backgroundColor($r('sys.color.comp_background_primary'))
                    .borderRadius(20)
                    .padding(16)
                    .margin({ bottom: 24 })
                    .clickEffect({ level: ClickEffectLevel.LIGHT })
                  }
                }
                .layoutWeight(1)
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
              }
              .width(new WidthBreakpointType(this.attributeShow ? '100%' : '0', '45%',
                '45%').getValue(this.windowUtil.mainWindowInfo.widthBp))
              .padding({
                left: new WidthBreakpointType(16, 16, 64).getValue(this.windowUtil.mainWindowInfo.widthBp),
                right: new WidthBreakpointType(16, 16, 64).getValue(this.windowUtil.mainWindowInfo.widthBp)
              })
            }

            // 分割线
            if (this.windowUtil.mainWindowInfo.widthBp > WidthBreakpoint.WIDTH_SM) {
              Row()
                .width(8)
                .height(100)
                .backgroundColor(Color.Gray)
                .borderRadius(20)
            }

            // 右区域
            if (this.contentShow || this.windowUtil.mainWindowInfo.widthBp > WidthBreakpoint.WIDTH_SM) {
              Column() {
                // 问题列表
                List({ space: 24, scroller: this.qScroller }) {
                  ForEach(this.survey?.questions, (question: Question, questionIndex: number) => {
                    ListItem() {
                      Column() {
                        // 类型 + 标题
                        RelativeContainer() {
                          Text(question.type)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .backgroundColor($r('sys.color.button_background_color_transparent'))
                            .borderRadius(20)
                            .padding({
                              top: 4,
                              bottom: 4,
                              left: 16,
                              right: 16
                            })
                            .alignRules({
                              left: { anchor: '__container__', align: HorizontalAlign.Start },
                              center: { anchor: '__container__', align: VerticalAlign.Center }
                            })

                          Text() {
                            Span(`第`)
                            Span(` ${1 + questionIndex} `).fontSize(22)
                            Span(`题`)
                          }
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
                          .alignRules({
                            middle: { anchor: '__container__', align: HorizontalAlign.Center },
                            center: { anchor: '__container__', align: VerticalAlign.Center }
                          })
                        }
                        .width('100%')
                        .height(34)

                        // 问题
                        if (this.operationIndex === 0) {
                          Row() {
                            Text(question.content)
                              .fontSize(18)
                              .fontWeight(FontWeight.Medium)
                          }
                          .width('100%')
                          .borderRadius(20)
                          .padding({ left: 16, right: 16 })
                          .margin({ top: 16, bottom: 16 })
                        }
                        if (this.operationIndex === 1) {
                          TextArea({ placeholder: '请输入您的问题', text: question.content!! })
                            .margin({ top: 16, bottom: 16 })
                        }

                        // 选项
                        List({ space: 8 }) {
                          ForEach(question.options, (option: string, optionIndex: number) => {
                            ListItem() {
                              if (question.type !== QuestionType.TEXT_ANSWER) {
                                Row({ space: 8 }) {
                                  if (this.operationIndex === 0) {
                                    Checkbox({ name: `${question.type}_option_${1 + optionIndex}` })
                                      .enabled(false)
                                    Text(option)
                                      .fontSize(16)
                                      .layoutWeight(1)
                                  }
                                  if (this.operationIndex === 1) {
                                    Text(`${String.fromCharCode(65 + optionIndex)} .`)
                                      .margin({ left: 8 })
                                    TextArea({
                                      placeholder: `请输入您选项 ${String.fromCharCode(65 + optionIndex)} 的问题`,
                                      text: option
                                    })
                                      .onChange((value: string) => {
                                        // 只更新 UI ，用于嵌套数据的防抖
                                        this.option = value;
                                      })
                                      .onBlur(() => {
                                        // 失去焦点后，进行组件状态更新
                                        this.survey!.questions[questionIndex].options[optionIndex] = this.option;
                                      })
                                      .layoutWeight(1)
                                  }

                                }
                                .width('100%')
                                .padding({ left: 6, right: 6 })
                              }
                            }
                          }, (option: string, optionIndex: number) => option + optionIndex)
                        }

                        // 添加选项按钮
                        if (this.operationIndex === 1) {
                          Button() {
                            Row({ space: 8 }) {
                              SymbolGlyph(this.getTypeSymbol(question.type))
                                .fontSize(24)
                                .fontColor([Color.Gray])
                              Text(`添加 ${question.type}`)
                            }
                          }
                          .width('100%')
                          .backgroundColor($r('sys.color.button_background_color_transparent'))
                          .borderRadius(20)
                          .padding({ top: 12, bottom: 12 })
                          .margin({ top: 16 })
                          .onClick(() => {
                            this.survey!.questions[questionIndex].options.push('');
                          })
                          .clickEffect({ level: ClickEffectLevel.LIGHT })
                        }

                      }
                      .width('100%')
                      .backgroundColor($r('sys.color.comp_background_primary'))
                      .borderRadius(20)
                      .padding(12)
                      .clickEffect({ level: ClickEffectLevel.LIGHT })
                    }
                    .swipeAction({
                      end: {
                        builder: () => {
                          this.operationIndex === 1 ? this.itemEnd(questionIndex) : () => {
                          };
                        }
                      }
                    })
                  }, (question: Question, index: number) => JSON.stringify(question) + index)
                    .onMove((from: number, to: number) => {
                      if (this.operationIndex === 1) {
                        let tmp = this.survey!.questions.splice(from, 1);
                        this.survey!.questions.splice(to, 0, tmp[0]);
                      }
                    })
                }
                .width('100%')
                .layoutWeight(1)
                .contentStartOffset(this.getUIContext()
                  .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 40)
                .contentEndOffset(new WidthBreakpointType(80, 24, 24).getValue(this.windowUtil.mainWindowInfo.widthBp))
                .scrollBar(BarState.Off)
                .padding({
                  left: new WidthBreakpointType(16, 16, 96).getValue(this.windowUtil.mainWindowInfo.widthBp),
                  right: new WidthBreakpointType(16, 16, 96).getValue(this.windowUtil.mainWindowInfo.widthBp)
                })
              }
              .width(new WidthBreakpointType(this.contentShow ? '100%' : '0', '55%',
                '55%').getValue(this.windowUtil.mainWindowInfo.widthBp))
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
        if (this.operationIndex === 2) {
          if (this.survey?.id_cloud) {
            if (this.appTmpData.isNetwork) {
              List({ space: 24 }) {
                ForEach(this.survey?.questions, (question: Question, questionIndex: number) => {
                  ListItem() {
                    Column() {
                      if (questionIndex === 0) {
                        // 收集问卷数量
                        Column() {
                          Text('当前收集问卷数量')
                            .fontSize(20)
                            .fontWeight(FontWeight.Bold)
                          Text(`${this.answer.length / this.questions.length}`)
                            .fontSize(24)
                            .fontWeight(FontWeight.Bold)
                            .fontStyle(FontStyle.Italic)
                            .margin({ top: 24, bottom: 6 })
                        }
                        .width(new WidthBreakpointType('100%', '100%',
                          '80%').getValue(this.windowUtil.mainWindowInfo.widthBp))
                        .backgroundColor($r('sys.color.comp_background_primary'))
                        .borderRadius(20)
                        .padding(16)
                        .margin({ bottom: 24 })
                        .clickEffect({ level: ClickEffectLevel.LIGHT })
                      }

                      Flex({
                        direction: this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD ?
                          FlexDirection.Column : FlexDirection.Row,
                        space: { main: LengthMetrics.vp(24) }
                      }) {
                        Column() {
                          // 类型 + 标题
                          RelativeContainer() {
                            Text(question.type)
                              .fontSize(16)
                              .fontWeight(FontWeight.Medium)
                              .backgroundColor($r('sys.color.button_background_color_transparent'))
                              .borderRadius(20)
                              .padding({
                                top: 4,
                                bottom: 4,
                                left: 16,
                                right: 16
                              })
                              .alignRules({
                                left: { anchor: '__container__', align: HorizontalAlign.Start },
                                center: { anchor: '__container__', align: VerticalAlign.Center }
                              })

                            Text() {
                              Span(`第`)
                              Span(` ${1 + questionIndex} `).fontSize(22)
                              Span(`题`)
                            }
                            .fontSize(18)
                            .fontWeight(FontWeight.Bold)
                            .alignRules({
                              middle: { anchor: '__container__', align: HorizontalAlign.Center },
                              center: { anchor: '__container__', align: VerticalAlign.Center }
                            })
                          }
                          .width('100%')
                          .height(34)

                          // 问题
                          Row() {
                            Text(question.content)
                              .fontSize(18)
                              .fontWeight(FontWeight.Medium)
                          }
                          .width('100%')
                          .borderRadius(20)
                          .padding({ left: 16, right: 16 })
                          .margin({ top: 16, bottom: 16 })

                          // 选项
                          List({ space: 8 }) {
                            ForEach(this.survey?.questions[questionIndex].options,
                              (option: string, optionIndex: number) => {
                                ListItem() {
                                  Row({ space: 8 }) {
                                    if (question.type !== '文本') {
                                      Checkbox({ name: `${question.type}_option_${1 + optionIndex}` })
                                        .enabled(false)
                                      Text(option)
                                        .fontSize(16)
                                        .layoutWeight(1)
                                    }
                                  }
                                  .width('100%')
                                  .padding({ left: 6, right: 6 })
                                }
                              }, (option: string, optionIndex: number) => option + optionIndex)
                          }

                        }
                        .width(new WidthBreakpointType('100%', '60%',
                          '60%').getValue(this.windowUtil.mainWindowInfo.widthBp))

                        Column() {
                          if (question.type === QuestionType.SINGLE_CHOICE) {
                            McBarChart({
                              options: new Options({
                                title: {
                                  show: true,
                                  text: '基础属性',
                                  right: 20,
                                  top: 30
                                },
                                xAxis: {
                                  data: JSON.parse(this.questions[questionIndex].options) as string[]
                                },
                                yAxis: {
                                  name: '选项数',
                                  max: Math.max(...this.answerSingle[questionIndex] || [], 0)
                                },
                                series: [
                                  {
                                    // name: `${questionIndex}选项个数`,
                                    data: this.answerSingle[questionIndex]
                                  }
                                ]
                              })
                            })
                              .height(250)
                          }
                          if (question.type === QuestionType.MULTIPLE_CHOICE) {
                            McBarChart({
                              options: new Options({
                                title: {
                                  show: true,
                                  text: '基础属性',
                                  right: 20,
                                  top: 30
                                },
                                xAxis: {
                                  data: JSON.parse(this.questions[questionIndex].options) as string[]
                                },
                                yAxis: {
                                  name: '选项数',
                                  // max: this.getMax(this.answerMultiple[questionIndex])
                                  max: Math.max(...this.answerMultiple[questionIndex] || [], 0)
                                },
                                series: [
                                  {
                                    // name: `${questionIndex}选项个数`,
                                    data: this.answerMultiple[questionIndex]
                                  }
                                ]
                              })
                            })
                              .height(250)
                            // Text(JSON.stringify(this.answerMultiple[0]))
                          }
                        }
                        .width(new WidthBreakpointType('100%', '40%',
                          '40%').getValue(this.windowUtil.mainWindowInfo.widthBp))
                      }
                      .width(new WidthBreakpointType('100%', '100%',
                        '80%').getValue(this.windowUtil.mainWindowInfo.widthBp))
                      .height('auto')
                      .backgroundColor($r('sys.color.comp_background_primary'))
                      .borderRadius(20)
                      .padding(12)
                      .clickEffect({ level: ClickEffectLevel.LIGHT })
                    }

                  }
                }, (question: Question, questionIndex: number) => JSON.stringify(question) + questionIndex)
              }
              .width('100%')
              .layoutWeight(1)
              .listDirection(Axis.Vertical)
              .alignListItem(ListItemAlign.Center)
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
              .contentStartOffset(this.getUIContext()
                .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                56 + 40)
              .contentEndOffset(24)
              .padding({ left: 16, right: 16 })
            } else {
              Column() {
                Text('请先连接网络')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .margin({
                    top: this.getUIContext()
                      .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                      56 + 40
                  })
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            }
          } else {
            Column() {
              Text('请先进行问卷发布')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .margin({
                  top: this.getUIContext()
                    .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                    56 + 40
                })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }


        }

        // 属性/内容 按钮
        if (this.windowUtil.mainWindowInfo.widthBp === WidthBreakpoint.WIDTH_SM && this.operationIndex < 2) {
          Row({ space: 12 }) {
            Button() {
              Text('属性')
            }
            .backgroundColor(this.attributeShow ? $r('app.color.list_on_color') :
              $r('sys.color.button_background_color_transparent'))
            .padding({
              top: 8,
              bottom: 8,
              left: 24,
              right: 24
            })
            .onClick(() => {
              this.attributeShow = true;
              this.contentShow = false;
            })

            Button() {
              Text('内容')
            }
            .backgroundColor(!this.attributeShow ? $r('app.color.list_on_color') :
              $r('sys.color.button_background_color_transparent'))
            .padding({
              top: 8,
              bottom: 8,
              left: 24,
              right: 24
            })
            .onClick(() => {
              this.attributeShow = false;
              this.contentShow = true;
            })
          }
          .zIndex(1)
          .position({
            left: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width) / 2 - 86,
            bottom: 36
          })
        }

      }
      .backgroundColor($r('sys.color.background_secondary'))
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }

  // 添加问题
  private addNewQuestion(type: QuestionType, content: string, options: string[]): void {
    let newQuestion: Question = new Question();
    newQuestion.type = type;
    newQuestion.content = content;
    newQuestion.options = options;
    this.survey!.questions.push(newQuestion);
    this.survey!.questions = [...this.survey!.questions];
  }

  // 获取添加按钮图标
  private getTypeSymbol(type: string): Resource {
    if (type === '单选') {
      return $r('sys.symbol.checkmark_circle_fill');
    } else if (type === '多选') {
      return $r('sys.symbol.checkmark_circle_on_circle_fill');
    } else if (type === '判断') {
      return $r('sys.symbol.checkmark_clipboard_fill');
    }
    return $r('sys.symbol.doc_plaintext_fill');
  }

  // 只统计单选题
  private calculateSingleChoiceStats(questions: QuestionCloud[], answers: AnswerCloud[]): number[][] {
    const singleChoiceQuestions = questions.filter(q => q.type !== '文本');

    return singleChoiceQuestions.map((question: QuestionCloud) => {
      const questionAnswers = answers.filter(a => a.question_id === question.id);
      const options = JSON.parse(question.options) as string[];
      const counts: number[] = new Array(options.length).fill(0);

      questionAnswers.forEach(answer => {
        const selectedOption = answer.answer_value;
        const index = options.indexOf(selectedOption);
        if (index !== -1) {
          counts[index]++;
        }
      });
      return counts;
    });
  }

  // 只统计多选题
  private calculateMultipleStats(questions: QuestionCloud[], answers: AnswerCloud[]): number[][] {
    // 返回与questions相同长度的数组，非多选问题返回空数组而不是null
    return questions.map(question => {
      if (question.type !== '多选') {
        return []; // 返回空数组而不是null
      }

      const questionAnswers = answers.filter(a => a.question_id === question.id);
      const options = JSON.parse(question.options) as string[];
      const counts: number[] = new Array(options.length).fill(0);

      questionAnswers.forEach(answer => {
        let selected: string[] = [];
        selected = JSON.parse(answer.answer_options) as string[];

        selected.forEach(option => {
          const index = options.indexOf(option);
          if (index !== -1) {
            counts[index]++;
          }
        });
      });

      console.error('[多选统计]', counts);
      return counts;
    });
  }
}

@Builder
export function CheckSurveyBuilder() {
  CheckSurveyView();
}