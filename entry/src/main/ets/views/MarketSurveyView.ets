import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import {
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  DistributedDB,
  getTargetTitle,
  OptionTemplate,
  Question,
  QuestionTemplate,
  QuestionType,
  StartVibrator,
  Survey,
  SurveyDescriptionTemplate,
  SurveyTemplate,
  WidthBreakpointType,
  WindowUtil
} from "common";
import { common } from "@kit.AbilityKit";
import { cloudDatabase } from "@kit.CloudFoundationKit";
import Logger from "common/src/main/ets/utils/Logger";
import { uiEffect } from "@kit.ArkGraphics2D";
import { i18n } from "@kit.LocalizationKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct MarketSurveyView {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 问卷 id
  private marketSurveyId: string = this.pageInfos.getParamByName('MarketSurveyView')[0] as string;
  // 创建问卷实例
  @Local survey: SurveyTemplate = new SurveyTemplate();
  // 创建问卷描述（中文）
  @Local surveyDescriptionZh: string = '';
  // 创建问卷描述（英文）
  @Local surveyDescriptionEn: string = '';
  // 创建问题实例
  @Local questions: QuestionTemplate[] = [];
  // 用于监听侧边栏当前所选item对应的索引值
  @Consumer('sideBarMainIndex') sideBarMainIndex: number = 0;
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.context);
  // 用于监听获取云数据库内容是否成功
  @Local isVisit: boolean = false;
  @Local surveyTitle: string = '';
  @Local surveyStatusBox: Resource[] =
    [$r('app.string.status_publish_now_text'), $r('app.string.status_save_draft_text')];
  // 用于监听是否加载出问卷
  @Local isLoading: boolean = true;
  @Local isSuccess: boolean = false;
  @Local isFailed: boolean = false;

  async aboutToAppear(): Promise<void> {
    // 初始化存储区
    let databaseZone = cloudDatabase.zone('guanlanwenjuan');
    // 初始化查询
    // let surveyTemplate = new cloudDatabase.DatabaseQuery(SurveyTemplate);
    // let questionTemplate = new cloudDatabase.DatabaseQuery(QuestionTemplate);
    // let surveyDescriptionTemplate = new cloudDatabase.DatabaseQuery(SurveyDescriptionTemplate);
    // 进行查询并赋值
    try {
      // 根据问卷 id 查询，获取该问卷
      // surveyTemplate.equalTo('id', this.marketSurveyId);
      // // 根据问卷 template_id 查询该问卷下的问题，并且根据问题 id 进行排序
      // questionTemplate.equalTo('template_id', this.marketSurveyId).orderByAsc('id');
      // // 根据问卷 template_id 查询该问卷下的问卷描述
      // surveyDescriptionTemplate.equalTo('template_id', this.marketSurveyId);
      // // 获取的问卷模板
      // let surveyResult = await databaseZone.query(surveyTemplate);
      // // 获取的问卷描述
      // let surveyDescriptionResult = await databaseZone.query(surveyDescriptionTemplate);
      // // 获取的问题模板
      // let questionResult = await databaseZone.query(questionTemplate);

      // 1. 并行查询所有基础数据
      const generatedDestructArray = await Promise.all([
        this.querySurveyTemplate(databaseZone),
        this.queryQuestionTemplate(databaseZone),
        this.querySurveyDescription(databaseZone)
      ]);
      const surveyResult = generatedDestructArray[0];
      const questionResult = generatedDestructArray[1];
      const surveyDescriptionResult = generatedDestructArray[2];

      // // 赋值到用状态管理修饰的变量中
      // this.survey = surveyResult[0];
      // // 根据分片，将问卷描述叠加（目前中文+英文）
      // surveyDescriptionResult.forEach((description: SurveyDescriptionTemplate) => {
      //   this.surveyDescriptionZh += description.description_part_zh === undefined ? '' :
      //     description.description_part_zh;
      //   this.surveyDescriptionEn += description.description_part_en === undefined ? '' :
      //     description.description_part_en;
      // })

      // 2. 处理问卷数据
      this.processSurveyData(surveyResult, surveyDescriptionResult);

      // // 利用分片原理，将单个选项根据问题 template_question_id 赋值到问题数组中
      // for (let i = 0; i < questionResult.length; i++) {
      //   // 获取当前问题
      //   let question = questionResult[i];
      //   // 初始化查询
      //   let optionTemplate = new cloudDatabase.DatabaseQuery(OptionTemplate);
      //   // 根据问题 temple_question_id 查询对应的选项
      //   optionTemplate.equalTo('template_question_id', question.id).orderByAsc('id');
      //   // 获取选项
      //   let options = await databaseZone.query(optionTemplate);
      //   // 将选项置空，防止数据污染
      //   question.options = '';
      //   question.options_en = '';
      //   // 循环云数据中的选项数组
      //   for (let j = 0; j < options.length; j++) {
      //     // 获取中英文选项
      //     let option_zh = options[j].option_part_zh;
      //     let option_en = options[j].option_part_en;
      //     // 将选项添加到问题数组的选项中
      //     question.options += option_zh === undefined ? '' : option_zh;
      //     question.options_en += option_en === undefined ? '' : option_en;
      //   }
      //   // 更改问题数组
      //   questionResult.splice(i, 1, question);
      // }
      // // 将访问的云数据赋值到问题实例中
      // this.questions = questionResult;

      // 3. 批量查询所有选项并处理
      const processedQuestions = await this.processQuestionsWithOptions(databaseZone, questionResult);

      // 4. 赋值到状态变量中，成功访问云数据库并拿到数据
      if (processedQuestions) {
        this.questions = processedQuestions;
        this.isVisit = true;
        if (this.appGeneralData.languageId === 0) {
          this.appGeneralData.language = i18n.System.getSystemLanguage();
        }
        this.surveyTitle = getTargetTitle(this.survey.title, this.appGeneralData.language === 'en-Latn-US' ? 1 : 0);
        this.formPromptData(true);
        this.appTmpData.marketSurveyId = this.marketSurveyId;
      } else {
        this.formPromptData(false);
        return;
      }
      Logger.error('[MarketSurveyView.aboutAppear]',
        `Succeeded in querying data, survey: ${JSON.stringify(this.survey)}, questions: ${JSON.stringify(this.questions)}`);
    } catch (err) {
      // 访问云数据库失败
      this.formPromptData(false);
      Logger.error('[MarketSurveyView.aboutAppear]',
        `Failed to query data, code: ${err.code}, message: ${err.message}`);
    }
  }

  aboutToDisappear(): void {
    this.appTmpData.marketSurveyId = '';
  }

  @Local attributeShow: boolean =
    new WidthBreakpointType(true, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local contentShow: boolean =
    new WidthBreakpointType(false, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local attributeWidth: string = '100%';
  @Local contentWidth: string = '100%';
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  private panOptionLeft: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Left });

  // @Monitor('appGeneralData.language')
  // languageChange() {
  //   if (this.appGeneralData.language === 'zh-Hans') {
  //
  //   } else if (this.appGeneralData.language === 'en-Latn-US') {
  //
  //   }
  // }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        Image(this.appAppearanceData.staticWallpaper)

        Column() {

          // 当前有网络
          if (this.appTmpData.isNetwork) {
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

                Text(this.surveyTitle)
                // Text(this.isVisit ?
                //   getTargetTitle(this.survey.title, this.appGeneralData.language === 'en-Latn-US' ? 1 : 0) : 'null')
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .maxLines(1)
              }
              .height(40)
              .width('100%')
              .justifyContent(FlexAlign.Center)

              Blank()

              Divider().strokeWidth(0.5).color(Color.Gray)
                .margin({ top: new WidthBreakpointType(4, 4, 6).getValue(this.windowUtil.mainWindowInfo.widthBp) })

              if (this.windowUtil.mainWindowInfo.widthBp === WidthBreakpoint.WIDTH_SM) {
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
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .margin({ top: 4 })
              }

            }
            .width('100%')
            .height(new WidthBreakpointType(
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48 + 40,
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48,
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48
            ).getValue(this.windowUtil.mainWindowInfo.widthBp))
            .justifyContent(FlexAlign.Start)
            .padding({
              top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
              bottom: 12,
              left: 16,
              right: 16
            })
            .position({ top: 0 })
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
                        .height(this.getUIContext()
                          .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                          56 + 40)

                      // 问卷描述
                      Column() {
                        // Text('问卷描述')
                        Text($r('app.string.survey_description_text'))
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)

                        Text(this.isVisit ? this.appGeneralData.language === 'en-Latn-US' ? this.surveyDescriptionEn :
                          this.surveyDescriptionZh : 'null')
                          .fontSize(18)
                          .margin({ top: 16, bottom: 16 })
                          .lineHeight(24)
                          .letterSpacing(2)
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
                        // Text('问题数量')
                        Text($r('app.string.survey_count_text'))
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)
                        Text(this.questions.length.toString())
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
                        // Text('问卷状态')
                        Text($r('app.string.survey_status_text'))
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)

                        Row() {
                          // ForEach(['立即发放', '暂不发放'], (item: string, index: number) => {
                          ForEach(this.surveyStatusBox, (item: Resource, index: number) => {
                            Column({ space: 6 }) {
                              Text(item)
                                .fontSize(18)
                              Checkbox()
                                .select(index === 1 ? true : false)
                                .enabled(false)
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

                      // 底部填充区域
                      Blank()
                        .layoutWeight(1)
                        .margin({ bottom: 78 })

                    }
                  }
                  .width('100%')
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
                  List({ space: 24 }) {
                    ForEach(this.questions, (question: QuestionTemplate, questionIndex: number) => {
                      ListItem() {
                        Column() {
                          // 类型 + 标题
                          RelativeContainer() {
                            Text(getTargetTitle(question.type, this.appGeneralData.language === 'en-Latn-US' ? 1 : 0))
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
                              if (this.appGeneralData.language === 'en-Latn-US') {
                                Span(`Question`)
                                Span(` ${1 + questionIndex} `).fontSize(22)
                              } else {
                                Span(`第`)
                                Span(` ${1 + questionIndex} `).fontSize(22)
                                Span(`题`)
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
                            // Text(question.content)
                            Text(this.appGeneralData.language === 'en-Latn-US' ? question.content_en :
                              question.content)
                              .fontSize(18)
                              .fontWeight(FontWeight.Medium)
                          }
                          .width('100%')
                          .borderRadius(20)
                          .padding({ left: 16, right: 16 })
                          .margin({ top: 16, bottom: 16 })

                          // 选项
                          List({ space: 8 }) {
                            ForEach(JSON.parse(this.appGeneralData.language === 'en-Latn-US' ?
                              question.options_en : question.options) as string[],
                              (option: string, optionIndex: number) => {
                                ListItem() {
                                  Row({ space: 8 }) {
                                    // if (question.type !== '文本') {
                                    if (getTargetTitle(question.type, 0) !== '文本' ||
                                      getTargetTitle(question.type, 1) !== 'Text') {
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
                    }, (question: QuestionTemplate, questionIndex: number) => JSON.stringify(question) + questionIndex)
                  }
                  .width('100%')
                  .layoutWeight(1)
                  .contentStartOffset(this.getUIContext()
                    .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                    56 + 40)
                  .contentEndOffset(78)
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

            // 引用按钮
            Button() {
              // Text('引用模板')
              Text($r('app.string.use_template_text'))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
            }
            .width(new WidthBreakpointType('180', '360', '360').getValue(this.windowUtil.mainWindowInfo.widthBp))
            .backgroundColor($r('app.color.list_on_color'))
            .padding({
              top: 8,
              bottom: 8,
              left: 16,
              right: 16
            })
            .zIndex(1)
            .position({
              left: new WidthBreakpointType(
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width / 2) - 90,
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width / 2) - 180,
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width / 2) - 180
              ).getValue(this.windowUtil.mainWindowInfo.widthBp),
              bottom: 36
            })
            .onClick(async () => {
              // 开启按钮触感反馈
              if (this.appGeneralData.isHapticButton) {
                StartVibrator()
              }
              await this.distributedDB.setDistributedTables(this.context);
              let saveSurvey = new Survey();
              saveSurvey.title = getTargetTitle(this.survey.title, this.appGeneralData.language === 'zh-Hans' ? 0 : 1);
              saveSurvey.description =
                this.appGeneralData.language === 'zh-Hans' ? this.surveyDescriptionZh : this.surveyDescriptionEn;
              // 总问题
              let saveQuestions: Question[] = [];
              this.questions.map((question: QuestionTemplate) => {
                // 每一个问题
                let saveQuestion: Question = new Question();
                if (getTargetTitle(question.type, 0) === '单选') {
                  saveQuestion.type = QuestionType.SINGLE_CHOICE
                }
                if (getTargetTitle(question.type, 0) === '多选') {
                  saveQuestion.type = QuestionType.MULTIPLE_CHOICE
                }
                if (getTargetTitle(question.type, 0) === '判断') {
                  saveQuestion.type = QuestionType.TRUE_FALSE_CHOICE
                }
                if (getTargetTitle(question.type, 0) === '文本') {
                  saveQuestion.type = QuestionType.TEXT_ANSWER
                }
                saveQuestion.content =
                  this.appGeneralData.language === 'zh-Hans' ? question.content : question.content_en;
                // 问题对应的每一个选项
                let options: string[] = JSON.parse(this.appGeneralData.language === 'zh-Hans' ?
                  question.options : question.options_en) as string[];
                // 将对应的每一个选项推入该问题数组
                options.map((option: string) => {
                  saveQuestion.options.push(option);
                })
                saveQuestion.required = true;
                // 将单个问题推入总问题数组
                saveQuestions.push(saveQuestion)
              })
              saveSurvey.questions = saveQuestions;
              try {
                const newId: number = await this.distributedDB.saveSurvey(saveSurvey);
                if (newId > 0) {
                  this.refresh = true;
                  promptAction.openToast({ message: '问卷引用成功' });
                  console.error('skdfnvds', JSON.stringify(saveSurvey))
                  this.pageInfos.pop();
                  setTimeout(() => {
                    this.sideBarMainIndex = 0;
                    this.pageInfos.pushPath({ name: 'CheckSurveyView', param: newId }, { animated: true });
                  }, 700)
                }
              } catch (error) {
                promptAction.openToast({ message: '问卷引用失败', textColor: Color.Red });
              }

              // 初始化存储区
              let databaseZone = cloudDatabase.zone('guanlanwenjuan');
              try {
                let surveyResult: SurveyTemplate[] = await this.querySurveyTemplate(databaseZone);
                let survey = new SurveyTemplate();
                survey = surveyResult[0];
                survey.usage_count += 1;
                survey.description = '';
                survey.description_en = '';
                let success = await databaseZone.upsert([survey]);
                Logger.info('[MarketSurveyView]',
                  `Succeeded in upserting SurveyTemplate usage_count, result: ${success}`);
              } catch (err) {
                Logger.error('[MarketSurveyView]',
                  `Failed to upsert SurveyTemplate usage_count, code: ${err.code}, message: ${err.message}`);
              }
            })

            // if (this.isLoading) {
            //   Column() {
            //     LoadingProgress()
            //       .size({ width: 48, height: 48 })
            //       .color($r('app.color.list_on_color'))
            //       .margin({ bottom: 6 })
            //     Text($r('app.string.is_loading_text'))
            //   }
            //   .width('100%')
            //   .height('100%')
            //   .justifyContent(FlexAlign.Center)
            //   .alignItems(HorizontalAlign.Center)
            //   .zIndex(2)
            // }
          }
          // 当前无网络
          else {
            Column() {
              Text('当前无网络，请先连接网络')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .margin({
                  top: new WidthBreakpointType(
                    this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24,
                    this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24,
                    this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 +
                      38).getValue(this.windowUtil.mainWindowInfo.widthBp)
                })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }

        }
        .gesture(
          PanGesture(this.panOptionRight)
            .onActionEnd((event: GestureEvent) => {
              // 开启滑动触感反馈
              if (this.appGeneralData.isHapticSwipe) {
                StartVibrator()
              }

              if (this.attributeShow) {
                this.pageInfos.pop();
              }
              if (this.contentShow) {
                this.attributeShow = true;
                this.contentShow = false;
              }

              Logger.info('[ContentView.PanGesture]', 'Pan end');
            })
        )
        .gesture(
          PanGesture(this.panOptionLeft)
            .onActionEnd((event: GestureEvent) => {
              // 开启滑动触感反馈
              if (this.appGeneralData.isHapticSwipe) {
                StartVibrator()
              }
              if (this.attributeShow) {
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
              Text($r('app.string.is_loading_text'))
            } else if (this.isSuccess) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(48)
                .fontColor([$r('app.color.list_on_color')])
              Text($r('app.string.is_loading_success_text'))
            } else {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(48)
                .fontColor([$r('app.color.list_on_color')])
              Text($r('app.string.is_loading_failed_text'))
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
    }
  }

  // 查询问卷模板
  private async querySurveyTemplate(databaseZone: cloudDatabase.DatabaseZone): Promise<SurveyTemplate[]> {
    const surveyTemplate = new cloudDatabase.DatabaseQuery(SurveyTemplate);
    // 根据问卷 id 查询，获取该问卷
    surveyTemplate.equalTo('id', this.marketSurveyId);
    return await databaseZone.query(surveyTemplate);
  }

  // 查询问题模板
  private async queryQuestionTemplate(databaseZone: cloudDatabase.DatabaseZone): Promise<QuestionTemplate[]> {
    const questionTemplate = new cloudDatabase.DatabaseQuery(QuestionTemplate);
    // // 根据问卷 template_id 查询该问卷下的问题，并且根据问题 id 进行排序
    questionTemplate.equalTo('template_id', this.marketSurveyId).orderByAsc('id');
    return await databaseZone.query(questionTemplate);
  }

  // 查询问卷描述
  private async querySurveyDescription(databaseZone: cloudDatabase.DatabaseZone): Promise<SurveyDescriptionTemplate[]> {
    const surveyDescriptionTemplate = new cloudDatabase.DatabaseQuery(SurveyDescriptionTemplate);
    // // 根据问卷 template_id 查询该问卷下的问卷描述
    surveyDescriptionTemplate.equalTo('template_id', this.marketSurveyId);
    return await databaseZone.query(surveyDescriptionTemplate);
  }

  // 处理问卷数据
  private processSurveyData(
    surveyResult: SurveyTemplate[],
    surveyDescriptionResult: SurveyDescriptionTemplate[]
  ): void {
    if (surveyResult.length > 0) {
      this.survey = surveyResult[0];
    }

    // 处理问卷描述分片
    this.surveyDescriptionZh = '';
    this.surveyDescriptionEn = '';

    for (const description of surveyDescriptionResult) {
      this.surveyDescriptionZh += description.description_part_zh ?? '';
      this.surveyDescriptionEn += description.description_part_en ?? '';
    }
  }

  // 批量处理问题与选项
  private async processQuestionsWithOptions(
    databaseZone: cloudDatabase.DatabaseZone,
    questionResult: QuestionTemplate[]
  ): Promise<QuestionTemplate[]> {
    if (questionResult.length === 0) {
      return [];
    }

    // 1. 收集所有问题ID
    const questionIds: string[] = questionResult.map((q: QuestionTemplate) => q.id);

    // 2. 批量查询所有选项（一次性查询）
    const allOptions = await this.batchQueryOptions(databaseZone, questionIds);

    // 3. 将选项按问题ID分组
    const optionsByQuestionId = this.groupOptionsByQuestionId(allOptions);

    // 4. 处理每个问题
    return this.processEachQuestion(questionResult, optionsByQuestionId);
  }

  // 批量查询选项
  private async batchQueryOptions(
    databaseZone: cloudDatabase.DatabaseZone,
    questionIds: string[]
  ): Promise<OptionTemplate[]> {
    const optionTemplate = new cloudDatabase.DatabaseQuery(OptionTemplate);
    optionTemplate.in('template_question_id', questionIds).orderByAsc('id');
    return await databaseZone.query(optionTemplate);
  }

  // 按问题ID分组选项
  private groupOptionsByQuestionId(options: OptionTemplate[]): Map<string, OptionTemplate[]> {
    const optionsMap: Map<string, OptionTemplate[]> = new Map();

    for (const option of options) {
      const questionId: string = option.template_question_id;
      if (!optionsMap.has(questionId)) {
        optionsMap.set(questionId, []);
      }
      optionsMap.get(questionId)!.push(option);
    }

    return optionsMap;
  }

  // 处理每个问题的选项
  private processEachQuestion(
    questions: QuestionTemplate[],
    optionsMap: Map<string, OptionTemplate[]>
  ): QuestionTemplate[] {
    const processedQuestions: QuestionTemplate[] = [];
    for (let i = 0; i < questions.length; i++) {
      const question: QuestionTemplate = questions[i];
      const questionOptions: OptionTemplate[] = optionsMap.get(question.id) || [];
      // 初始化选项字符串
      let options: string = '';
      let options_en: string = '';
      // 拼接选项
      for (const option of questionOptions) {
        options += option.option_part_zh ?? '';
        options_en += option.option_part_en ?? '';
      }
      question.options = options;
      question.options_en = options_en;
      // 创建处理后的问题对象
      let processQuestion = question;
      processedQuestions.push(processQuestion)
    }
    return processedQuestions;
  }
}

@Builder
export function MarketSurveyBuilder() {
  MarketSurveyView();
}