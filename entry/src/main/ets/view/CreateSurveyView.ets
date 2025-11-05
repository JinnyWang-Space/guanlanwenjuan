import {
  AppStorageV2, promptAction, SymbolGlyphModifier, window
} from "@kit.ArkUI";
import { DistributedDB, Question, QuestionType, Survey, SurveyStatus, WidthBreakpointType, WindowUtil } from "common";
import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { QuestionItem } from "../components/QuestionItem";
import { common } from "@kit.AbilityKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct CreateSurveyView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 用于监听是否开始填写问卷名称
  @Local isWriteTitle: boolean = false;
  @Local isWriteD: boolean = false;
  @Local writeD: string = '';
  // 用于监听标题栏的背景高斯模糊（父）
  @Provider('isCVTitleBlur') isTitleBlur: boolean = false;
  // 菜单栏创建问卷图标
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

  // 创建所有问卷数据实例（子）
  @Consumer('surveys') surveys: Survey[] = [];
  // 创建问卷实例（父）
  @Provider('survey') survey: Survey = new Survey();
  // 用于监听是否正在使用添加问题功能
  @Local isAdd: boolean = false;
  @Provider('qScroller') qScroller: Scroller = new Scroller();
  @Local surveyTitle: string = '';
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  @Local selectedValue: number = 0;
  @Local attributeShow: boolean =
    new WidthBreakpointType(true, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local contentShow: boolean =
    new WidthBreakpointType(false, true, true).getValue(this.windowUtil.mainWindowInfo.widthBp);
  @Local attributeWidth: string = '100%';
  @Local contentWidth: string = '100%';

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
        this.survey.questions.splice(questionIndex, 1);
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')
    .margin({ left: 24 })
  }

  async aboutToAppear(): Promise<void> {
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  async aboutToDisappear(): Promise<void> {
    this.survey.title = this.surveyTitle;
    if (this.survey.title != '' || this.survey.description != '' || this.survey.questions.length != 0) {
      if (this.survey.title.trim().length === 0) {
        this.survey.title = `未知名问卷`
      }
      if (this.survey.description.trim().length === 0) {
        this.survey.description = '尊敬的参与者：\n' +
          '您好！感谢您抽出宝贵时间来参与我们的问卷调查。本次调查旨在了解您对该问卷的看法和需求。您的意见对我们了解该领域至关重要。\n' +
          '我们保证您的所有回答都将严格保密，并仅用于本次研究目的。' +
          '\n再次感谢您的参与与支持！祝您一切顺利！'
      }
      try {
        const newId: number = await this.distributedDB.saveSurvey(this.survey);
        if (newId > 0) {
          this.refresh = true;
        }
      } catch (error) {
      }
    }
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

            Row({ space: 2 }) {
              if (this.isWriteTitle) {
                TextInput({ placeholder: '请输入问卷名称', text: this.surveyTitle!! })
                  .layoutWeight(1)
                  // .maxLines(1)
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
            .layoutWeight(1)

            // Blank()
          }
          .height(40)
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Divider().width('100%').strokeWidth(0.5).color(Color.Gray).margin({ top: 4 })

          Row({ space: 12 }) {
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
          .width('100%')
          .height(40)
          .justifyContent(FlexAlign.Center)

        }
        .width('100%')
        .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 38)
        .justifyContent(FlexAlign.Start)
        .padding({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 8,
          left: 16, right: 16
        })
        .zIndex(1)
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

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
                      56 + 38)

                  // 问卷描述
                  Column() {
                    Text('问卷描述')
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                    TextArea({ placeholder: '请输入您的问卷描述', text: this.survey.description!! })
                      .fontSize(18)
                      .lineHeight(24)
                      .letterSpacing(2)
                      .margin({ top: 16, bottom: 16 })
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
                    Text(this.survey.questions.length.toString())
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
                                  this.survey.status = SurveyStatus.COLLECTING;
                                  promptAction.openToast({ message: '正在发放' })
                                } else {
                                  this.survey.status = SurveyStatus.DRAFT;
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
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius(20)
                  .padding(16)
                  .margin({ bottom: 24 })
                  .clickEffect({ level: ClickEffectLevel.LIGHT })

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
              // 问题列表
              List({ space: 24, scroller: this.qScroller }) {
                ForEach(this.survey.questions, (question: Question, index: number) => {
                  ListItem() {
                    QuestionItem({
                      question: question,
                      questionIndex: index,
                    })
                  }
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.itemEnd(index);
                      }
                    }
                  })
                }, (question: Question, index: number) => JSON.stringify(question) + index)
                  .onMove((from: number, to: number) => {
                    let tmp = this.survey.questions.splice(from, 1);
                    this.survey.questions.splice(to, 0, tmp[0]);
                  })
              }
              .width('100%')
              .layoutWeight(1)
              .contentStartOffset(this.getUIContext()
                .px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                56 + 40)
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
            Button() {
              Text('属性')
            }
            .backgroundColor(this.attributeShow ? $r('app.color.list_on_color') : $r('sys.color.button_background_color_transparent'))
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
            .backgroundColor(!this.attributeShow ? $r('app.color.list_on_color') : $r('sys.color.button_background_color_transparent'))
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
    this.survey.questions.push(newQuestion);
    this.survey.questions = [...this.survey.questions];
  }
}

@Builder
export function CreateSurveyBuilder() {
  CreateSurveyView()
}

@ComponentV2
export struct AddAttributeView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建问卷实例（子）
  @Consumer('survey') survey: Survey = new Survey();

  build() {

  }
}

@ComponentV2
export struct AddQuestionView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 用于监听标题栏的背景高斯模糊（子）
  @Consumer('isCVTitleBlur') isTitleBlur: boolean = false;
  // 用于监听填充组件的可见面积
  @Local ratio: number = 0;

  // 监听可见面积
  @Monitor('ratio')
  ratioChange() {
    if (this.ratio < 1) {
      this.isTitleBlur = true;
    } else {
      this.isTitleBlur = false;
    }
  }

  // 创建所有问卷数据实例（子）
  @Consumer('surveys') surveys: Survey[] = [];
  // 创建问卷实例（子）
  @Consumer('survey') survey: Survey = new Survey();
  @Consumer('qScroller') qScroller: Scroller = new Scroller();

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
        this.deleteQuestion(questionIndex);
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')
    .margin({ left: 24 })
  }

  build() {
    Scroll() {
      Column() {
        Blank()
          .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
            56 + 40)
          .onVisibleAreaChange([0.0, 1.0], (isExpanding: boolean, currentRatio: number) => {
            this.ratio = currentRatio;
          })

        // Text(`surveys: ${JSON.stringify(this.surveys)}`);
        // Text(`survey.text: ${JSON.stringify(this.survey.title)}`);
        // Text(`survey.questions: ${JSON.stringify(this.survey.questions)}`);

        // 问题列表
        List({ space: 24, scroller: this.qScroller }) {
          ForEach(this.survey.questions, (question: Question, index: number) => {
            ListItem() {
              QuestionItem({
                question: question,
                questionIndex: index,
              })
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.itemEnd(index);
                }
              }
            })
          }, (question: Question, index: number) => JSON.stringify(question) + index)
            .onMove((from: number, to: number) => {
              let tmp = this.survey.questions.splice(from, 1);
              this.survey.questions.splice(to, 0, tmp[0]);
            })
        }
        .width('100%')
        .layoutWeight(1)
        .contentEndOffset(24)
        .scrollBar(BarState.Off)
        .backgroundColor(Color.Pink)
        .padding({
          left: new WidthBreakpointType(16, 16, 96).getValue(this.windowUtil.mainWindowInfo.widthBp),
          right: new WidthBreakpointType(16, 16, 96).getValue(this.windowUtil.mainWindowInfo.widthBp)
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // 删除问题
  private deleteQuestion(questionIndex: number): void {
    this.survey.questions.splice(questionIndex, 1);
  }
}