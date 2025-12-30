import { AppAppearanceViewModel,
  AppGeneralViewModel,
  DistributedDB, StartVibrator, Survey, SurveyStatus, WindowUtil } from "common";
import { SideBarListViewModel } from "../viewmodel/SideBarListViewModel";
import { SideBarListModel } from "../model/SideBarListModel";
import { SideMenu } from "../components/SideMenu";
import { AppStorageV2, PersistenceV2, window } from "@kit.ArkUI";
import { uiEffect } from "@kit.ArkGraphics2D";
import Logger from "common/src/main/ets/utils/Logger";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct SideBarView {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建变量用于监听是否显示侧边栏（子）
  @Consumer('isShowSideBar') isShowSidebar: boolean = false;
  // 创建侧边栏列表数据实例
  private mainVM: SideBarListModel[] = new SideBarListViewModel().mainVM;
  @Consumer('sideBarMainList') sideBarMainList: SideBarListModel[] = [...this.mainVM];
  // 用于监听侧边栏当前所选item对应的索引值
  @Consumer('sideBarMainIndex') sideBarMainIndex: number = 0;
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Left });

  build() {
    Column() {
      Blank().height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
      // Text('我的问卷')
      Text($r('app.string.my_surveys'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .fontColor(Color.Gray)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 24 })
        .margin({ top: 24, bottom: 12 })

      // SideBar菜单栏，不用 HdsSideMenu，因为不能高度自定义，例如：UI
      SideMenu({
        type: 0,
        items: this.sideBarMainList,
        selectedIndex: this.sideBarMainIndex,
        changeIndex: (selectedIndex: number) => {
          this.sideBarMainIndex = selectedIndex;
        }
      })

      // Text('资源')
      Text($r('app.string.resources'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .fontColor(Color.Gray)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 24 })
        .margin({ top: 24, bottom: 12 })

      SideMenu({
        type: 1,
        items: this.sideBarMainList,
        selectedIndex: this.sideBarMainIndex,
        changeIndex: (selectedIndex: number) => {
          this.sideBarMainIndex = selectedIndex;
        }
      })

    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
      $r('sys.color.background_secondary'))
    .backgroundFilter(this.appAppearanceData.isComponentBlur ?
      uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) : uiEffect.createFilter().blur(BlurStyle.NONE))
    .gesture(
      PanGesture(this.panOptionRight)
        .onActionEnd((event: GestureEvent) => {
          // 开启滑动触感反馈
          if (this.appGeneralData.isHapticSwipe) {
            StartVibrator()
          }
          this.isShowSidebar = false;
          Logger.info('[ContentView.PanGesture]', 'Pan end');
        })
    )
  }
}

@Builder
export function sideBarPanelBuilder() {
  SideBarView();
}