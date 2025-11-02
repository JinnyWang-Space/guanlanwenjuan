import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { AppStorageV2, promptAction, window } from "@kit.ArkUI";
import { DistributedDB, Question, QuestionType, Survey, SurveyViewModel, WindowUtil } from "common";
import { common } from "@kit.AbilityKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct MarketSurveyView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 问卷 id
  private marketSurveyId: number = this.pageInfos.getParamByName('MarketSurveyView')[0] as number;
  // 创建问卷实例
  @Local survey: Survey | null = new Survey();
  // 创建问卷模板实例
  private marketSurvey: Survey[] = new SurveyViewModel().marketSurvey;
  // 用于监听侧边栏当前所选item对应的索引值
  @Consumer('sideBarMainIndex') sideBarMainIndex: number = 0;
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);

  aboutToAppear(): void {
    this.survey = this.marketSurvey[this.marketSurveyId];
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Column() {
          Row({ space: 12 }) {
            Text(this.survey?.title)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
          }
          .height(40)
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Blank()

          Divider().strokeWidth(0.5).color(Color.Gray).margin({ top: 6 })
        }
        .width('100%')
        .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 48)
        .justifyContent(FlexAlign.Start)
        .padding({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
          bottom: 12,
          left: 16,
          right: 16
        })
        .zIndex(1)
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

        // 主体区域
        Row() {
          // 左区域
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
                  Text('问卷描述')
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                  Text(this.survey?.description)
                    .fontSize(18)
                    .margin({ top: 16, bottom: 16 })
                    .lineHeight(24)
                    .letterSpacing(2)
                }
                .width(480)
                .backgroundColor(Color.Gray)
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
                .width(480)
                .backgroundColor(Color.Gray)
                .borderRadius(20)
                .padding(16)
                .margin({ bottom: 24 })
                .clickEffect({ level: ClickEffectLevel.LIGHT })

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
                .width(480)
                .backgroundColor(Color.Gray)
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
          .width('45%')

          // 分割线
          Row()
            .width(8)
            .height(100)
            .backgroundColor(Color.Gray)
            .borderRadius(20)

          // 右区域
          Column() {
            // 问题列表
            List({ space: 24 }) {
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
                    if (question.type === QuestionType.SINGLE_CHOICE ||
                      question.type === QuestionType.MULTIPLE_CHOICE) {
                      List({ space: 8 }) {
                        ForEach(question.options, (option: string, optionIndex: number) => {
                          ListItem() {
                            Row({ space: 8 }) {
                              Checkbox({ name: `${question.type}_option_${1 + optionIndex}` })
                                .enabled(false)
                              Text(option)
                                .fontSize(16)
                                .layoutWeight(1)
                            }
                            .width('100%')
                            .padding({ left: 6, right: 6 })
                          }
                        }, (option: string, optionIndex: number) => option + optionIndex)
                      }
                    }
                    // if (this.question.type === QuestionType.TEXT_ANSWER) {
                    //
                    // }
                  }
                  .width(560)
                  .backgroundColor(Color.Gray)
                  .borderRadius(20)
                  .padding(12)
                  .clickEffect({ level: ClickEffectLevel.LIGHT })
                }
              }, (question: Question, index: number) => JSON.stringify(question) + index)
            }
            .width('100%')
            .layoutWeight(1)
            .alignListItem(ListItemAlign.Center)
            .contentStartOffset(this.getUIContext()
              .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
              56 + 40)
            .contentEndOffset(78)
            .scrollBar(BarState.Off)

          }
          .width('55%')
        }
        .width('100%')
        .layoutWeight(1)

        // 引用按钮
        Button() {
          Text('引用模板')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
        }
        .width(360)
        .padding({
          top: 8,
          bottom: 8,
          left: 16,
          right: 16
        })
        .zIndex(1)
        .position({ left: 540, bottom: 36 })
        .onClick(async () => {
          this.survey!.createdTime = Date.now() as number;
          await this.distributedDB.setDistributedTables(this.getUIContext()
            .getHostContext() as common.UIAbilityContext);
          try {
            const newId: number = await this.distributedDB.saveSurvey(this.survey as Survey);
            if (newId > 0) {
              this.refresh = true;
              promptAction.openToast({ message: '问卷引用成功' });
              this.pageInfos.pop();
              setTimeout(() => {
                this.sideBarMainIndex = 0;
                this.pageInfos.pushPath({ name: 'CheckSurveyView', param: newId }, { animated: true });
              }, 500)
            }
          } catch (error) {
            promptAction.openToast({ message: '问卷引用失败', textColor: Color.Red });
          }
        })
      }
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}

@Builder
export function MarketSurveyBuilder() {
  MarketSurveyView();
}