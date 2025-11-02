import { Question, QuestionType, Survey } from "common"
import { promptAction } from "@kit.ArkUI";

@ComponentV2
export struct QuestionItem {
  // 接收父组件传来的问题
  @Param @Require question: Question;
  // 接受父组件传来的问题索引值
  @Param @Require questionIndex: number;
  // 创建问卷实例
  @Consumer('survey') survey: Survey = new Survey();

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
        this.deleteOption(optionIndex);
      })
    }
    .alignItems(VerticalAlign.Center)
    .height('100%')
    .margin({ left: 24 })
  }

  aboutToAppear(): void {

    promptAction.openToast({ message: '出现' })
  }

  aboutToDisappear(): void {
    promptAction.openToast({ message: '消失' })
  }

  // 创建变量作为一个临时选项，用于嵌套数据的防抖（输入法的抖动），question中含有option字符串数组，不能直接在onChange()中更新组件状态
  @Local option: string = '';

  build() {
    Column() {

      // Text('item')
      // Text(JSON.stringify(this.question))

      // 类型 + 标题
      RelativeContainer() {
        Text(this.question.type)
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

        Text(){
          Span(`第`)
          Span(` ${1 + this.questionIndex} `).fontSize(22)
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
      TextArea({ placeholder: '请输入您的问题', text: this.question.content!! })
        .margin({ top: 12, bottom: 12 })

      // 选项
      if (this.question.type === QuestionType.SINGLE_CHOICE || this.question.type === QuestionType.MULTIPLE_CHOICE) {
        List({ space: 8 }) {
          ForEach(this.question.options, (option: string, optionIndex: number) => {
            ListItem() {
              Row({ space: 8 }) {
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
                    this.question.options[optionIndex] = this.option;
                  })
                  .layoutWeight(1)
              }
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.itemEnd(optionIndex);
                }
              }
            })
          }, (option: string, optionIndex: number) => option + optionIndex)
            .onMove((from: number, to: number) => {
              let tmp = this.question.options.splice(from, 1);
              this.question.options.splice(to, 0, tmp[0]);
            })
        }
      }

      // 添加选项按钮
      Button() {
        Row({ space: 8 }) {
          SymbolGlyph(this.getTypeSymbol(this.question.type))
            .fontSize(24)
            .fontColor([Color.Gray])
          Text(`添加 ${this.question.type}`)
        }
      }
      .width('100%')
      .backgroundColor($r('sys.color.button_background_color_transparent'))
      .borderRadius(20)
      .padding({ top: 12, bottom: 12 })
      .margin({ top: 16 })
      .onClick(() => {
        this.addOption('');
      })
      .clickEffect({ level: ClickEffectLevel.LIGHT })

    }
    .width(480)
    .backgroundColor(Color.Gray)
    .borderRadius(20)
    .padding({
      top: 12,
      bottom: 12,
      left: 12,
      right: 12
    })
    .clickEffect({ level: ClickEffectLevel.LIGHT })
  }

  // 添加问题
  private addOption(pushOption: string): void {
    this.question.options.push(pushOption);
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
}