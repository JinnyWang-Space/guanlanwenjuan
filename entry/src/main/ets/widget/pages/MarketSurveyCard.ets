@Entry
@Component
struct MarketSurveyCard {
  build() {
    Row() {
      Text('问卷模板')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Blank()
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_right'))
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
            targetSideBarMainIndex: '5'
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