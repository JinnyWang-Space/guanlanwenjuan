import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { AppAppearanceViewModel, AppGeneralViewModel, StartVibrator, WindowUtil } from "common";
import Logger from "common/src/main/ets/utils/Logger";
import { uiEffect } from "@kit.ArkGraphics2D";
import { SHCListItemModel } from "../model/SHCModel";
import { SHCViewModel } from "../viewmodel/SHCViewModel";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct SHCView {
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 获取按钮控件列表
  @Local buttonList: SHCListItemModel[] = new SHCViewModel().getButtonsList();
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });

  aboutToAppear(): void {
    if (!this.appAppearanceData.isButtonsShow) {
      this.buttonList.forEach((item: SHCListItemModel) => {
        item.is_on = false;
      })
      this.buttonList[0].isDivider = false;
    } else {
      this.buttonList.forEach((item: SHCListItemModel, index: number) => {
        if (index === 1) {
          item.is_on = this.appAppearanceData.isSideBarButtonShow;
        } else if (index === 2) {
          item.is_on = this.appAppearanceData.isSearchButtonShow;
        } else if (index === 3) {
          item.is_on = this.appAppearanceData.isScanButtonShow;
        } else if (index === 4) {
          item.is_on = this.appAppearanceData.isSettingButtonShow;
        }
      })
    }
  }

  // 设置列表 item
  @Builder
  snList(list_title: Resource, hapticList: SHCListItemModel[]) {
    // 列表标题
    Text(list_title)
      .width('100%')
      .textAlign(TextAlign.Start)
      .fontColor(Color.Gray)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .padding({ left: 12 })
      .margin({ bottom: 8 })

    // 列表
    List() {
      ForEach(hapticList, (item: SHCListItemModel, index: number) => {
        // 总震感开关列表项
        if (index === 0) {
          ListItem() {
            Column() {
              Row() {
                Row() {
                  Text(item.label)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Toggle({ isOn: item.is_on!!, type: ToggleType.Switch })
                    .selectedColor($r('app.color.list_on_color'))
                    .onChange((isOn: boolean) => {
                      this.appAppearanceData.isButtonsShow = isOn;
                      this.appAppearanceData.isSideBarButtonShow = isOn;
                      this.appAppearanceData.isSearchButtonShow = isOn;
                      this.appAppearanceData.isScanButtonShow = isOn;
                      this.appAppearanceData.isSettingButtonShow = isOn;
                      this.buttonList[0].isDivider = isOn;
                      for (let i = 1; i < this.buttonList.length; i++) {
                        const button = this.buttonList[i];
                        button.is_on = isOn;
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
                .padding({ left: 12, right: 12 })
                .clickEffect({ level: ClickEffectLevel.LIGHT })
              }
              .width('100%')
              .height(52)
              .alignItems(VerticalAlign.Center)
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

              if (item.isDivider) {
                Divider().padding({ left: 12, right: 12 })
              }
            }
            .width('100%')
          }
          .padding({
            top: 2,
            bottom: 2,
            left: 4,
            right: 4
          })
          .onClick(() => {
            // 开启列表项触感反馈
            if (this.appGeneralData.isHapticListItem) {
              StartVibrator()
            }
          })
        }
        // 具体震感列表项
        else {
          if (hapticList[0].is_on) {
            ListItem() {
              Column() {
                Row() {
                  Row() {
                    Text(item.label)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                    Blank()
                    Toggle({ isOn: item.is_on!!, type: ToggleType.Switch })
                      .selectedColor($r('app.color.list_on_color'))
                      .onChange((isOn: boolean) => {

                        if (index === 1) {
                          this.appAppearanceData.isSideBarButtonShow = isOn;
                        } else if (index === 2) {
                          this.appAppearanceData.isSearchButtonShow = isOn;
                        } else if (index === 3) {
                          this.appAppearanceData.isScanButtonShow = isOn;
                        } else {
                          this.appAppearanceData.isSettingButtonShow = isOn;
                        }

                        let isClosed: boolean = true;

                        for (let i = 1; i < this.buttonList.length; i++) {
                          const haptic = this.buttonList[i];
                          if (haptic.is_on) {
                            isClosed = false;
                          }
                        }

                        if (isClosed) {
                          this.buttonList[0].is_on = false;
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
                  .padding({ left: 12, right: 12 })
                  .clickEffect({ level: ClickEffectLevel.LIGHT })
                }
                .width('100%')
                .height(52)
                .alignItems(VerticalAlign.Center)
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

                if (item.isDivider) {
                  Divider().padding({ left: 12, right: 12 })
                }
              }
              .width('100%')
            }
            .padding({
              top: 2,
              bottom: 2,
              left: 4,
              right: 4
            })
            .onClick(() => {
              // 开启震动
              if (this.appGeneralData.isHapticListItem) {
                StartVibrator()
              }
            })
            .transition(TransitionEffect.OPACITY.combine(TransitionEffect.SLIDE)
              .animation({ duration: 300, curve: Curve.LinearOutSlowIn, delay: index * 80 }))
          }
        }
      })
    }
    .width('100%')
    .borderRadius(15)
    .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
      $r('app.color.sheet_list_card_bg_color'))
    .backgroundFilter(this.appAppearanceData.isComponentBlur ?
      uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
      uiEffect.createFilter().blur(BlurStyle.NONE))
    .margin({ bottom: 16 })
  }

  build() {
    Column() {

      // 触感反馈列表
      this.snList($r('app.string.list_shc_list_title_button_text'), this.buttonList)

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
