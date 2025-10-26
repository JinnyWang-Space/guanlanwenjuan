@ComponentV2
export struct CreateQ {
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row({ space: 12 }) {
        Button() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(24)
        }
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.hds_sidebar_overlay'))

        Blank()

        Text('请输入问卷名称')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)

        Blank()

        Button() {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(24)
        }
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.hds_sidebar_overlay'))
      }
      .width('100%')
      .height(64)
      .padding({ top: 16, left: 16, right: 16 })
      .zIndex(1)
      .position({ top: 0 })

      Scroll() {
        Column() {
          Blank()
            .height(80)

          

        }
      }
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
  }
}

@Builder
export function CreateQBuilder() {
  CreateQ()
}