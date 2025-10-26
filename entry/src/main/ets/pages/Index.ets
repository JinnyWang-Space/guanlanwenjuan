import { AppStorageV2, window } from '@kit.ArkUI'
import { WindowUtil } from 'common';
import { HdsSideBar } from '@hms.hds.HdsSideBar';
import { sideBarPanelBuilder } from '../view/SideBarView';
import { ContentPanelBuilder } from '../view/ContentView';

// 创建窗口实例
let windowStage: window.WindowStage;

@Entry
@ComponentV2
struct Index {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 是否显示侧边栏按钮，默认位 false
  @Provider('isShowSideBar') isShowSidebar: boolean = false;

  @Provider('sideBarIndex') sideBarIndex:number = 0;

  // 判断侧边栏是否显示
  getIsSideBar(): void {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      this.isShowSidebar = false;
    } else {
      this.isShowSidebar = true;
    }
  }

  // 获得侧边栏与内容区的显示关系
  getSideBarType(): SideBarContainerType {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      return SideBarContainerType.Overlay;
    }
    return SideBarContainerType.Embed;
  }

  aboutToAppear(): void {
    this.getIsSideBar();
  }

  @BuilderParam sideBarBuilder: () => void = sideBarPanelBuilder;
  @BuilderParam contentBuilder: () => void = ContentPanelBuilder;

  build() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 侧边栏按钮
        Button() {
          SymbolGlyph(this.isShowSidebar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'))
            .fontWeight(FontWeight.Normal)
            .fontSize(24)
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            .hitTestBehavior(HitTestMode.None)
        }
        .id('side_bar_button')
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .height(40)
        .width(40)
        .onClick(() => {
          this.isShowSidebar = !this.isShowSidebar;
        })
        .zIndex(1)
        .margin({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 8,
          left: 16
        })

        // 侧边栏容器
        HdsSideBar({
          contentAreaMask: true,
          isShowSideBar: this.isShowSidebar!,
          minSideBarWidth: 280,
          sideBarColor:$r('sys.color.hds_sidebar_overlay'),
          sideBarPanelBuilder: (): void => this.sideBarBuilder(),
          contentPanelBuilder: (): void => this.contentBuilder(),
          sideBarContainerType: this.getSideBarType()
        })
      }
  }
}