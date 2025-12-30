import { HdsNavDestination, HdsNavDestinationAttribute } from "@kit.UIDesignKit"
import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { common } from "@kit.AbilityKit";
import {
  Answer,
  AnswerCloud,
  AppAppearanceViewModel,
  AppTmpViewModel,
  QuestionCloud,
  SurveyCloud,
  SurveyDescription,
  SurveyStatus,
  WidthBreakpointType,
  WindowUtil
} from "common";
import { cloudDatabase } from "@kit.CloudFoundationKit";
import Logger from "common/src/main/ets/utils/Logger";
import { uiEffect } from "@kit.ArkGraphics2D";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct WriteSurvey {
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 问卷 id
  private writeSurveyId: string = this.pageInfos.getParamByName('WriteSurveyView')[0] as string;
  // 创建问卷实例
  @Local survey: SurveyCloud = new SurveyCloud();
  // 创建问卷描述数组
  @Local surveyDescription: SurveyDescription[] = [];
  // 通过问卷描述数组进行整合
  @Local description: string = '';
  // 创建问题数组
  @Local questions: QuestionCloud[] = [];
  @Local answers: Answer[] = [];
  @Local options: string[] = [];

  async aboutToAppear(): Promise<void> {
    promptAction.openToast({message:this.writeSurveyId})
    // 初始化存储区
    let databaseZone = cloudDatabase.zone('guanlanwenjuan');
    // 初始化查询
    let surveyCondition = new cloudDatabase.DatabaseQuery(SurveyCloud);
    let surveyDescriptionCondition = new cloudDatabase.DatabaseQuery(SurveyDescription);
    let questionCondition = new cloudDatabase.DatabaseQuery(QuestionCloud);

    // 查询问卷并赋值
    surveyCondition.equalTo('id', this.writeSurveyId);
    let surveyResult = await databaseZone.query(surveyCondition);
    this.survey = surveyResult[0];

    // 查询问卷描述并赋值
    surveyDescriptionCondition.equalTo('survey_id', this.writeSurveyId);
    this.surveyDescription = await databaseZone.query(surveyDescriptionCondition);
    this.surveyDescription.map((item: SurveyDescription) => {
      this.description += item.description_part;
    })

    // 查询问题并赋值
    questionCondition.equalTo('survey_id', this.writeSurveyId).orderByAsc('id');
    this.questions = await databaseZone.query(questionCondition);

    this.questions.map((question: QuestionCloud, index: number) => {
      let answer = new Answer();
      answer.id = index.toString();
      this.answers.push(answer);
    })

  }

  // 是否显示属性
  @Local attributeShow: boolean =
    new WidthBreakpointType(true, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  // 是否显示内容
  @Local contentShow: boolean =
    new WidthBreakpointType(false, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  // 属性视图宽度
  @Local attributeWidth: string = '100%';
  // 内容视图宽度
  @Local contentWidth: string = '100%';

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.appAppearanceData.staticWallpaper)
        // 当前处于分发状态，可以填写
        if (this.survey.status === SurveyStatus.COLLECTING) {
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

              Text(this.survey.title)
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
          .zIndex(1)
          // .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

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
                      Text($r('app.string.survey_description_text'))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                      Text(this.description)
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

                    // Text(JSON.stringify(this.answers))

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
                  ForEach(this.questions, (question: QuestionCloud, questionIndex: number) => {
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
                          ForEach(JSON.parse(this.questions[questionIndex].options) as string[],
                            (option: string, optionIndex: number) => {
                              ListItem() {
                                Row({ space: 8 }) {
                                  if (question.type !== '文本') {
                                    // 单选
                                    if (question.type === '单选') {
                                      Radio({
                                        value: option,
                                        group: `statusBox_${questionIndex}}`
                                      })
                                        .onChange((isChecked: boolean) => {
                                          if (isChecked) {
                                            let answer = new Answer()
                                            answer.id = questionIndex.toString();
                                            answer.question_id = question.id;
                                            answer.answer_value = option;
                                            this.answers.splice(questionIndex, 1, answer);
                                          }
                                        })
                                    }
                                    // 多选
                                    else {
                                      Checkbox({ name: `${question.type}_option_${1 + optionIndex}` })
                                        .onChange((isCheck: boolean) => {
                                          let answer = this.answers[questionIndex] || new Answer();
                                          answer.id = questionIndex.toString();
                                          answer.question_id = question.id;

                                          if (isCheck) {
                                            // 如果选中，且选项不在数组中，则添加
                                            if (answer.answer_options.indexOf(option) === -1) {
                                              answer.answer_options.push(option);
                                            }
                                          } else {
                                            // 如果取消选中，则从数组中移除该选项
                                            const index = answer.answer_options.indexOf(option);
                                            if (index >= 0) {
                                              answer.answer_options.splice(index, 1);
                                            }
                                          }

                                          // 答案更新到数组
                                          this.answers.splice(questionIndex, 1, answer);
                                        })
                                    }
                                    Text(option)
                                      .fontSize(16)
                                      .layoutWeight(1)
                                  } else {
                                    TextArea({ placeholder: '请输入您的看法' })
                                      .onChange((value: string) => {
                                        let answer = new Answer()
                                        answer.id = questionIndex.toString();
                                        answer.question_id = question.id;
                                        answer.answer_value = value;
                                        this.answers.splice(questionIndex, 1, answer);
                                      })
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
                  }, (question: QuestionCloud, questionIndex: number) => JSON.stringify(question) + questionIndex)
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

          // 提交按钮
          Button() {
            Text('提交')
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

            // 当前有网络
            if (this.appTmpData.isNetwork) {
              // 初始化存储区
              let databaseZone = cloudDatabase.zone('guanlanwenjuan');

              // 初始化查询
              let surveyTemplate = new cloudDatabase.DatabaseQuery(AnswerCloud);

              for (let i = 0; i < this.answers.length; i++) {
                try {
                  let answerCloud = new AnswerCloud();
                  answerCloud.id = 'share_answer_' + Date.now().toLocaleString() + '_' + i.toString();
                  answerCloud.question_id = this.answers[i].question_id;
                  answerCloud.answer_value = this.answers[i].answer_value;
                  answerCloud.answer_options = JSON.stringify(this.answers[i].answer_options);
                  let record = await databaseZone.upsert([answerCloud]);
                  Logger.info('[WriteSurveyView]', `Succeeded in upserting a answer, result: ${JSON.stringify(record)}`);
                } catch (err) {
                  Logger.error('[WriteSurveyView]', `Failed to upsert a answer, code: ${err.code}, message: ${err.message}`);
                }
              }
              this.pageInfos.pop();
              promptAction.openToast({ message: '提交完成' });
            }
            // 当前无网络
            else {
              promptAction.openToast({ message: '请先连接网络', textColor: Color.Red })
            }
          })
        }
        // 当前处于非分发状态不可填写
        else {
          Text('当前问卷已关闭，感谢您的参加')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({
              top: new WidthBreakpointType(
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48 + 40,
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48,
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48
              ).getValue(this.windowUtil.mainWindowInfo.widthBp)
            })
        }
      }
      .backgroundColor($r('sys.color.background_secondary'))
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}

@Builder
export function WriteSurveyBuilder() {
  WriteSurvey();
}