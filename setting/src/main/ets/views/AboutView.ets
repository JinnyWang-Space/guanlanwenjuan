import Want from "@ohos.app.ability.Want"
import common from "@ohos.app.ability.common"
import { AppStorageV2, PersistenceV2, window } from "@kit.ArkUI";
import { AppAppearanceViewModel, AppGeneralViewModel, StartVibrator, WindowUtil } from "common";
import Logger from "common/src/main/ets/utils/Logger";
import { uiEffect } from "@kit.ArkGraphics2D";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct AboutView {
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });

  build() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(64)
        .height(64)
        .borderRadius(15)
        .margin({ top: 16, bottom: 12 })
      // Text('观澜问卷')
      Text($r('app.string.app_name'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 36 })

      Column() {
        ForEach([0, 0], (item: string, index: number) => {
          Row() {
            Column({ space: 4 }) {
              if (index === 0) {
                Text($r('app.string.list_about_version_text'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                // Text('1.0.0')
                Text('1.0.0 - 探索版 ')
                  .fontSize(16)
                  .opacity(0.7)
              } else {
                Text($r('app.string.list_about_contact_us_text'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text('jinnywang@petalmail.com')
                  .fontSize(16)
                  .opacity(0.7)
              }
            }
            .alignItems(HorizontalAlign.Start)

            Blank()
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(24)
              .fontColor([$r('sys.color.font_tertiary')])
          }
          .width('100%')
          .height(64)
          .padding({ left: 12, right: 12 })
          .margin(index === 0 ? { top: 6 } : '' || index === 1 ? { bottom: 6 } : '')

          if (index < 1) {
            Divider().padding({ left: 12, right: 12 })
          }
        })
      }
      .width('100%')
      .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
        $r('app.color.sheet_list_card_bg_color'))
      .backgroundFilter(this.appAppearanceData.isComponentBlur ?
        uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
        uiEffect.createFilter().blur(BlurStyle.NONE))
      .borderRadius(15)

      Blank()
      // Text('津ICP备2025039701号-1A')
      Text($r('app.string.list_about_icp_text'))
        .fontSize(12)
        .fontColor($r('app.color.list_on_color'))
        .padding(4)
        .borderRadius(4)
        .stateStyles({
          normal: {
            .backgroundColor('')
          },
          pressed: {
            .backgroundColor($r('app.color.list_on_foucs_color'))
          }
        })
        .onClick(() => {
          const want: Want = {
            uri: 'https://beian.miit.gov.cn',
            action: 'ohos.want.action.viewData' // 系统标准动作，用于打开链接，可以替换成其他应用
          };
          const context: common.UIAbilityContext = this.getUIContext().getHostContext()! as common.UIAbilityContext
          context.startAbility(want).then(() => {
            console.info('跳转浏览器成功');
          })
            .catch((err: BusinessError) => {
              console.error(`跳转失败:  ${err.message}`)
            });
        })
      // Text('版权所有 © 2025 观澜问卷 保留一切权利')
      Text($r('app.string.list_about_copy_right_text'))
        .fontSize(12)
        .margin({ bottom: 24 })
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
