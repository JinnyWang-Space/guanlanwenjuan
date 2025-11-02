import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { AppStorageV2, promptAction, SymbolGlyphModifier, window } from "@kit.ArkUI";
import { DistributedDB, Question, QuestionType, Survey, SurveyStatus, WindowUtil } from "common";
import { common } from "@kit.AbilityKit";
import { QuestionItem } from "../components/QuestionItem";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct CheckSurveyView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
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

  async aboutToAppear(): Promise<void> {
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.survey = await this.distributedDB.getSurveyById(this.surveyId);

    this.description = this.survey!.description;
    if (this.survey!.status === SurveyStatus.DRAFT) {
      this.selectedValue = 1;
    }
    if (this.survey!.status === SurveyStatus.COLLECTING) {
      this.selectedValue = 0;
    }
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

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Column() {
          Row({ space: 12 }) {
            if (this.operationIndex === 1) {
              TextArea({ placeholder: '请输入您的问卷名称', text: this.survey!.title!! })
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .width('auto')
            } else {
              Text(this.survey?.title)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
            }
          }
          .height(40)
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Divider().strokeWidth(0.5).color(Color.Gray).margin({ top: 4 })

          Row({ space: 24 }) {
            ForEach(this.operationBox, (item: string, index: number) => {
              if (index === 1) {
                Row({ space: 8 }) {
                  Button() {
                    Text(item)
                      .fontSize(this.operationIndex === index ? 18 : 16)
                      .fontWeight(FontWeight.Medium)
                  }
                  .backgroundColor(this.operationIndex === index ? Color.Blue :
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
                    .backgroundColor(this.isAdd ? Color.Pink : $r('sys.color.ohos_id_color_background_transparent'))
                    .onClick(() => {
                      this.isAdd = true;
                    })
                    .bindMenu(this.createMenu)
                  }

                }
              } else {
                Button() {
                  Text(item)
                    .fontSize(this.operationIndex === index ? 18 : 16)
                    .fontWeight(FontWeight.Medium)
                }
                .backgroundColor(this.operationIndex === index ? Color.Blue :
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
        .width('100%')
        .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 30)
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
            Column() {
              Scroll() {
                Column() {
                  // 顶部填充区域
                  Blank()
                    .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                      56 + 38)

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
                      TextArea({ placeholder: '请输入您的问卷描述', text: this.survey!.description })
                        .fontSize(18)
                        .lineHeight(24)
                        .letterSpacing(2)
                        .margin({ top: 16, bottom: 16 })
                    }
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
                          Radio({
                            value: item,
                            group: 'statusBox'
                          })
                            .checked(this.selectedValue === index)
                            .onChange((isChecked: boolean) => {
                              if (isChecked) {
                                this.selectedValue = index;
                                if (this.selectedValue === 0) {
                                  this.survey!.status = SurveyStatus.COLLECTING;
                                  promptAction.openToast({ message: '正在发放' })
                                } else {
                                  this.survey!.status = SurveyStatus.DRAFT;
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
                  .width(480)
                  .backgroundColor(Color.Gray)
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
                    .width(560)
                    .backgroundColor(Color.Gray)
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
                  // .onMove((from: number, to: number) => {
                  //   if (this.operationIndex === 1) {
                  //     let tmp = this.survey!.questions.splice(from, 1);
                  //     this.survey!.questions.splice(to, 0, tmp[0]);
                  //   }
                  // })
              }
              .width('100%')
              .layoutWeight(1)
              .alignListItem(ListItemAlign.Center)
              .contentStartOffset(this.getUIContext()
                .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                56 + 40)
              .contentEndOffset(24)
              .scrollBar(BarState.Off)
            }
            .width('55%')
          }
          .width('100%')
          .layoutWeight(1)
        }
        if (this.operationIndex === 2) {
          Column() {
            Blank()
              .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                56 + 38)

            Text(`text: ${this.survey}`)
          }

          Text('数据统计')
        }
      }
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
}

@Builder
export function CheckSurveyBuilder() {
  CheckSurveyView();
}