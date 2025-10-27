import { WindowUtil } from "common";
import { AppStorageV2, SymbolGlyphModifier, window } from "@kit.ArkUI";
import { SideBarListViewModel } from "../viewmodel/SideBarListViewModel";
import { SideBarListModel } from "../model/SideBarListModel";
import { SideMenu } from "../components/SideMenu";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct SideBarView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建侧边栏列表数据实例
  private mainVM: SideBarListModel[] = new SideBarListViewModel().mainVM;
  // 用于监听侧边栏当前所选item对应的索引值
  @Consumer('sideBarIndex') mainIndex:number = 0;

  build() {
    Column() {
      Blank().height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
      Text('我的问卷')
        .width('100%')
        .textAlign(TextAlign.Start)
        .fontColor(Color.Gray)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 24 })
        .margin({ top: 24, bottom: 12 })

      // SideBar菜单栏，不用 HdsSideMenu，因为不能高度自定义，例如：UI
      SideMenu({
        items: this.mainVM,
        selectedIndex: this.mainIndex,
        changeIndex: (selectedIndex: number) => {
          this.mainIndex = selectedIndex
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}

@Builder
export function sideBarPanelBuilder() {
  SideBarView();
}