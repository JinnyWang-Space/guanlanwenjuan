import { WindowUtil } from "common";
import { AppStorageV2, SymbolGlyphModifier, window } from "@kit.ArkUI";
import { SideBarListModel } from "../model/SideBarListModel";
import { SideBarListViewModel } from "../viewmodel/SideBarListViewModel";
import { ShowListModel } from "../model/ShowListModel";
import { ShowListViewModel } from "../viewmodel/ShowListViewModel";
import { CreateQBuilder } from "./CreateQ";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct ContentView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建侧边栏列表数据实例
  private mainVM: SideBarListModel[] = new SideBarListViewModel().mainVM;
  @Consumer('isShowSideBar') isShowSidebar: boolean = false;
  // 侧边栏当前所选item对应的索引值
  @Consumer('sideBarIndex') mainIndex: number = 0;
  // 创建主视图列表数据实例
  private showListVM: ShowListModel[] = new ShowListViewModel().mainVM;

  // 用于监听是否显示创建问卷半模态页面
  @Local isCreateQ: boolean = false;

  // 菜单栏创建问卷图标
  @Local menuIconModifier1: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.doc_plaintext')).fontSize('24vp').fontColor([Color.Gray]);

  // 菜单
  @Builder
  createMenu() {
    Menu() {
      MenuItem({ symbolStartIcon: this.menuIconModifier1, content: "创建问卷" })
        .onChange((selected: boolean) => {
          if (selected) {
            this.isCreateQ = true;
          }
        })
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        Text(this.mainVM[this.mainIndex].label)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .margin({ left: this.isShowSidebar ? 0 : 56 })
          .animation({ duration: 400, curve: Curve.EaseInOut })

        Blank()

        Search()
          .width('30%')
          .margin({ right: 12 })
        Button() {
          SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
            .fontWeight(FontWeight.Normal)
            .fontSize(24)
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
        }
        .id('side')
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .height(40)
        .width(40)
        .onClick(() => {
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
          Blank()
            .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 38)
          if (this.mainIndex === 0) {
            List({ space: 32 }) {
              ForEach(this.showListVM, (item: ShowListModel, index: number) => {
                ListItem() {
                  Stack() {
                    // item 操作按钮，为了不与悬浮态效果冲突，改为 stack 视图，显示在最上层
                    if (index !== 0) {
                      Button() {
                        SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
                          .fontSize(24)
                          .fontColor([Color.Gray])
                      }
                      .width(40)
                      .height(40)
                      .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
                      .zIndex(1)
                      .position({ top: 20, right: 16 })
                    }

                    // item 视图
                    Row() {
                      Row() {
                        Column() {
                          SymbolGlyph($r('sys.symbol.plus'))
                            .fontSize(24)
                        }
                        .width(48)
                        .height('100%')
                        .justifyContent(FlexAlign.Center)
                        .backgroundColor(Color.Gray)
                        .borderRadius({
                          topLeft: 2,
                          bottomLeft: 2,
                          topRight: 8,
                          bottomRight: 8
                        })
                        .margin({ right: 16 })

                        if (index === 0) {
                          Text(item.label)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                        } else {
                          Column({ space: 12 }) {
                            Text(`${item.label}（${index}）`)
                              .fontSize(16)
                              .fontWeight(FontWeight.Medium)
                            Text(item.deltaT)
                              .fontSize(14)
                              .fontColor(Color.Gray)
                              .margin({ bottom: 6 })
                          }
                          .height('100%')
                          .justifyContent(FlexAlign.End)
                          .alignItems(HorizontalAlign.Start)
                        }

                        Blank()

                        if (index !== 0) {

                        }

                      }
                      .width('100%')
                      .height(80)
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
                      .padding({
                        top: 8,
                        bottom: 8,
                        left: 16,
                        right: 16
                      })
                    }
                    .bindMenu(index === 0 ? this.createMenu() : () => {
                    })
                    .backgroundColor($r('sys.color.comp_background_primary'))
                    .borderRadius(12)
                    .padding({
                      top: 4,
                      bottom: 4,
                      left: 6,
                      right: 6
                    })
                  }
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .listDirection(Axis.Vertical)
            .lanes(2, 32)
            .padding({ left: this.isShowSidebar ? 32 : 32 + 140, right: this.isShowSidebar ? 32 : 32 + 140 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
          }

        }
      }
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .bindSheet(this.isCreateQ!!, CreateQBuilder(), {
      width: 650,
      height: '90%',
      showClose: false,
      preferType: SheetType.CENTER,
      onWillDismiss: (dismissSheetAction: DismissSheetAction) => {
        // 三键，手势，esc返回
        if (dismissSheetAction.reason === DismissReason.PRESS_BACK) {
          dismissSheetAction.dismiss();
        }
        // 关闭按钮返回
        if (dismissSheetAction.reason === DismissReason.CLOSE_BUTTON) {
          dismissSheetAction.dismiss();
        }
      }
    })
  }
}

@Builder
export function ContentPanelBuilder() {
  ContentView();
}