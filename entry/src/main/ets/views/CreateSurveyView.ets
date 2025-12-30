import {
  AppStorageV2,
  PersistenceV2,
  promptAction,
  SymbolGlyphModifier,
  window
} from "@kit.ArkUI";
import {
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  AppViewModel,
  DistributedDB,
  mkdir,
  Question,
  QuestionCloud,
  QuestionType,
  access,
  StartVibrator,
  Survey,
  SurveyCloud,
  SurveyDescription,
  SurveyStatus,
  WidthBreakpointType,
  WindowUtil,
  savePixelMapToAlbum,
  OptionCloud
} from "common";
import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { QuestionItem } from "../components/QuestionItem";
import { common } from "@kit.AbilityKit";
import Logger from "common/src/main/ets/utils/Logger";
import { cloudDatabase } from "@kit.CloudFoundationKit";
import { image } from "@kit.ImageKit";
import { generateBarcode, scanCore } from "@kit.ScanKit";
import { util } from "@kit.ArkTS";
import { BusinessError } from "@kit.BasicServicesKit"
import { uiEffect } from "@kit.ArkGraphics2D";
import { fileIo, fileUri } from "@kit.CoreFileKit";
import { photoAccessHelper } from "@kit.MediaLibraryKit";
import { systemShare } from "@kit.ShareKit";
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct CreateSurveyView {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 用于监听是否开始填写问卷名称
  @Local isWriteTitle: boolean = false;
  @Local isWriteD: boolean = false;
  @Local writeD: string = '';
  // 用于监听标题栏的背景高斯模糊（父）
  @Provider('isCVTitleBlur') isTitleBlur: boolean = false;
  // 菜单栏创建问卷图标，单选、多选、判断、文本
  @Local menuIconModifier1: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier2: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_on_circle_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier3: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_clipboard_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier4: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.doc_plaintext_fill')).fontSize('24vp').fontColor([Color.Gray]);

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
            // 更新底部操作盒子索引值
            this.operationSelectedIndex = 1;
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
            // 更新底部操作盒子索引值
            this.operationSelectedIndex = 1;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.MULTIPLE_CHOICE, '', []);
          // 列表滑到底部，方便用户填写
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
            // 更新底部操作盒子索引值
            this.operationSelectedIndex = 1;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.TRUE_FALSE_CHOICE, '', []);
          // 列表滑到底部，方便用户填写
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
            // 更新底部操作盒子索引值
            this.operationSelectedIndex = 1;
          }

          // 添加问题
          this.addNewQuestion(QuestionType.TEXT_ANSWER, '', []);
          // 列表滑到底部，方便用户填写
          this.qScroller.scrollEdge(Edge.Bottom);
        })
    }
  }

  // 创建所有问卷数据实例（子）
  @Consumer('surveys') surveys: Survey[] = [];
  // 创建问卷实例（父）
  @Provider('survey') survey: Survey = new Survey();
  // 用于监听是否正在使用添加问题功能
  @Local isAdd: boolean = false;
  @Provider('qScroller') qScroller: Scroller = new Scroller();
  // 输入的标题文本
  @Local surveyTitle: string = '';
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  @Local selectedStatus: number = 1;
  @Local tmpSelectedStatus: number = 1;
  @Local attributeShow: boolean =
    new WidthBreakpointType(true, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local contentShow: boolean =
    new WidthBreakpointType(false, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  // 底部操作盒子索引值
  @Local operationSelectedIndex: number = 0;
  @Local attributeWidth: string = '100%';
  @Local contentWidth: string = '100%';
  // 本地数据库的问卷 id
  @Local surveyId: number = 0;

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
        // 删除该问题
        this.survey.questions.splice(questionIndex, 1);
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')
    .margin({ left: 24 })
  }

  async aboutToAppear(): Promise<void> {
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);

    // 问卷描述初始化
    this.survey.description =
      this.context.resourceManager.getStringSync($r('app.string.survey_description_had_text').id);
  }

  async aboutToDisappear(): Promise<void> {
    // 获取添加本地数据库结果
    let success: boolean = await this.saveToDB();
    // 添加成功
    if (success) {
      this.refresh = true;
      promptAction.openToast({ message: '问卷创建成功' });
    }
    // 添加失败
    else {
      promptAction.openToast({ message: '问卷创建失败', textColor: Color.Red });
    }
  }

  // 二维码图片
  @Local pixelMap: image.PixelMap | undefined = undefined;
  // 二维码操作盒子索引值
  @Local selectedQRIndex: number = -1;
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  private panOptionLeft: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Left });
  // 是否加载
  @Local isLoading: boolean = false;
  // 是否更新成功
  @Local isSuccess: boolean = false;
  // 是否更新失败
  @Local isFailed: boolean = false;

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.appAppearanceData.staticWallpaper)

        Column() {

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
              .onClick(async () => {
                // 开启按钮震动
                if (this.appGeneralData.isHapticButton) {
                  StartVibrator()
                }
                this.pageInfos.pop();
              })

              // 标题
              Row({ space: 2 }) {
                // 输入标题后
                if (this.isWriteTitle) {
                  TextInput({ placeholder: $r('app.string.survey_title_create_prompt_text'), text: this.surveyTitle!! })
                    .layoutWeight(1)
                    .onClick(() => {
                      // 开启按钮震动
                      if (this.appGeneralData.isHapticButton) {
                        StartVibrator()
                      }
                    })
                    .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                }
                // 未输入标题时
                if (!this.isWriteTitle) {
                  Text() {
                    Span($r('app.string.survey_title_create_prompt_text'))
                      .fontSize(20)
                      .fontWeight(FontWeight.Medium)

                    SymbolSpan($r('sys.symbol.pencil_waveform_fill'))
                      .fontSize(24)
                      .fontColor([Color.Gray])
                  }
                  .layoutWeight(1)
                  .onClick(() => {
                    // 开启按钮震动
                    if (this.appGeneralData.isHapticButton) {
                      StartVibrator()
                    }
                    this.isWriteTitle = true;
                  })
                  .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
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

            // 标题栏分割线
            Divider().width('100%').strokeWidth(0.5).color(Color.Gray).margin({ top: 4 })

            // 标题工具栏
            Row({ space: 12 }) {
              // 添加问题按钮
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
            .width('100%')
            .height(40)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 38)
          .justifyContent(FlexAlign.Start)
          .padding({ left: 16, right: 16 })
          .position({
            top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 8
            // , left: 16, right: 16
          })
          .zIndex(1)

          // 主体区域
          Row() {
            // 左区域
            if (this.attributeShow || this.windowUtil.mainWindowInfo.widthBp > WidthBreakpoint.WIDTH_SM) {
              Column() {
                Scroll() {
                  Column() {
                    // 顶部填充区域
                    Blank()
                      .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                        56 + 44)

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

                      TextArea({
                        placeholder: $r('app.string.survey_description_create_prompt_text'),
                        text: this.survey.description!!
                      })
                        .fontSize(18)
                        .lineHeight(24)
                        .letterSpacing(2)
                        .margin({ top: 16, bottom: 16 })
                        .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
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
                      Text(this.survey.questions.length.toString())
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

                      // 当前问卷未编写完
                      if (!this.appTmpData.isNetwork) {
                        Text('请编写完问卷，在进行发放')
                          .width('100%')
                          .textAlign(TextAlign.Center)
                          .fontColor(Color.Red)
                          .fontWeight(FontWeight.Medium)
                          .margin({ top: 16 })
                      }

                      // 选项按钮
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
                                .enabled(this.appTmpData.isNetwork || this.isSurveyForm() ? true : false)
                                .checked(this.selectedStatus === index)
                                .onChange(async (isChecked: boolean) => {
                                  if (isChecked) {
                                    // 展示加载状态
                                    this.isLoading = true;

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
                                      surveyCloud.title = this.surveyTitle;
                                      surveyCloud.status = this.survey.status;
                                      surveyCloud.published_time = new Date(this.survey.publishedTime!);
                                      surveyCloud.closed_time = new Date(this.survey.closedTime!)
                                      let record = await databaseZone.upsert(surveyCloud);

                                      // 成功修改问卷数据
                                      if (record) {

                                        // 删除已有的问卷描述
                                        let desCondition = new cloudDatabase.DatabaseQuery(SurveyDescription);
                                        desCondition.equalTo('survey_id', this.survey.id_cloud);
                                        let desResult = await databaseZone.query(desCondition);

                                        // 用于监听问卷描述是否成功
                                        let isDeleteDes: boolean = true;
                                        for (let i = 0; i < desResult.length; i++) {
                                          let desDelete = new SurveyDescription();
                                          desDelete.id = desResult[i].id
                                          let num = await databaseZone.delete(desDelete);

                                          // 删除问卷描述失败
                                          if (!num) {
                                            isDeleteDes = false;
                                            this.formPromptData(false);
                                            return;
                                          }
                                        }

                                        // 是否成功添加问卷描述
                                        let isAddDes: boolean = true;
                                        //问卷描述删除成功，进行下一步操作（添加问卷描述）
                                        if (isDeleteDes) {
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
                                              if (!record) {
                                                isAddDes = false;
                                                this.formPromptData(false);
                                                return;
                                              }
                                              Logger.info('[testTag]',
                                                `Succeeded in upserting a description, result: ${JSON.stringify(record)}`);
                                            } catch (err) {
                                              isAddDes = false;
                                              this.formPromptData(false);
                                              Logger.error('[testTag]',
                                                `Failed to upsert a description, code: ${err.code}, message: ${err.message}`);
                                              return;
                                            }
                                          }
                                        }

                                        // 用于监听是否成功删除问卷问题与选项
                                        let isDeleteQueAndOpt: boolean = true;
                                        // 成功添加问卷描述
                                        if (isAddDes) {
                                          // 删除已有的问卷问题
                                          let queCondition = new cloudDatabase.DatabaseQuery(QuestionCloud);
                                          queCondition.equalTo('survey_id', this.survey.id_cloud);
                                          let queResult = await databaseZone.query(queCondition);
                                          for (let i = 0; i < queResult.length; i++) {
                                            const que = queResult[i];

                                            let optCondition = new cloudDatabase.DatabaseQuery(OptionCloud);
                                            optCondition.equalTo('question_id', que.id);
                                            let optResult = await databaseZone.query(optCondition);
                                            for (let j = 0; j < optResult.length; j++) {
                                              const opt = optResult[j];
                                              let optDelete = new OptionCloud();
                                              optDelete.id = opt.id;
                                              let num_opt = await databaseZone.delete(optDelete);
                                              if (!num_opt) {
                                                isDeleteQueAndOpt = false;
                                                this.formPromptData(false);
                                                return;
                                              }
                                              // 该问题选项删除成功，开始删除问题
                                              else {
                                                let queDelete = new QuestionCloud();
                                                queDelete.id = que.id;
                                                let num = await databaseZone.delete(queDelete);
                                                if (!num) {
                                                  isDeleteQueAndOpt = false;
                                                  this.formPromptData(false);
                                                  return;
                                                }
                                              }
                                            }
                                          }
                                        }

                                        // 用于监听是否成功添加问卷问题与选项
                                        let isAddQueAndOp: boolean = true;
                                        // 成功删除问卷问题与选项，进行下一步操作
                                        if (isDeleteQueAndOpt) {
                                          // 将新的问题（包含选项）添加到云数据库中
                                          for (let i = 0; i < this.survey.questions.length; i++) {
                                            const question = this.survey.questions[i];
                                            try {
                                              let questionCloud = new QuestionCloud();
                                              let questionCloudId = 'share_question_' + Date.now() + '_' + i;
                                              questionCloud.id = questionCloudId;
                                              questionCloud.survey_id = this.survey.id_cloud;
                                              questionCloud.type = question.type as string;
                                              questionCloud.content = question.content;
                                              ;
                                              questionCloud.options = '前往 Option 表查看数据';
                                              questionCloud.required = true;
                                              let record = await databaseZone.upsert([questionCloud]);
                                              if (!record) {
                                                isAddQueAndOp = false;
                                                this.formPromptData(false);
                                                return;
                                              }
                                              // 问题上传成功，开始上传选项
                                              else {
                                                // 问题对应的选项
                                                const options = JSON.stringify(question.options) as string;

                                                // 进行选项的分片处理
                                                let options_len: number = options.length;
                                                let byteLength: number = 0;
                                                let optionArr: string[] = [];
                                                let option_part: string = '';
                                                for (let i = 0; i < options_len; i++) {
                                                  let part = options[i];
                                                  let charBytes = new util.TextEncoder().encodeInto(part).length;
                                                  if (byteLength + charBytes <= 200) {
                                                    byteLength += charBytes;
                                                    option_part += part;
                                                  } else {
                                                    optionArr.push(option_part);
                                                    byteLength = charBytes;
                                                    option_part = part;
                                                  }
                                                }
                                                if (option_part) {
                                                  optionArr.push(option_part);
                                                }

                                                // 将问卷对应的选项添加到云数据库中
                                                for (let j = 0; j < optionArr.length; j++) {
                                                  try {
                                                    let optionCloud = new OptionCloud();
                                                    optionCloud.id =
                                                      'share_option_' + Date.now() + '_' + i + '_' + j;
                                                    optionCloud.question_id = questionCloudId;
                                                    optionCloud.option_part = optionArr[j];
                                                    let record_option = await databaseZone.upsert([optionCloud]);
                                                    if (!record_option) {
                                                      isAddQueAndOp = false;
                                                      this.formPromptData(false);
                                                      return;
                                                    }
                                                    Logger.info('[CreateSurveyView]',
                                                      `Succeeded in upserting a option, result: ${JSON.stringify(record_option)}`);
                                                  } catch (err) {
                                                    isAddQueAndOp = false;
                                                    this.formPromptData(false);
                                                    Logger.error('[CreateSurveyView]',
                                                      `Failed to upsert a option, code: ${err.code}, message: ${err.message}`);
                                                    return;
                                                  }
                                                }
                                              }
                                              Logger.info('[question]',
                                                `Succeeded in upserting a question, result: ${JSON.stringify(record)}`);
                                            } catch (err) {
                                              isAddQueAndOp = false;
                                              this.formPromptData(false);
                                              Logger.error('[question]',
                                                `Failed to upsert a question, code: ${err.code}, message: ${err.message}`);
                                              return;
                                            }
                                          }
                                        }

                                        // 成功添加问卷
                                        if (isAddQueAndOp) {
                                          this.formPromptData(true);
                                        }
                                      }
                                      // 修改失败
                                      else {
                                        this.formPromptData(false);
                                        return;
                                      }
                                    }
                                    // 云数据库中未存在该问卷
                                    else {
                                      promptAction.openToast({
                                        message: `不存在,${this.survey.id_cloud}`,
                                        duration: 1000
                                      })

                                      // 用于监听是否成功添加问卷
                                      let isAddS: boolean = true;

                                      // 生成云问卷实例
                                      let survey = new SurveyCloud();
                                      // 生成云问卷 id
                                      let survey_cloud_id = 'share_survey_' + Date.now();
                                      // 为实例赋值
                                      survey.id = survey_cloud_id;
                                      // 问卷标题
                                      let surveyTitle: string = '';
                                      // 标题为空，则赋值为未命名问卷（中/英文）
                                      if (this.survey.title.trim().length === 0) {
                                        surveyTitle =
                                          this.context.resourceManager.getStringSync($r('app.string.unnamed_survey_text')
                                            .id)
                                            + ' (' + this.appBasicData.unnamedSurveyId + ')';
                                      }
                                      survey.title = this.surveyTitle.length === 0 ?
                                        surveyTitle : this.surveyTitle;
                                      survey.created_time = new Date(this.survey.createdTime);
                                      survey.status = this.survey.status;
                                      survey.published_time = new Date(this.survey.publishedTime!);
                                      survey.closed_time = new Date(this.survey.closedTime!);
                                      survey.deleted = this.survey!.deleted;
                                      // 进行云数据库的添加问卷
                                      try {
                                        let record = await databaseZone.upsert([survey]);
                                        if (!record) {
                                          isAddS = false;
                                          this.formPromptData(false);
                                          return;
                                        }
                                      } catch (err) {
                                        isAddS = false;
                                        this.formPromptData(false);
                                        Logger.error('[CreateView]',
                                          `Failed to upsert data, code: ${err.code}, message: ${err.message}`);
                                        return;
                                      }

                                      // 用于监听是否成功添加问卷描述
                                      let isAddDes: boolean = true;
                                      // 成功添加问卷
                                      if (isAddS) {
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
                                            if (!record) {
                                              isAddDes = false;
                                              this.formPromptData(false);
                                              return;
                                            }
                                            Logger.info('[testTag]',
                                              `Succeeded in upserting a description, result: ${JSON.stringify(record)}`);
                                          } catch (err) {
                                            isAddDes = false;
                                            this.formPromptData(false);
                                            Logger.error('[testTag]',
                                              `Failed to upsert a description, code: ${err.code}, message: ${err.message}`);
                                            return;
                                          }
                                        }
                                      }

                                      // 用于监听是否成功添加问题
                                      let isAddQueAndOp: boolean = true;
                                      // 成功添加问卷描述，进行下一步操作
                                      if (isAddDes) {
                                        // 将问题（包含选项）添加到云数据库中
                                        for (let i = 0; i < this.survey.questions.length; i++) {
                                          const question = this.survey.questions[i];
                                          try {
                                            let questionCloud = new QuestionCloud();
                                            let questionCloudId = 'share_question_' + Date.now() + '_' + i;
                                            questionCloud.id = questionCloudId;
                                            questionCloud.survey_id = survey_cloud_id;
                                            questionCloud.type = question.type as string;
                                            questionCloud.content = question.content;
                                            questionCloud.options = '前往 Option 表查看数据';
                                            // questionCloud.options = JSON.stringify(question.options) as string;
                                            questionCloud.required = true;
                                            let record = await databaseZone.upsert([questionCloud]);
                                            if (!record) {
                                              isAddQueAndOp = false;
                                              this.formPromptData(false);
                                              return;
                                            }
                                            // 问题上传成功，开始上传选项
                                            else {
                                              // 问题对应的选项
                                              const options = JSON.stringify(question.options) as string;

                                              // 进行选项的分片处理
                                              let options_len: number = options.length;
                                              let byteLength: number = 0;
                                              let optionArr: string[] = [];
                                              let option_part: string = '';
                                              for (let i = 0; i < options_len; i++) {
                                                let part = options[i];
                                                let charBytes = new util.TextEncoder().encodeInto(part).length;
                                                if (byteLength + charBytes <= 200) {
                                                  byteLength += charBytes;
                                                  option_part += part;
                                                } else {
                                                  optionArr.push(option_part);
                                                  byteLength = charBytes;
                                                  option_part = part;
                                                }
                                              }
                                              if (option_part) {
                                                optionArr.push(option_part);
                                              }

                                              // 将问卷对应的选项添加到云数据库中
                                              for (let j = 0; j < optionArr.length; j++) {
                                                try {
                                                  let optionCloud = new OptionCloud();
                                                  optionCloud.id =
                                                    'share_option_' + Date.now() + '_' + i + '_' + j;
                                                  optionCloud.question_id = questionCloudId;
                                                  optionCloud.option_part = optionArr[j];
                                                  let record_option = await databaseZone.upsert([optionCloud]);
                                                  if (!record_option) {
                                                    isAddQueAndOp = false;
                                                    this.formPromptData(false);
                                                    return;
                                                  }
                                                  Logger.info('[CreateSurveyView]',
                                                    `Succeeded in upserting a option, result: ${JSON.stringify(record_option)}`);
                                                } catch (err) {
                                                  isAddQueAndOp = false;
                                                  this.formPromptData(false);
                                                  Logger.error('[CreateSurveyView]',
                                                    `Failed to upsert a option, code: ${err.code}, message: ${err.message}`);
                                                  return;
                                                }
                                              }
                                            }
                                            Logger.info('[question]',
                                              `Succeeded in upserting a question, result: ${JSON.stringify(record)}`);
                                          } catch (err) {
                                            isAddQueAndOp = false;
                                            this.formPromptData(false);
                                            Logger.error('[question]',
                                              `Failed to upsert a question, code: ${err.code}, message: ${err.message}`);
                                            return;
                                          }
                                        }
                                      }

                                      // 用于监听是否成功生成二维码
                                      let isQR: boolean = true;
                                      // 成功添加问题选项
                                      if (isAddQueAndOp) {
                                        // 更新 UI界面中的 id_cloud，方便下次访问
                                        this.survey!.id_cloud = survey_cloud_id;

                                        // 当前未存过二维码
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
                                                let packOpts: image.PackingOption =
                                                  { format: "image/jpeg", quality: 98 };
                                                const filePath: string =
                                                  this.context.filesDir + `/qrDir/${this.survey.id_cloud}`;
                                                let file = fileIo.openSync(filePath,
                                                  fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
                                                const imagePackerObj: image.ImagePacker = image.createImagePacker();
                                                imagePackerObj.packToFile(imageSourceObj, file.fd, packOpts,
                                                  (err: BusinessError) => {
                                                    if (err) {
                                                      isQR = false;
                                                      this.formPromptData(false);
                                                      Logger.error('[CreateSurveyView]',
                                                        `Failed to pack the image to file.code ${err.code},message is ${err.message}`);
                                                      return;
                                                    } else {
                                                      Logger.info('[CreateSurveyView]',
                                                        'Succeeded in packing the image to file.');
                                                    }
                                                  })

                                                promptAction.openToast({ message: '二维码生成成功' })
                                              })
                                              .catch((error: BusinessError) => {
                                                isQR = false;
                                                this.formPromptData(false);
                                                Logger.error('[generateBarcode]',
                                                  `Failed to get PixelMap by promise with options. Code: ${JSON.stringify(error.code)},message:${error.message}`);
                                                return;
                                              })
                                          } catch (error) {
                                            isQR = false;
                                            this.formPromptData(false);
                                            Logger.error('[generateBarcode]',
                                              `Failed to createBarcode by promise with options. Code: ${error.code}, message: ${error.message}`);
                                            return;
                                          }
                                        }

                                        // 成功生成二维码
                                        if (isQR) {
                                          this.formPromptData(true);
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

                    // 是否有二维码图片
                    if (this.pixelMap) {
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

                        Text(this.surveyTitle)
                          .fontSize(18)
                          .fontWeight(FontWeight.Medium)
                          .margin({ top: 8, bottom: 24 })

                        Image(this.pixelMap)
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
                  ForEach(this.survey.questions, (question: Question, questionIndex: number) => {
                    ListItem() {
                      QuestionItem({
                        question: question,
                        questionIndex: questionIndex,
                      })
                    }
                    .swipeAction({
                      end: {
                        builder: () => {
                          this.itemEnd(questionIndex);
                        }
                      }
                    })
                  }, (question: Question, questionIndex: number) => JSON.stringify(question) + questionIndex)
                    .onMove((from: number, to: number) => {
                      // 开启托转排序
                      let tmp = this.survey.questions.splice(from, 1);
                      this.survey.questions.splice(to, 0, tmp[0]);
                    })
                }
                .width('100%')
                .layoutWeight(1)
                .contentStartOffset(
                  this.survey.status !== SurveyStatus.COLLECTING ?
                    this.getUIContext()
                      .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                      56 + 44 : 12)
                .contentEndOffset(new WidthBreakpointType(80, 24, 24).getValue(this.windowUtil.mainWindowInfo.widthBp))
                .edgeEffect(EdgeEffect.Spring)
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

          // 属性/内容 按钮
          if (this.windowUtil.mainWindowInfo.widthBp === WidthBreakpoint.WIDTH_SM) {
            Row({ space: 12 }) {
              ForEach([$r('app.string.survey_attribute_text'), $r('app.string.survey_content_text')],
                (item: Resource, index: number) => {
                  Button() {
                    Text(item)
                  }
                  .backgroundColor(this.operationSelectedIndex === index ? $r('app.color.list_on_color') :
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
                    this.operationSelectedIndex = index;

                    // 当前选中为属性
                    if (this.operationSelectedIndex === 0) {
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
        .enabled(this.isLoading ? false : true)
        .gesture(
          PanGesture(this.panOptionRight)
            .onActionEnd((event: GestureEvent) => {
              // 开启滑动反馈
              if (this.appGeneralData.isHapticSwipe) {
                StartVibrator()
              }
              // if (this.attributeShow) {
              //   this.pageInfos.pop();
              // }
              if (this.contentShow) {
                this.operationSelectedIndex = 0;
                this.attributeShow = true;
                this.contentShow = false;
              }

              Logger.info('[ContentView.PanGesture]', 'Pan end');
            })
        )
        .gesture(
          PanGesture(this.panOptionLeft)
            .onActionEnd((event: GestureEvent) => {
              // 开启滑动反馈
              if (this.appGeneralData.isHapticSwipe) {
                StartVibrator()
              }
              if (this.attributeShow) {
                this.operationSelectedIndex = 1;
                this.attributeShow = false;
                this.contentShow = true;
              }
              Logger.info('[ContentView.PanGesture]', 'Pan end');
            })
        )

        if (this.isLoading || this.isSuccess || this.isFailed) {
          Column({ space: 6 }) {
            if (this.isLoading) {
              LoadingProgress()
                .color($r('app.color.list_on_color'))
                .size({
                  width: new WidthBreakpointType(48, 48, 56).getValue(this.windowUtil.mainWindowInfo.widthBp),
                  height: new WidthBreakpointType(48, 48, 56).getValue(this.windowUtil.mainWindowInfo.widthBp)
                })
              Text('正在更新问卷状态')
            } else if (this.isSuccess) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(48)
                .fontColor([$r('app.color.list_on_color')])
              Text('更新成功')
            } else {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(48)
                .fontColor([$r('app.color.list_on_color')])
              Text('更新失败')
            }
          }
          .width(new WidthBreakpointType(150, 150, 200).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .height(new WidthBreakpointType(150, 150, 200).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .justifyContent(FlexAlign.Center)
          .borderRadius(new WidthBreakpointType(20, 20, 36).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .backgroundColor($r('app.color.list_card_bg_color'))
        }

      }
      .backgroundColor($r('sys.color.background_secondary'))

    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }

  // 判断问卷是否编写完成
  private isSurveyForm(): boolean {
    let isCompletion: boolean = true;
    // 如果标题不为空
    if (!this.survey.title) {
      isCompletion = false;
    }
    // 问题不能为空
    if (this.survey.questions.length === 0) {
      isCompletion = false;
    }
    // 问题对应的选项不能为空
    this.survey.questions.forEach((question: Question) => {
      if (!question.content) {
        isCompletion = false;
      }
      question.options.forEach((option: string) => {
        if (!option) {
          isCompletion = false;
        }
      })
    })
    return isCompletion;
  }

  // 建立弹出框数据
  private formPromptData(isSuccess: boolean) {
    if (isSuccess) {
      this.isLoading = false;
      this.isSuccess = true;
      this.isFailed = false;
      setTimeout(() => {
        this.isSuccess = false;
      }, 500)
    } else {
      this.isLoading = false;
      this.isSuccess = false;
      this.isFailed = true;
      setTimeout(() => {
        this.isFailed = false;
      }, 500)
      if (this.selectedStatus === 0) {
        this.selectedStatus = 1;
      }
    }
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

  // 向数据库添加，并返回添加结果（boolean）
  private async saveToDB(): Promise<boolean> {
    let success: boolean = true;
    // 更新问卷标题
    this.survey.title = this.surveyTitle;
    // 不再判断是否为空，只要关闭后自动创建
    // 标题为空，则赋值为未命名问卷（中/英文）
    if (this.survey.title.trim().length === 0) {
      this.survey.title = this.context.resourceManager.getStringSync($r('app.string.unnamed_survey_text').id)
        + ' (' + this.appBasicData.unnamedSurveyId + ')';
      // 更新未命名问卷 id
      this.appBasicData.unnamedSurveyId += 1;
    }
    // 问卷描述为空，则自动赋值问卷描述
    if (this.survey.description.trim().length === 0) {
      // 更新问卷描述（中/英文）
      this.survey.description =
        this.context.resourceManager.getStringSync($r('app.string.survey_description_had_text').id);
    }
    // 向数据库添加数据
    try {
      const newId: number = await this.distributedDB.saveSurvey(this.survey);
      if (newId) {
        this.surveyId = newId;
        // 刷新全部问卷列表
        this.refresh = true;
        // promptAction.openToast({ message: '问卷创建成功' });
      } else {
        success = false;
      }
    } catch (error) {
      success = false;
      // promptAction.openToast({ message: '问卷创建失败', textColor: Color.Red });
    }
    return success;
  }
}

@Builder
export function CreateSurveyBuilder() {
  CreateSurveyView()
}