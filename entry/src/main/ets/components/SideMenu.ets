import { SideBarListModel } from "../model/SideBarListModel"

@ComponentV2
export struct SideMenu {
  // 接收父组件传来的侧边栏类型 —— 0-main, 1-sub
  @Param @Require type: number;
  // 接收父组件传来的列表数据
  @Param @Require items: SideBarListModel[];
  // 接收父组件传来的索引值
  @Param @Require selectedIndex: number;
  // 子组件改变item索引值传递回父组件
  @Event changeIndex: (selectedIndex: number) => void = (selectedIndex: number) => {
  };

  build() {
    Column() {
      List({ space: 2 }) {
        ForEach(this.items, (item: SideBarListModel, index: number) => {
          if (this.type === 0) {
            if (index < 5) {
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
            }
          }
          if (this.type === 1) {
            if (index > 4) {
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
            }
          }
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}
