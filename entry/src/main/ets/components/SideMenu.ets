import { SideBarListModel } from "../model/SideBarListModel"

@ComponentV2
export struct SideMenu {
  @Param @Require items: SideBarListModel[];
  @Param @Require selectedIndex: number;
  @Event changeIndex: (selectedIndex: number) => void = (selectedIndex: number) => {
  };

  build() {
    Column() {
      List({ space: 2 }) {
        ForEach(this.items, (item: SideBarListModel, index: number) => {
          ListItem() {
            Row() {
              SymbolGlyph(item.symbol)
                .fontSize(24)
                .margin({ left: 6, right: 8 })
                .fontColor([Color.Gray])
              Text(item.label)
                .fontSize(16)
                .fontWeight(this.selectedIndex === index ? FontWeight.Bold : FontWeight.Medium)
              Blank()
              Text(item.count.toString())
                .fontSize(14)
                .margin({ right: 8 })
            }
            .width('100%')
            .height(45)
            .onClick(() => {
              this.changeIndex(index);
            })
            .stateStyles({
              normal: {
                .backgroundColor('')
              },
              pressed: {
                .backgroundColor(Color.Gray)
                .borderRadius(12)
              },
              focused: {
                .backgroundColor(Color.Gray)
                .borderRadius(12)
              }
            })
          }
          .backgroundColor(this.selectedIndex === index ? Color.Orange : '')
          .borderRadius(12)
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}
