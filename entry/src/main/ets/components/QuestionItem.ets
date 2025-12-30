import { AppAppearanceViewModel, AppGeneralViewModel, Question, QuestionType, StartVibrator, Survey,
  SurveyStatus } from "common"
import { PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { common } from "@kit.AbilityKit";
import { uiEffect } from "@kit.ArkGraphics2D";

@ReusableV2
@ComponentV2
export struct QuestionItem {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 接收父组件传来的问题
  @Param @Require question: Question;
  // 接受父组件传来的问题索引值
  @Param @Require questionIndex: number;
  // 创建问卷实例
  @Consumer('survey') survey: Survey = new Survey();
  @Local timerId: number = 0;

  // 划出组件 —— 当前用于删除问题
  @Builder
  itemEnd(optionIndex: number) {
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
        // 开启菜单项触感反馈
        if (this.appGeneralData.isHapticMenu) {
          StartVibrator()
        }
        // promptAction.openToast({message:`当前删除的索引值:${optionIndex}`})
        this.deleteOption(optionIndex);
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')
    .margin({ left: 24 })
  }

  // aboutToAppear(): void {
  //   promptAction.openToast({ message: '出现' })
  // }
  //
  // aboutToDisappear(): void {
  //   promptAction.openToast({ message: '消失' })
  // }

  // 创建变量作为一个临时选项，用于嵌套数据的防抖（输入法的抖动），question中含有option字符串数组，不能直接在onChange()中更新组件状态
  @Local option: string = '';

  build() {
    Column() {

      // Text('item')
      // Text(JSON.stringify(this.question))

      // 类型 + 标题
      RelativeContainer() {
        // 类型
        Text(this.getTypeLanguage(this.question.type))
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

        // 标题号
        Text() {
          // 中文模式下
          if (this.appGeneralData.language === 'zh-Hans') {
            Span(`第`)
            Span(` ${1 + this.questionIndex} `).fontSize(22)
            Span(`题`)
          }
          // 英文模式下
          else {
            Span(`Question`)
            Span(` ${1 + this.questionIndex} `).fontSize(22)
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
      TextArea({ placeholder: $r('app.string.question_create_prompt_text'), text: this.question.content!! })
        .margin({ top: 12, bottom: 12 })
        .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)

      // 选项
      if (this.question.type !== QuestionType.TEXT_ANSWER) {
        List({ space: 8 }) {
          ForEach(this.question.options, (option: string, optionIndex: number) => {
            ListItem() {
              Row({ space: 8 }) {
                // 选项号，用大写字母代替序号
                Text(`${String.fromCharCode(65 + optionIndex)} .`)
                  .margin({ left: 8 })
                // 选项填写区域
                TextArea({
                  placeholder: this.getOptionPrompt(optionIndex),
                  // 不加!!，为了防止嵌套数据的抖动
                  text: option
                })
                  .enabled(this.survey.status === SurveyStatus.COLLECTING ? false : true)
                  .onChange((value: string) => {
                    // 只更新 UI ，用于嵌套数据的防抖
                    this.option = value;
                    promptAction.openToast({ message: `更新：${this.option}` })
                    // this.timerId = setTimeout(() => {
                      this.survey.questions[this.questionIndex].options[optionIndex] = this.option;
                    // }, 10000)
                  })
                  .onDidInsert(() => {
                    clearTimeout(this.timerId)
                  })
                  .onBlur(() => {
                    // this.survey.questions[this.questionIndex].options[optionIndex] = this.option;
                    // this.option = '';
                  })
                  // .onDidInsert(() => {
                  // promptAction.openToast({ message: '输入完成' })
                  // 输入完成后，进行组件状态更新
                  // setTimeout(() => {
                  //   this.question.options[optionIndex] = this.option;
                  // }, 100)
                  // })
                  .layoutWeight(1)
              }
            }
            .constraintSize({ minHeight: 40 })
            .swipeAction({
              end: {
                builder: () => {
                  this.itemEnd(optionIndex);
                }
              }
            })
          }, (option: string, optionIndex: number) => JSON.stringify(option) + optionIndex)
            .onMove((from: number, to: number) => {
              // 开启菜单项触感反馈
              if (this.appGeneralData.isHapticMenu) {
                StartVibrator()
              }
              let tmp = this.question.options.splice(from, 1);
              this.question.options.splice(to, 0, tmp[0]);
            })
        }
      }

      // 添加选项按钮
      if (this.question.type !== QuestionType.TEXT_ANSWER) {
        Button() {
          Row({ space: 8 }) {
            // 类型图标
            SymbolGlyph(this.getTypeSymbol(this.question.type))
              .fontSize(24)
              .fontColor([Color.Gray])
            // 添加类型文本
            Text() {
              Span($r('app.string.option_type_create_text'))
              Span(this.getTypeLanguage(this.question.type))
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
          // 添加选项
          this.addOption('');
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

  // 添加问题
  private addOption(pushOption: string): void {
    // this.question.options.push(pushOption);
    // this.question.options = [...this.question.options];

    this.survey.questions[this.questionIndex].options.push(pushOption);
  }

  // 删除问题
  private deleteOption(optionIndex: number): void {
    this.question.options.splice(optionIndex, 1);
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
}