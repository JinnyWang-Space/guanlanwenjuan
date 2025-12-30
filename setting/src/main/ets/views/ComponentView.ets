import { AppAppearanceViewModel, AppGeneralViewModel, StartVibrator, WindowUtil } from "common";
import { PreviewView } from "./BackgroundView"
import { AppStorageV2, PersistenceV2, window } from "@kit.ArkUI";
import Logger from "common/src/main/ets/utils/Logger";
import { uiEffect } from "@kit.ArkGraphics2D";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct ComponentView {
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });

  build() {
    Column() {
      PreviewView({
        isComponent: true, componentBlur: this.appAppearanceData.componentBlur, isSystemShare: false })

      Row() {
        Text($r('app.string.list_component_component_blur_text'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Toggle({ isOn: this.appAppearanceData.isComponentBlur!!, type: ToggleType.Switch })
          .selectedColor($r('app.color.list_on_color'))
          .onChange((isOn: boolean) => {
            if (!isOn) {
              this.appAppearanceData.componentBlur = 20;
            }
          })
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
          })
      }
      .width('100%')
      .height(52)
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
        $r('app.color.sheet_list_card_bg_color'))
      .backgroundFilter(this.appAppearanceData.isComponentBlur ?
        uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
        uiEffect.createFilter().blur(BlurStyle.NONE))
      .padding({ left: 12, right: 12 })
      .clickEffect({ level: ClickEffectLevel.LIGHT })

      if (this.appAppearanceData.isComponentBlur) {
        Slider({
          value: this.appAppearanceData.componentBlur!!,
          min: 0,
          max: 100,
          step: 0.1,
          style: SliderStyle.InSet
        })
          .margin({ left: 24, right: 24 })
          .selectedColor($r('app.color.list_on_color'))
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .gesture(
      PanGesture(this.panOptionRight)
        .onActionEnd((event: GestureEvent) => {
          // 开启滑动触感反馈
          if (this.appGeneralData.isHapticSwipe) {
            StartVibrator()
          }
          this.toolInfos.pop();
          Logger.info('[ContentView.PanGesture]', 'Pan end');
        })
    )
  }
}
