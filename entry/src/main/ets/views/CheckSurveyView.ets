import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import {
  AppStorageV2,
  LengthMetrics,
  LengthUnit,
  PersistenceV2,
  promptAction,
  SymbolGlyphModifier,
  TipsDialogV2,
  window
} from "@kit.ArkUI";
import {
  AnswerCloud,
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  DistributedDB,
  access,
  mkdir,
  Question,
  QuestionCloud,
  QuestionType,
  savePixelMapToAlbum,
  StartVibrator,
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
import { uiEffect } from "@kit.ArkGraphics2D";
import { systemShare } from "@kit.ShareKit";
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileIo, fileUri } from "@kit.CoreFileKit";
import { photoAccessHelper } from "@kit.MediaLibraryKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct CheckSurveyView {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
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
  @Local survey: Survey = new Survey();
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  // 操作框
  @Local operationBox: Resource[] = [$r('app.string.survey_preview_text'),
    $r('app.string.survey_edit_text'), $r('app.string.survey_analyze_text')];
  // 操作框索引值
  @Local operationTopIndex: number = 0;
  @Local description: string = '';
  @Local selectedStatus: number = 1;
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
      // 单选
      MenuItem({ symbolStartIcon: this.menuIconModifier1, content: $r('app.string.single_choice_text') })
        .onClick(() => {
          // 开启菜单项触动反馈
          if (this.appGeneralData.isHapticMenu) {
            StartVibrator()
          }

          // 跳转到内容页面
          if (this.attributeShow && !this.contentShow) {
            this.attributeShow = false;
            this.contentShow = true;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.SINGLE_CHOICE, '', []);
          // 列表滑倒底部，方便用户填写
          this.qScroller.scrollEdge(Edge.Bottom);
        })
      // 多选
      MenuItem({ symbolStartIcon: this.menuIconModifier2, content: $r('app.string.multiple_choice_text') })
        .onClick(() => {
          // 开启菜单项触动反馈
          if (this.appGeneralData.isHapticMenu) {
            StartVibrator()
          }

          // 跳转到内容页面
          if (this.attributeShow && !this.contentShow) {
            this.attributeShow = false;
            this.contentShow = true;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.MULTIPLE_CHOICE, '', []);
          // 列表滑倒底部，方便用户填写
          this.qScroller.scrollEdge(Edge.Bottom);
        })
      // 判断
      MenuItem({ symbolStartIcon: this.menuIconModifier3, content: $r('app.string.true_false_choice_text') })
        .onClick(() => {
          // 开启菜单项触动反馈
          if (this.appGeneralData.isHapticMenu) {
            StartVibrator()
          }

          // 跳转到内容页面
          if (this.attributeShow && !this.contentShow) {
            this.attributeShow = false;
            this.contentShow = true;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.TRUE_FALSE_CHOICE, '', []);
          // 列表滑倒底部，方便用户填写
          this.qScroller.scrollEdge(Edge.Bottom);
        })
      // 文本
      MenuItem({ symbolStartIcon: this.menuIconModifier4, content: $r('app.string.text_choice_text') })
        .onClick(() => {

          // 开启菜单项触动反馈
          if (this.appGeneralData.isHapticMenu) {
            StartVibrator()
          }

          // 跳转到内容页面
          if (this.attributeShow && !this.contentShow) {
            this.attributeShow = false;
            this.contentShow = true;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.TEXT_ANSWER, '', []);
          // 列表滑倒底部，方便用户填写
          this.qScroller.scrollEdge(Edge.Bottom);

        })
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
        // 开启按钮触感反馈
        if (this.appGeneralData.isHapticButton) {
          StartVibrator()
        }
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
  // 二维码盒子操作索引值
  @Local selectedQRIndex: number = -1;
  // 底部操作盒子索引值
  @Local operationBottomIndex: number = 0;

  async aboutToAppear(): Promise<void> {

    // 获取问卷 id，暂存用于应用接续
    this.appTmpData.checkSurveyId = JSON.stringify(this.surveyId) as string;

    // 根据问卷 id 获取问卷全部信息
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.survey = await this.distributedDB.getSurveyById(this.surveyId) as Survey;

    // 获取问卷描述
    // this.description = this.survey.description;
    // 获取问卷状态
    if (this.survey!.status === SurveyStatus.DRAFT) {
      this.selectedStatus = 1;
    }
    if (this.survey!.status === SurveyStatus.COLLECTING) {
      this.selectedStatus = 0;
    }

    // 初始化存储区
    let databaseZone = cloudDatabase.zone('guanlanwenjuan');
    // 初始化查询
    let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);
    let questionCondition = new cloudDatabase.DatabaseQuery(QuestionCloud);

    // 根据问卷云 id 查询
    surveyCondition.equalTo('id', this.survey.id_cloud);
    let surveyCloud = await databaseZone.query(surveyCondition);

    // 获取云问卷的主键 id，根据主键 id 找到问题数据
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
  }

  async aboutToDisappear(): Promise<void> {

    this.appTmpData.checkSurveyId = '';

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
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  private panOptionLeft: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Left });

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.appAppearanceData.staticWallpaper)

        // 标题栏
        Column() {
          Row({ space: 12 }) {
            // 返回按钮
            Button() {
              SymbolGlyph($r('sys.symbol.chevron_left'))
                .fontSize(24)
                .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            }
            .width(40)
            .height(40)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .onClick(() => {
              // 开启按钮触感反馈
              if (this.appGeneralData.isHapticButton) {
                StartVibrator()
              }
              this.pageInfos.pop();
            })

            Row({ space: 2 }) {
              // 当前处于编辑状态
              if (this.operationTopIndex === 1) {
                TextArea({
                  placeholder: $r('app.string.survey_description_create_prompt_text'),
                  text: this.survey.title!!
                })
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
              } else {
                Text(this.survey.title)
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              // 当前处于发放状态，不可编辑
              if (this.survey.status === SurveyStatus.COLLECTING) {
                Text($r('app.string.survey_edit_warning_text'))
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.Red)
              }
            }
            .layoutWeight(1)
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
                        .fontSize(this.operationTopIndex === index ? 18 : 16)
                        .fontWeight(FontWeight.Medium)
                    }
                    .backgroundColor(this.operationTopIndex === index ? $r('app.color.list_on_color') :
                      $r('sys.color.button_background_color_transparent'))
                    .borderRadius(18)
                    .padding({
                      top: 4,
                      bottom: 4,
                      left: 16,
                      right: 16
                    })
                    .onClick(() => {
                      // 开启按钮触感反馈
                      if (this.appGeneralData.isHapticButton) {
                        StartVibrator()
                      }
                      this.operationTopIndex = index;
                    })

                    if (this.operationTopIndex === 1) {
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
                        // 开启按钮触感反馈
                        if (this.appGeneralData.isHapticButton) {
                          StartVibrator()
                        }
                        // 启用添加功能
                        this.isAdd = true;
                      })
                      .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                      .bindMenu(this.createMenu)

                      // 当前处于发放状态，不可编辑
                      if (this.survey.status === SurveyStatus.COLLECTING) {
                        Text($r('app.string.survey_edit_warning_text'))
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.Red)
                      }
                    }
                  }
                }
                // 按中预览与数据统计按钮
                else {
                  Button() {
                    Text(item)
                      .fontSize(this.operationTopIndex === index ? 18 : 16)
                      .fontWeight(FontWeight.Medium)
                  }
                  .backgroundColor(this.operationTopIndex === index ? $r('app.color.list_on_color') :
                    $r('sys.color.button_background_color_transparent'))
                  .borderRadius(18)
                  .padding({
                    top: 4,
                    bottom: 4,
                    left: 16,
                    right: 16
                  })
                  .onClick(() => {
                    // 开启按钮触感反馈
                    if (this.appGeneralData.isHapticButton) {
                      StartVibrator()
                    }
                    this.operationTopIndex = index;
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

        // 主题区域
        if (this.operationTopIndex < 2) {
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
                      Text($r('app.string.survey_description_text'))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                      // 当前处于发放状态，不可编辑
                      if (this.survey.status === SurveyStatus.COLLECTING) {
                        Text($r('app.string.survey_edit_warning_text'))
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.Red)
                          .margin({ top: 12 })
                      }
                      // 当前处于预览
                      if (this.operationTopIndex === 0) {
                        Text(this.survey.description)
                          .fontSize(18)
                          .lineHeight(24)
                          .letterSpacing(2)
                          .margin({ top: 16, bottom: 16 })
                      }
                      // 当前处于编辑
                      else {
                        TextArea({
                          placeholder: $r('app.string.survey_description_create_prompt_text'),
                          text: this.survey.description!!
                        })
                          .fontSize(18)
                          .lineHeight(24)
                          .letterSpacing(2)
                          .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                          .margin({ top: 16, bottom: 16 })
                      }
                    }
                    .width('100%')
                    .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                      $r('sys.color.comp_background_primary'))
                    .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                      uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                      uiEffect.createFilter().blur(BlurStyle.NONE))
                    .borderRadius(20)
                    .padding(16)
                    .margin({ bottom: 24 })
                    .clickEffect({ level: ClickEffectLevel.LIGHT })

                    // 问卷问题数量
                    Column() {
                      Text($r('app.string.survey_count_text'))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                      Text(this.survey?.questions.length.toString())
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontStyle(FontStyle.Italic)
                        .margin({ top: 24, bottom: 6 })
                    }
                    .width('100%')
                    .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                      $r('sys.color.comp_background_primary'))
                    .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                      uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                      uiEffect.createFilter().blur(BlurStyle.NONE))
                    .borderRadius(20)
                    .padding(16)
                    .margin({ bottom: 24 })
                    .clickEffect({ level: ClickEffectLevel.LIGHT })

                    // Text(JSON.stringify(this.questions))
                    // Text(JSON.stringify(this.answerSingle))
                    // Text(JSON.stringify(this.answerMultiple))

                    // 问卷状态
                    Column() {
                      Text($r('app.string.survey_status_text'))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)

                      // 当前无网
                      if (!this.appTmpData.isNetwork) {
                        Text('处于联网状态下才可进行该操作')
                          .width('100%')
                          .textAlign(TextAlign.Center)
                          .fontColor(Color.Red)
                          .fontWeight(FontWeight.Medium)
                          .margin({ top: 16 })
                      }

                      Row() {
                        ForEach([$r('app.string.status_publish_now_text'), $r('app.string.status_save_draft_text')],
                          (item: string, index: number) => {
                            Column({ space: 6 }) {
                              Text(item)
                                .fontSize(18)
                              Radio({
                                value: item,
                                group: 'statusBox'
                              })
                                .enabled(this.appTmpData.isNetwork && this.operationTopIndex === 1 ? true : false)
                                .checked(this.selectedStatus === index)
                                .onChange(async (isChecked: boolean) => {
                                  if (isChecked) {
                                    // 更新状态索引值
                                    this.selectedStatus = index;

                                    //  更新发放状态
                                    this.survey.status =
                                      this.selectedStatus === 0 ? SurveyStatus.COLLECTING : SurveyStatus.DRAFT;
                                    // 更新问卷发布时间与结束时间
                                    if (this.selectedStatus === 0) {
                                      this.survey.publishedTime = Date.now();
                                      this.survey.closedTime = undefined;
                                    } else {
                                      this.survey.closedTime = Date.now();
                                      this.survey.publishedTime = undefined;
                                    }

                                    // 进行云数据库的操作
                                    let databaseZone = cloudDatabase.zone('guanlanwenjuan');

                                    // 当前问卷已经存在云数据库中
                                    if (this.survey.id_cloud) {
                                      promptAction.openToast({
                                        message: `已存在,${this.survey.id_cloud}`,
                                        duration: 1000
                                      })

                                      // 初始化查询
                                      // 修改问卷数据
                                      let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);
                                      surveyCondition.equalTo('id', this.survey.id_cloud);
                                      let surveyResult = await databaseZone.query(surveyCondition);
                                      let surveyCloud = surveyResult[0];
                                      surveyCloud.title = this.survey.title;
                                      surveyCloud.status = this.survey.status;
                                      surveyCloud.published_time = new Date(this.survey.publishedTime!);
                                      surveyCloud.closed_time = new Date(this.survey.closedTime!)
                                      let record = await databaseZone.upsert(surveyCloud);

                                      // 删除已有的问卷描述
                                      let desCondition = new cloudDatabase.DatabaseQuery(SurveyDescription);
                                      desCondition.equalTo('survey_id', this.survey.id_cloud);
                                      let desResult = await databaseZone.query(desCondition);
                                      for (let i = 0; i < desResult.length; i++) {
                                        let desDelete = new SurveyDescription();
                                        desDelete.id = desResult[i].id
                                        let num = await databaseZone.delete(desDelete);
                                      }

                                      // 将新的描述进行分片处理
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
                                      // 将新的问卷描述添加到云数据库中
                                      for (let i = 0; i < description.length; i++) {
                                        try {
                                          let descriptionCloud = new SurveyDescription();
                                          descriptionCloud.id =
                                            'share_survey_description_' + Date.now() + '_' + i;
                                          descriptionCloud.description_part = description[i];
                                          descriptionCloud.survey_id = this.survey.id_cloud;
                                          let record = await databaseZone.upsert([descriptionCloud]);
                                          Logger.info('[testTag]',
                                            `Succeeded in upserting a description, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[testTag]',
                                            `Failed to upsert a description, code: ${err.code}, message: ${err.message}`);
                                        }
                                      }

                                      // 删除已有的问卷问题
                                      let queCondition = new cloudDatabase.DatabaseQuery(QuestionCloud);
                                      queCondition.equalTo('survey_id', this.survey.id_cloud);
                                      let queResult = await databaseZone.query(queCondition);
                                      for (let i = 0; i < queResult.length; i++) {
                                        let queDelete = new QuestionCloud();
                                        queDelete.id = queResult[i].id
                                        let num = await databaseZone.delete(queDelete);
                                      }

                                      // 将新的问题（包含选项）添加到云数据库中
                                      for (let i = 0; i < this.survey!.questions.length; i++) {
                                        const question = this.survey!.questions[i];
                                        try {
                                          let questionCloud = new QuestionCloud();
                                          questionCloud.id = 'share_question_' + Date.now() + '_' + i;
                                          questionCloud.survey_id = this.survey.id_cloud;
                                          questionCloud.type = question.type as string;
                                          questionCloud.content = question.content;
                                          questionCloud.options = JSON.stringify(question.options) as string;
                                          questionCloud.required = true;
                                          let record = await databaseZone.upsert([questionCloud]);
                                          Logger.info('[question]',
                                            `Succeeded in upserting a question, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[question]',
                                            `Failed to upsert a question, code: ${err.code}, message: ${err.message}`);
                                        }
                                      }
                                    }
                                    // 云数据库中未存在该问卷
                                    else {
                                      promptAction.openToast({
                                        message: `不存在,${this.survey.id_cloud}`,
                                        duration: 1000
                                      })
                                      // 生成云问卷实例
                                      let survey = new SurveyCloud();
                                      // 生成云问卷 id
                                      let survey_cloud_id = 'share_survey_' + Date.now();
                                      // 为实例赋值
                                      survey.id = survey_cloud_id;
                                      survey.title = this.survey.title;
                                      survey.created_time = new Date(this.survey.createdTime);
                                      survey.status = this.survey.status;
                                      survey.published_time = new Date(this.survey.publishedTime!);
                                      survey.closed_time = new Date(this.survey.closedTime!);
                                      survey.deleted = this.survey!.deleted;
                                      // 进行云数据库的添加
                                      try {
                                        let record = await databaseZone.upsert([survey]);
                                      } catch (err) {
                                        Logger.error('[CreateView]',
                                          `Failed to upsert data, code: ${err.code}, message: ${err.message}`);
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

                                      // 将问卷描述添加到云数据库中
                                      for (let i = 0; i < description.length; i++) {
                                        try {
                                          let descriptionCloud = new SurveyDescription();
                                          descriptionCloud.id =
                                            'share_survey_description_' + Date.now() + '_' + i;
                                          descriptionCloud.description_part = description[i];
                                          descriptionCloud.survey_id = survey_cloud_id;
                                          let record = await databaseZone.upsert([descriptionCloud]);
                                          Logger.info('[testTag]',
                                            `Succeeded in upserting a description, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[testTag]',
                                            `Failed to upsert a description, code: ${err.code}, message: ${err.message}`);
                                        }
                                      }

                                      // 将问题（包含选项）添加到云数据库中
                                      for (let i = 0; i < this.survey!.questions.length; i++) {
                                        const question = this.survey!.questions[i];
                                        try {
                                          let questionCloud = new QuestionCloud();
                                          questionCloud.id = 'share_question_' + Date.now() + '_' + i;
                                          questionCloud.survey_id = survey_cloud_id;
                                          questionCloud.type = question.type as string;
                                          questionCloud.content = question.content;
                                          questionCloud.options = JSON.stringify(question.options) as string;
                                          questionCloud.required = true;
                                          let record = await databaseZone.upsert([questionCloud]);
                                          Logger.info('[question]',
                                            `Succeeded in upserting a question, result: ${JSON.stringify(record)}`);
                                        } catch (err) {
                                          Logger.error('[question]',
                                            `Failed to upsert a question, code: ${err.code}, message: ${err.message}`);
                                        }
                                      }

                                      // 更新 UI界面中的 id_cloud，方便下次访问
                                      this.survey.id_cloud = survey_cloud_id;

                                      // 当前为存过二维码
                                      if (!this.pixelMap) {
                                        // 以QR码为例，码图生成参数
                                        this.pixelMap = undefined;
                                        // 配置信息
                                        let options: generateBarcode.CreateOptions = {
                                          scanType: scanCore.ScanType.QR_CODE,
                                          height: 400,
                                          width: 400
                                        }

                                        // 生成二维码图片
                                        try {
                                          // 码图生成接口，成功返回PixelMap格式图片
                                          generateBarcode.createBarcode(this.survey.id_cloud, options)
                                            .then(async (pixelMap: image.PixelMap) => {
                                              this.pixelMap = pixelMap;

                                              access(`${this.context.filesDir}/qrDir`, (isExist: boolean) => {
                                                if (!isExist) {
                                                  mkdir(this.context.filesDir, 'qrDir');
                                                }
                                              });

                                              const imageSourceObj: image.PixelMap = pixelMap;
                                              let packOpts: image.PackingOption = { format: "image/jpeg", quality: 98 };
                                              const filePath: string =
                                                this.context.filesDir + `/qrDir/${this.survey.id_cloud}`;
                                              let file = fileIo.openSync(filePath,
                                                fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
                                              const imagePackerObj: image.ImagePacker = image.createImagePacker();
                                              imagePackerObj.packToFile(imageSourceObj, file.fd, packOpts,
                                                (err: BusinessError) => {
                                                  if (err) {
                                                    console.error(`Failed to pack the image to file.code ${err.code},message is ${err.message}`);
                                                  } else {
                                                    console.info('Succeeded in packing the image to file.');
                                                  }
                                                })

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
                                      }
                                    }
                                  }
                                })
                            }
                            .layoutWeight(1)
                          })
                      }
                      .width('100%')
                      .margin({ top: 36, bottom: 16 })
                    }
                    .width('100%')
                    .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                      $r('sys.color.comp_background_primary'))
                    .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                      uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                      uiEffect.createFilter().blur(BlurStyle.NONE))
                    .borderRadius(20)
                    .padding(16)
                    .margin({ bottom: 24 })
                    .clickEffect({ level: ClickEffectLevel.LIGHT })

                    if (this.survey.id_cloud || this.pixelMap) {
                      Column() {
                        Text($r('app.string.qr_link_text'))
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)
                          .margin({ top: 8, bottom: 24 })

                        Row({ space: 12 }) {
                          ForEach([$r('sys.symbol.share'), $r('sys.symbol.arrowshape_down_to_line_fill')],
                            (item: Resource, index: number) => {
                              Button() {
                                SymbolGlyph(item)
                                  .fontSize(24)
                                  .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                              }
                              .size({ width: 40, height: 40 })
                              .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                              .onClick(async () => {
                                // 开启按钮触感反馈
                                if (this.appGeneralData.isHapticButton) {
                                  StartVibrator()
                                }

                                this.selectedQRIndex = index;

                                // 分享
                                if (this.selectedQRIndex === 0) {

                                  let data: systemShare.SharedData = new systemShare.SharedData({
                                    utd: utd.UniformDataType.IMAGE,
                                    uri: fileUri.getUriFromPath(`${this.context.filesDir}/qrDir/${this.survey.id_cloud}`),
                                    label: '观澜问卷',
                                    title: this.survey.title,
                                    description: '二维码链接'
                                  })

                                  // 构建ShareController
                                  let controller: systemShare.ShareController = new systemShare.ShareController(data);

                                  // 注册分享面板关闭监听
                                  controller.on('dismiss', () => {
                                    console.info('Share panel closed');
                                    // 分享结束，可处理其他业务。
                                  });

                                  // 拉起分享面板
                                  controller.show(this.context, {
                                    previewMode: systemShare.SharePreviewMode.DETAIL,
                                    selectionMode: systemShare.SelectionMode.BATCH
                                  })

                                }
                                // 保存到图库
                                else {
                                  // 使用弹窗授权保存媒体资源
                                  savePixelMapToAlbum(`${this.context.filesDir}/qrDir/${this.survey.id_cloud}`,
                                    photoAccessHelper.getPhotoAccessHelper(this.context));
                                }

                              })
                            })
                        }
                        .position({ top: 0, right: 0 })

                        Text(this.survey.title)
                          .fontSize(18)
                          .fontWeight(FontWeight.Medium)
                          .margin({ top: 8, bottom: 24 })

                        Image(fileUri.getUriFromPath(`${this.context.filesDir}/qrDir/${this.survey.id_cloud}`))
                          .width(200)
                          .height(200)
                          .margin({ bottom: 36 })
                      }
                      .width('100%')
                      .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                        $r('sys.color.comp_background_primary'))
                      .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                        uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                        uiEffect.createFilter().blur(BlurStyle.NONE))
                      .borderRadius(20)
                      .padding(16)
                      .margin({ bottom: 24 })
                      .clickEffect({ level: ClickEffectLevel.LIGHT })
                    }

                    // 底部填充区域
                    Blank()
                      .height(new WidthBreakpointType(80, 24, 24).getValue(this.windowUtil.mainWindowInfo.widthBp))

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
                // 当前处于发放状态，不可编辑
                if (this.survey.status === SurveyStatus.COLLECTING) {
                  Text($r('app.string.survey_edit_warning_text'))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.Red)
                    .margin({
                      top: this.getUIContext()
                        .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                        56 + 44
                    })
                }

                // 问题列表
                List({ space: 24, scroller: this.qScroller }) {
                  ForEach(this.survey?.questions, (question: Question, questionIndex: number) => {
                    ListItem() {
                      Column() {
                        // 类型 + 标题
                        RelativeContainer() {
                          Text(this.getTypeLanguage(question.type))
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
                            // 中文模式下
                            if (this.appGeneralData.language === 'zh-Hans') {
                              Span(`第`)
                              Span(` ${1 + questionIndex} `).fontSize(22)
                              Span(`题`)
                            }
                            // 英文模式下
                            else {
                              Span(`Question`)
                              Span(` ${1 + questionIndex} `).fontSize(22)
                            }
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
                        if (this.operationTopIndex === 0) {
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
                        if (this.operationTopIndex === 1) {
                          TextArea({
                            placeholder: $r('app.string.question_create_prompt_text'),
                            text: question.content!!
                          })
                            .margin({ top: 16, bottom: 16 })
                            .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                        }

                        // 选项
                        List({ space: 8 }) {
                          ForEach(question.options, (option: string, optionIndex: number) => {
                            ListItem() {
                              if (question.type !== QuestionType.TEXT_ANSWER) {
                                Row({ space: 8 }) {
                                  if (this.operationTopIndex === 0) {
                                    Checkbox({ name: `${question.type}_option_${1 + optionIndex}` })
                                      .enabled(false)
                                    Text(option)
                                      .fontSize(16)
                                      .layoutWeight(1)
                                  }
                                  if (this.operationTopIndex === 1) {
                                    Text(`${String.fromCharCode(65 + optionIndex)} .`)
                                      .margin({ left: 8 })
                                    TextArea({
                                      placeholder: this.getOptionPrompt(optionIndex),
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
                                      .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                                  }

                                }
                                .width('100%')
                                .padding({ left: 6, right: 6 })
                              }
                            }
                          }, (option: string, optionIndex: number) => option + optionIndex)
                        }

                        // 添加选项按钮
                        if (this.operationTopIndex === 1 && question.type !== QuestionType.TEXT_ANSWER) {
                          Button() {
                            Row({ space: 8 }) {
                              // 类型图标
                              SymbolGlyph(this.getTypeSymbol(question.type))
                                .fontSize(24)
                                .fontColor([Color.Gray])
                              // 添加类型文本
                              Text() {
                                Span($r('app.string.option_type_create_text'))
                                Span(this.getTypeLanguage(question.type))
                              }
                            }
                          }
                          .width('100%')
                          .backgroundColor($r('sys.color.button_background_color_transparent'))
                          .borderRadius(20)
                          .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                          .padding({ top: 12, bottom: 12 })
                          .margin({ top: 16 })
                          .onClick(() => {
                            // 开启按钮触感反馈
                            if (this.appGeneralData.isHapticButton) {
                              StartVibrator()
                            }
                            this.survey!.questions[questionIndex].options.push('');
                          })
                          .clickEffect({ level: ClickEffectLevel.LIGHT })
                        }

                      }
                      .width('100%')
                      .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                        $r('sys.color.comp_background_primary'))
                      .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                        uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                        uiEffect.createFilter().blur(BlurStyle.NONE))
                      .borderRadius(20)
                      .padding(12)
                      .clickEffect({ level: ClickEffectLevel.LIGHT })
                    }
                    .swipeAction({
                      end: {
                        builder: () => {
                          this.operationTopIndex === 1 ? this.itemEnd(questionIndex) : () => {
                          };
                        }
                      }
                    })
                  }, (question: Question, index: number) => JSON.stringify(question) + index)
                    .onMove((from: number, to: number) => {
                      if (this.operationTopIndex === 1) {
                        let tmp = this.survey!.questions.splice(from, 1);
                        this.survey!.questions.splice(to, 0, tmp[0]);
                      }
                    })
                }
                .width('100%')
                .layoutWeight(1)
                .contentStartOffset(this.survey.status === SurveyStatus.COLLECTING ? 4 : this.getUIContext()
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

        // 当前处于数据分析页面
        if (this.operationTopIndex === 2) {
          if (this.appTmpData.isNetwork) {
            // if (this.survey?.status===SurveyStatus.COLLECTING) {

            Scroll() {
              Column() {

                Text(JSON.stringify(this.answer))

                // 收集问卷数量
                Column() {
                  Text($r('app.string.survey_collection_num_text'))
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
                .margin({
                  top: this.getUIContext()
                    .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                    56 + 40,
                  bottom: 24
                })
                .clickEffect({ level: ClickEffectLevel.LIGHT })

                Column({ space: 24 }) {
                  ForEach(this.survey.questions, (question: Question, questionIndex: number) => {
                    ListItem() {
                      Column() {
                        Flex({
                          direction: this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD ?
                            FlexDirection.Column : FlexDirection.Row,
                          space: { main: LengthMetrics.vp(24) }
                        }) {
                          // 选项
                          Column() {
                            // 类型 + 标题
                            RelativeContainer() {
                              Text(this.getTypeLanguage(question.type))
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
                                // 中文模式下
                                if (this.appGeneralData.language === 'zh-Hans') {
                                  Span(`第`)
                                  Span(` ${1 + questionIndex} `).fontSize(22)
                                  Span(`题`)
                                }
                                // 英文模式下
                                else {
                                  Span(`Question`)
                                  Span(` ${1 + questionIndex} `).fontSize(22)
                                }
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

                          // 表格
                          Column() {
                            // if (question.type === QuestionType.SINGLE_CHOICE) {
                            //   // Text(JSON.stringify(this.answerSingle[questionIndex]))
                            //   // Text(JSON.stringify(question.options))
                            //
                            //   ForEach(question.options, (item: string, index: number) => {
                            //     Text(item)
                            //     Text(this.answerSingle === [][] ? '0' :
                            //       this.answerSingle[questionIndex][index].toString())
                            //   })
                            //
                            // }
                            // if (question.type === QuestionType.MULTIPLE_CHOICE) {
                            //   Text(JSON.stringify(this.answerMultiple[questionIndex]))
                            // }

                            if (question.type === QuestionType.SINGLE_CHOICE ||
                            question.type === QuestionType.TRUE_FALSE_CHOICE) {
                              Text(this.answerSingle[questionIndex] ? JSON.stringify(this.answerSingle[questionIndex]) :
                                JSON.stringify(new Array(question.options.length).fill(0)))
                              McBarChart({
                                options: new Options({
                                  title: {
                                    show: true,
                                    text: '基础属性',
                                    right: 20,
                                    top: 30
                                  },
                                  xAxis: {
                                    data: question.options
                                  },
                                  yAxis: {
                                    name: '选项数',
                                    max: Math.max(...this.answerSingle[questionIndex] || [], 0)
                                  },
                                  series: [
                                    {
                                      data: this.answerSingle[questionIndex] ? this.answerSingle[questionIndex] :
                                        new Array(question.options.length).fill(0)
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
                                    data: question.options
                                  },
                                  yAxis: {
                                    name: '选项数',
                                    // max: this.getMax(this.answerMultiple[questionIndex])
                                    max: Math.max(...this.answerMultiple[questionIndex] || [], 0)
                                  },
                                  series: [
                                    {
                                      // name: `${questionIndex}选项个数`,
                                      data: this.answerMultiple[questionIndex] ? this.answerMultiple[questionIndex] :
                                        new Array(question.options.length).fill(0)
                                    }
                                  ]
                                })
                              })
                                .height(250)
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
                        .margin({
                          bottom: this.survey.questions.length - 1 === questionIndex ?
                            new WidthBreakpointType(24, 24, 36).getValue(this.windowUtil.mainWindowInfo.widthBp) : 0
                        })
                      }
                    }
                  }, (question: Question, questionIndex: number) => JSON.stringify(question) + questionIndex)
                }
                .width('100%')
              }

            }
            .width('100%')
            .layoutWeight(1)
            .align(Alignment.Top)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .padding({ left: 16, right: 16 })

            // List({ space: 24 }) {
            //   ForEach(this.survey.questions, (question: Question, questionIndex: number) => {
            //     ListItem() {
            //       Column() {
            //         if (questionIndex === 0) {
            //           // 收集问卷数量
            //           Column() {
            //             Text($r('app.string.survey_collection_num_text'))
            //               .fontSize(20)
            //               .fontWeight(FontWeight.Bold)
            //             Text(`${this.answer.length / this.questions.length}`)
            //               .fontSize(24)
            //               .fontWeight(FontWeight.Bold)
            //               .fontStyle(FontStyle.Italic)
            //               .margin({ top: 24, bottom: 6 })
            //           }
            //           .width(new WidthBreakpointType('100%', '100%',
            //             '80%').getValue(this.windowUtil.mainWindowInfo.widthBp))
            //           .backgroundColor($r('sys.color.comp_background_primary'))
            //           .borderRadius(20)
            //           .padding(16)
            //           .margin({ bottom: 24 })
            //           .clickEffect({ level: ClickEffectLevel.LIGHT })
            //         }
            //
            //         Flex({
            //           direction: this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD ?
            //             FlexDirection.Column : FlexDirection.Row,
            //           space: { main: LengthMetrics.vp(24) }
            //         }) {
            //
            //           // 选项
            //           Column() {
            //             // 类型 + 标题
            //             RelativeContainer() {
            //               Text(this.getTypeLanguage(question.type))
            //                 .fontSize(16)
            //                 .fontWeight(FontWeight.Medium)
            //                 .backgroundColor($r('sys.color.button_background_color_transparent'))
            //                 .borderRadius(20)
            //                 .padding({
            //                   top: 4,
            //                   bottom: 4,
            //                   left: 16,
            //                   right: 16
            //                 })
            //                 .alignRules({
            //                   left: { anchor: '__container__', align: HorizontalAlign.Start },
            //                   center: { anchor: '__container__', align: VerticalAlign.Center }
            //                 })
            //
            //               Text() {
            //                 // 中文模式下
            //                 if (this.appGeneralData.language === 'zh-Hans') {
            //                   Span(`第`)
            //                   Span(` ${1 + questionIndex} `).fontSize(22)
            //                   Span(`题`)
            //                 }
            //                 // 英文模式下
            //                 else {
            //                   Span(`Question`)
            //                   Span(` ${1 + questionIndex} `).fontSize(22)
            //                 }
            //               }
            //               .fontSize(18)
            //               .fontWeight(FontWeight.Bold)
            //               .alignRules({
            //                 middle: { anchor: '__container__', align: HorizontalAlign.Center },
            //                 center: { anchor: '__container__', align: VerticalAlign.Center }
            //               })
            //             }
            //             .width('100%')
            //             .height(34)
            //
            //             // 问题
            //             Row() {
            //               Text(question.content)
            //                 .fontSize(18)
            //                 .fontWeight(FontWeight.Medium)
            //             }
            //             .width('100%')
            //             .borderRadius(20)
            //             .padding({ left: 16, right: 16 })
            //             .margin({ top: 16, bottom: 16 })
            //
            //             // 选项
            //             List({ space: 8 }) {
            //               ForEach(this.survey?.questions[questionIndex].options,
            //                 (option: string, optionIndex: number) => {
            //                   ListItem() {
            //                     Row({ space: 8 }) {
            //                       if (question.type !== '文本') {
            //                         Checkbox({ name: `${question.type}_option_${1 + optionIndex}` })
            //                           .enabled(false)
            //                         Text(option)
            //                           .fontSize(16)
            //                           .layoutWeight(1)
            //                       }
            //                     }
            //                     .width('100%')
            //                     .padding({ left: 6, right: 6 })
            //                   }
            //                 }, (option: string, optionIndex: number) => option + optionIndex)
            //             }
            //
            //           }
            //           .width(new WidthBreakpointType('100%', '60%',
            //             '60%').getValue(this.windowUtil.mainWindowInfo.widthBp))
            //
            //           // 表格
            //           Column() {
            //             // if (question.type === QuestionType.SINGLE_CHOICE) {
            //             //   // Text(JSON.stringify(this.answerSingle[questionIndex]))
            //             //   // Text(JSON.stringify(question.options))
            //             //
            //             //   ForEach(question.options, (item: string, index: number) => {
            //             //     Text(item)
            //             //     Text(this.answerSingle === [][] ? '0' :
            //             //       this.answerSingle[questionIndex][index].toString())
            //             //   })
            //             //
            //             // }
            //             // if (question.type === QuestionType.MULTIPLE_CHOICE) {
            //             //   Text(JSON.stringify(this.answerMultiple[questionIndex]))
            //             // }
            //
            //             if (question.type === QuestionType.SINGLE_CHOICE) {
            //               Text(this.answerSingle[questionIndex] ? JSON.stringify(this.answerSingle[questionIndex]) :
            //                 JSON.stringify(new Array(question.options.length).fill(0)))
            //               McBarChart({
            //                 options: new Options({
            //                   title: {
            //                     show: true,
            //                     text: '基础属性',
            //                     right: 20,
            //                     top: 30
            //                   },
            //                   xAxis: {
            //                     data: question.options
            //                   },
            //                   yAxis: {
            //                     name: '选项数',
            //                     max: Math.max(...this.answerSingle[questionIndex] || [], 0)
            //                   },
            //                   series: [
            //                     {
            //                       data: this.answerSingle[questionIndex] ? this.answerSingle[questionIndex] :
            //                         new Array(question.options.length).fill(0)
            //                     }
            //                   ]
            //                 })
            //               })
            //                 .height(250)
            //             }
            //
            //             if (question.type === QuestionType.MULTIPLE_CHOICE) {
            //               McBarChart({
            //                 options: new Options({
            //                   title: {
            //                     show: true,
            //                     text: '基础属性',
            //                     right: 20,
            //                     top: 30
            //                   },
            //                   xAxis: {
            //                     data: question.options
            //                   },
            //                   yAxis: {
            //                     name: '选项数',
            //                     // max: this.getMax(this.answerMultiple[questionIndex])
            //                     max: Math.max(...this.answerMultiple[questionIndex] || [], 0)
            //                   },
            //                   series: [
            //                     {
            //                       // name: `${questionIndex}选项个数`,
            //                       data: this.answerMultiple[questionIndex] ? this.answerMultiple[questionIndex] :
            //                         new Array(question.options.length).fill(0)
            //                     }
            //                   ]
            //                 })
            //               })
            //                 .height(250)
            //             }
            //           }
            //           .width(new WidthBreakpointType('100%', '40%',
            //             '40%').getValue(this.windowUtil.mainWindowInfo.widthBp))
            //         }
            //         .width(new WidthBreakpointType('100%', '100%',
            //           '80%').getValue(this.windowUtil.mainWindowInfo.widthBp))
            //         .height('auto')
            //         .backgroundColor($r('sys.color.comp_background_primary'))
            //         .borderRadius(20)
            //         .padding(12)
            //         .clickEffect({ level: ClickEffectLevel.LIGHT })
            //       }
            //
            //     }
            //   },
            //     (question: Question, questionIndex: number) => JSON.stringify(question) + questionIndex)
            // }
            // .width('100%')
            // .layoutWeight(1)
            // .listDirection(Axis.Vertical)
            // .alignListItem(ListItemAlign.Center)
            // .scrollBar(BarState.Off)
            // .edgeEffect(EdgeEffect.Spring)
            // .contentStartOffset(this.getUIContext()
            //   .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
            //   56 + 40)
            // .contentEndOffset(24)
            // .padding({ left: 16, right: 16 })
          }
          // 没有网络
          else {
            Column() {
              Text($r('app.string.network_connect_prompt_text'))
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
        if (this.windowUtil.mainWindowInfo.widthBp === WidthBreakpoint.WIDTH_SM && this.operationTopIndex < 2) {
          Row({ space: 12 }) {
            ForEach([$r('app.string.survey_attribute_text'), $r('app.string.survey_content_text')],
              (item: Resource, index: number) => {
                Button() {
                  Text(item)
                }
                .backgroundColor(this.operationBottomIndex === index ? $r('app.color.list_on_color') :
                  $r('sys.color.button_background_color_transparent'))
                .padding({
                  top: 8,
                  bottom: 8,
                  left: 24,
                  right: 24
                })
                .onClick(() => {
                  // 开启按钮震动
                  if (this.appGeneralData.isHapticButton) {
                    StartVibrator()
                  }

                  // 更新底部操作盒子索引
                  this.operationBottomIndex = index;

                  // 当前选中为属性
                  if (this.operationBottomIndex === 0) {
                    this.attributeShow = true;
                    this.contentShow = false;
                  }
                  // 当前选中为内容
                  else {
                    this.attributeShow = false;
                    this.contentShow = true;
                  }
                })
              })
          }
          .zIndex(1)
          .position({
            left: this.appGeneralData.language === 'zh-Hans' ?
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width) / 2 - 86 :
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width) / 2 - 117,
            bottom: 36
          })
        }
      }
      .backgroundColor($r('sys.color.background_secondary'))

      // .gesture(
      //   PanGesture(this.panOptionRight)
      //     .onActionEnd((event: GestureEvent) => {
      //       // if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD) {
      //       if (this.attributeShow && this.operationTopIndex === 0) {
      //         this.pageInfos.pop();
      //       } else if (this.contentShow && this.operationTopIndex === 0) {
      //         this.attributeShow = true;
      //         this.contentShow = false;
      //       } else if (this.operationTopIndex === 1 && this.attributeShow) {
      //         this.operationTopIndex = 0;
      //         this.attributeShow = true;
      //         this.contentShow = false;
      //       } else if (this.operationTopIndex === 1 && this.contentShow) {
      //         this.attributeShow = true;
      //         this.contentShow = false;
      //       } else if (this.operationTopIndex === 2) {
      //         this.operationTopIndex = 1;
      //         this.attributeShow = true;
      //         this.contentShow = false;
      //       }
      //       // }
      //       Logger.info('[ContentView.PanGesture]', 'Pan end');
      //     })
      // )
      // .gesture(
      //   PanGesture(this.panOptionLeft)
      //     .onActionEnd((event: GestureEvent) => {
      //       // if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD) {
      //
      //       if (this.attributeShow && this.operationTopIndex === 0) {
      //         this.attributeShow = false;
      //         this.contentShow = true;
      //       } else if (this.contentShow && this.operationTopIndex === 0) {
      //         this.operationTopIndex = 1;
      //         this.attributeShow = true;
      //         this.contentShow = false;
      //       } else if (this.attributeShow && this.operationTopIndex === 1) {
      //         this.attributeShow = false;
      //         this.contentShow = true;
      //         this.operationTopIndex = 1;
      //       } else if (this.contentShow && this.operationTopIndex === 1) {
      //         this.operationTopIndex = 2;
      //       }
      //
      //       // }
      //       Logger.info('[ContentView.PanGesture]', 'Pan end');
      //     })
      // )
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }

  // 添加问题
  private addNewQuestion(type: QuestionType, content: string, options: string[]): void {
    // 新建问题对象
    let newQuestion: Question = new Question();
    newQuestion.type = type;
    newQuestion.content = content;
    newQuestion.options = options;
    // 将问题推入到问卷中
    this.survey.questions.push(newQuestion);
    this.survey.questions = [...this.survey.questions];
  }

  // 获取类型名称（在多语言下，因此使用resource类型）
  private getTypeLanguage(type: string) {
    if (type === '单选') {
      return $r('app.string.single_choice_text');
    } else if (type === '多选') {
      return $r('app.string.multiple_choice_text');
    } else if (type === '判断') {
      return $r('app.string.true_false_choice_text');
    }
    return $r('app.string.text_choice_text');
  }

  // 添加选项提示语
  private getOptionPrompt(optionIndex: number) {
    return this.context.resourceManager.getStringSync($r('app.string.option_create_prompt_left_text').id) +
    String.fromCharCode(65 + optionIndex) +
    this.context.resourceManager.getStringSync($r('app.string.option_create_prompt_right_text').id)
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