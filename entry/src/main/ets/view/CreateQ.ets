import {
  AppStorageV2,
  curves,
  LengthMetrics,
  promptAction,
  PromptAction,
  SymbolGlyphModifier,
  window
} from "@kit.ArkUI";
import { Question, QuestionType, Survey, WindowUtil } from "common";
import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct CreateQ {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 用于监听是否开始填写问卷名称
  @Local isWriteTitle: boolean = false;
  @Local isWriteD: boolean = false;
  @Local writeD: string = '';

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Row({ space: 12 }) {
          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(24)
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.hds_sidebar_overlay'))
          .onClick(() => {
            this.pageInfos.pop();
          })

          Blank()

          Row({ space: 2 }) {
            if (this.isWriteTitle) {
              TextInput({ placeholder: '请输入问卷名称' })
            }
            if (!this.isWriteTitle) {
              Text(`请输入问卷名称`)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  this.isWriteTitle = true;
                })
              SymbolGlyph($r('sys.symbol.pencil_waveform_fill'))
                .fontSize(24)
                .fontColor([Color.Gray])
            }

          }
          .width('30%')
          .justifyContent(FlexAlign.Center)


          Blank()

          Button() {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(24)
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.hds_sidebar_overlay'))
          .onClick(() => {
            this.pageInfos.pop();
          })
        }
        .width('100%')
        .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
        .justifyContent(FlexAlign.Start)
        .padding({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
          left: 16, right: 16
        })
        .zIndex(1)
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

        Scroll() {
          Column() {
            Row() {
              Column() {
                Scroll() {
                  Column() {
                    Blank()
                      .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                        56 + 38)

                  }
                }
                .layoutWeight(1)
                .align(Alignment.Top)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
              }
              .width('40%')

              Divider().vertical(true).color(Color.Gray)

              Column() {

                Content();

              }
              .width('60%')

            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}

@Builder
export function PageCreateQBuilder() {
  CreateQ()
}

@ComponentV2
struct Content {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 菜单栏创建问卷图标
  @Local menuIconModifier1: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier2: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_on_circle_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier3: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark_clipboard_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local menuIconModifier4: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.doc_plaintext_fill')).fontSize('24vp').fontColor([Color.Gray]);
  @Local survey: Survey = new Survey();

  // 菜单
  @Builder
  createMenu() {
    Menu() {
      MenuItem({ symbolStartIcon: this.menuIconModifier1, content: "单选" })
        .onClick(() => {
          this.addNewQuestion(QuestionType.SINGLE_CHOICE, '', []);
        })
      MenuItem({ symbolStartIcon: this.menuIconModifier2, content: "多选" })
        .onClick(() => {
          this.addNewQuestion(QuestionType.MULTIPLE_CHOICE, '', []);
        })
      MenuItem({ symbolStartIcon: this.menuIconModifier3, content: "判断" })
        .onClick(() => {
          this.addNewQuestion(QuestionType.TEXT_ANSWER, '', []);
        })
      MenuItem({ symbolStartIcon: this.menuIconModifier4, content: "文本" })
    }
  }

  private addNewQuestion(type: QuestionType, content: string, options: string[]): void {
    let newQuestion: Question = new Question();
    newQuestion.type = type;
    newQuestion.content = content;
    newQuestion.options = options;
    this.survey.questions.push(newQuestion);
    this.survey.questions = [...this.survey.questions];
  }

  getTypeSymbol(type: string): Resource {
    if (type === '单选') {
      return $r('sys.symbol.checkmark_circle_fill');
    } else if (type === '多选') {
      return $r('sys.symbol.checkmark_circle_on_circle_fill');
    } else if (type === '判断') {
      return $r('sys.symbol.checkmark_clipboard_fill');
    }
    return $r('sys.symbol.doc_plaintext_fill');
  }

  build() {
    Scroll() {
      Column() {
        Blank()
          .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
            56 + 38)

        // 问题列表
        List({ space: 24 }) {
          ForEach(this.survey.questions, (item: Question, index: number) => {
            ListItem() {
              Column() {
                // 类型 + 标题
                RelativeContainer() {
                  Text(item.type)
                    .fontSize(14)
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

                  Text(`第 ${1 + index} 题`)
                    .alignRules({
                      middle: { anchor: '__container__', align: HorizontalAlign.Center },
                      center: { anchor: '__container__', align: VerticalAlign.Center }
                    })
                }
                .width('100%')
                .height(28)

                // 问题
                TextArea({ placeholder: '请输入您的问题', text: item.content })
                  .margin({ top: 12, bottom: 12 })

                // 选项
                List({ space: 8 }) {
                  ForEach(item.options, (item: string, index: number) => {
                    ListItem() {
                      Row({ space: 8 }) {
                        Text(`${String.fromCharCode(65 + index)} .`)
                          .margin({ left: 8 })
                        TextArea({ placeholder: `请输入您选项 ${String.fromCharCode(65 + index)} 的问题` })
                          .layoutWeight(1)
                      }
                    }
                  })
                }

                // 添加选项按钮
                Button() {
                  Row({ space: 8 }) {
                    SymbolGlyph(this.getTypeSymbol(item.type))
                      .fontSize(24)
                      .fontColor([Color.Gray])
                    Text(`添加 ${item.type}`)
                  }
                }
                .width('100%')
                .backgroundColor($r('sys.color.button_background_color_transparent'))
                .borderRadius(20)
                .padding({ top: 12, bottom: 12 })
                .margin({ top: 16 })
                .onClick(() => {
                  let a = '';
                  item.options.push(a);
                })
                .clickEffect({ level: ClickEffectLevel.LIGHT })

              }
              .padding({ left: 12, right: 12 })
            }
            .width('100%')
            .backgroundColor(Color.Gray)
            .borderRadius(20)
            .padding({ top: 12, bottom: 12 })
            .clickEffect({ level: ClickEffectLevel.LIGHT })
          })
        }
        .width(480)
        .contentEndOffset(24)

        // 添加问题按钮
        Button() {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.doc_plaintext_and_pencil_fill'))
              .fontSize(24)
              .fontColor([Color.Gray])
            Text('添加')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width(456)
        .borderRadius(20)
        .backgroundColor($r('sys.color.button_background_color_transparent'))
        .clickEffect({ level: ClickEffectLevel.LIGHT })
        .padding({ top: 12, bottom: 12 })
        .margin({ bottom: 24 })
        .bindMenu(this.createMenu())
      }
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}