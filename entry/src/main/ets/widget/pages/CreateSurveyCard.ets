@Entry
@Component
struct CreateSurveyCard {
  build() {
    Row() {
      Text('创建问卷')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Blank()
      Button(){
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(22)
      }
      .width(36)
      .height(36)
      .backgroundColor($r('sys.color.button_background_color_transparent'))
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: {
            targetPage: 'CreateSurveyView'
          }
        });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .padding({ left: 16, right: 16 })
  }
}