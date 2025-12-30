import { AppStorageV2, curves, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { AppAppearanceViewModel, AppGeneralViewModel, StartVibrator, WindowUtil } from "common";
import Logger from "common/src/main/ets/utils/Logger";
import { TipsListItemModel } from "../model/TipsModel";
import { TipsViewModel } from "../viewmodel/TipsViewModel";
import { uiEffect } from "@kit.ArkGraphics2D";
import { webview } from "@kit.ArkWeb";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct TipsView {
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
  // 是否展示 tips 演示视图，用于背景模糊（子）
  @Consumer('isShowView') isShowView: boolean = false;
  // 演示视图对应的url
  @Local webUrl: string = '';
  // 网站加载状态
  @Local webIsLoading: boolean = true;
  // 获取手势操作列表
  @Local gestureList: TipsListItemModel[] = new TipsViewModel().getGestureList();

  // 设置列表 item
  @Builder
  tipList(list_title: Resource, tipList: TipsListItemModel[]) {
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
    List({ space: 12 }) {
      ForEach(tipList, (item: TipsListItemModel, index: number) => {
        ListItem() {
          Column() {
            Row() {
              Row() {
                Text(item.label)
                  .fontSize(item.rotate_angle === 90 ? 20 : 16)
                  .fontWeight(item.rotate_angle === 90 ? FontWeight.Bold : FontWeight.Medium)
                  .animation({ duration: 200, curve: curves.springCurve(1, 2, 2, 3) })
                Blank()
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(24)
                  .fontColor([$r('sys.color.font_tertiary')])
                  .rotate({ angle: item.rotate_angle })
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

            if (item.rotate_angle === 90) {
              // 左滑操作
              if (item.id === 'swipe_left') {
                Column() {
                  Text($r('app.string.list_tips_gesture_prompt_text'))
                    .fontColor(Color.Gray)
                    .fontWeight(FontWeight.Regular)
                    .margin({ bottom: 12 })
                    .transition(TransitionEffect.translate({ y: 20 }).combine(TransitionEffect.OPACITY)
                      .animation({ duration: 300, curve: Curve.FastOutLinearIn }))

                  ForEach([$r('app.string.list_tips_gesture_left_1_text'),
                    $r('app.string.list_tips_gesture_left_2_text'),],
                    (item: string, index: number) => {
                      Column() {
                        // 标题
                        Text(item)
                          .width('100%')
                          .textAlign(TextAlign.Start)
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
                          .margin({ bottom: 12 })

                        Column() {
                          // 1. 桌面左滑
                          if (index === 0) {
                            Row() {
                              Text($r('app.string.list_tips_gesture_left_1_item_text'))
                                .width('50%')
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 6 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = 'www.baidu.com'
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                          }
                          // 2. 问卷中左滑
                          else if (index === 1) {
                            Row({ space: 6 }) {
                              SymbolGlyph($r('sys.symbol.phone_fill_1'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ right: 4 })
                              Text($r('app.string.list_tips_gesture_left_2_item_1_text'))
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = item
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                            .margin({ bottom: 12 })

                            Row({ space: 6 }) {
                              SymbolGlyph($r('sys.symbol.pad_fill'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ right: 4 })
                              Text($r('app.string.list_tips_gesture_left_2_item_2_text'))
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = item
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                          }
                        }
                        .margin({ bottom: 24 })
                        .renderGroup(false)
                      }
                      .transition(TransitionEffect.translate({ y: 20 }).combine(TransitionEffect.OPACITY)
                        .animation({ duration: 300, curve: Curve.FastOutLinearIn, delay: 75 * index }))
                    })
                }
                .padding({ left: 12, right: 12 })
              }
              // 右滑操作
              else if (item.id === 'swipe_right') {
                Column() {
                  Text($r('app.string.list_tips_gesture_prompt_text'))
                    .fontColor(Color.Gray)
                    .fontWeight(FontWeight.Regular)
                    .margin({ bottom: 12 })
                    .transition(TransitionEffect.translate({ y: 20 }).combine(TransitionEffect.OPACITY)
                      .animation({ duration: 300, curve: Curve.FastOutLinearIn }))

                  ForEach([$r('app.string.list_tips_gesture_right_1_text'),
                    $r('app.string.list_tips_gesture_right_2_text'),
                    $r('app.string.list_tips_gesture_right_3_text'),
                    $r('app.string.list_tips_gesture_right_4_text')],
                    (item: string, index: number) => {
                      Column() {
                        // 标题
                        Text(item)
                          .width('100%')
                          .textAlign(TextAlign.Start)
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
                          .margin({ bottom: 12 })

                        Column() {
                          // 1. 桌面右滑
                          if (index === 0) {
                            Row() {
                              Text($r('app.string.list_tips_gesture_right_1_item_text'))
                                .width('50%')
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = 'www.baidu.com'
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                          }
                          // 2. 问卷中右滑
                          else if (index === 1) {
                            Row({ space: 6 }) {
                              SymbolGlyph($r('sys.symbol.phone_fill_1'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ right: 4 })
                              Text($r('app.string.list_tips_gesture_right_2_item_1_text'))
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = item
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                            .margin({ bottom: 12 })

                            Row({ space: 6 }) {
                              SymbolGlyph($r('sys.symbol.pad_fill'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ right: 4 })
                              Text($r('app.string.list_tips_gesture_right_2_item_2_text'))
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = item
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                          }
                          // 3. 设置中右滑
                          else if (index === 2) {
                            Row() {
                              Text($r('app.string.list_tips_gesture_right_3_item_text'))
                                .width('50%')
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = 'www.baidu.com'
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                          }
                          // 4. 搜索页面中右滑
                          else if (index === 3) {
                            Row() {
                              Text($r('app.string.list_tips_gesture_right_4_item_text'))
                                .width('50%')
                                .fontWeight(FontWeight.Regular)
                              Blank()
                              Text($r('app.string.list_tips_gesture_left_operation_text'))
                                .fontSize(14)
                                .fontWeight(FontWeight.Regular)
                              SymbolGlyph($r('sys.symbol.chevron_right'))
                                .fontSize(24)
                                .fontColor([$r('sys.color.font_on_tertiary')])
                                .margin({ left: 8 })
                            }
                            .width('100%')
                            .onClick(() => {
                              // 开启震动
                              if (this.appGeneralData.isHapticListItem) {
                                StartVibrator()
                              }
                              // 打开演示视图
                              this.isShowView = true;
                              // 赋值url
                              this.webUrl = 'www.baidu.com'
                              promptAction.openToast({ message: '正在跳转至演示区域' })
                            })
                          }
                        }
                        .margin({ bottom: 24 })
                        .renderGroup(false)
                      }
                      .transition(TransitionEffect.translate({ y: 20 }).combine(TransitionEffect.OPACITY)
                        .animation({ duration: 300, curve: Curve.FastOutLinearIn, delay: 75 * index }))

                    })
                }
                .padding({ left: 12, right: 12 })
              }
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
        .borderRadius(15)
        .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
          $r('app.color.sheet_list_card_bg_color'))
        .backgroundFilter(this.appAppearanceData.isComponentBlur ?
          uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
          uiEffect.createFilter().blur(BlurStyle.NONE))
        .onClick(() => {
          // 开启震动
          if (this.appGeneralData.isHapticListItem) {
            StartVibrator()
          }
          if (item.rotate_angle === 90) {
            item.rotate_angle = 270;
          } else {
            item.rotate_angle = 90;
          }
        })
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  // 创建 Web 控制器
  private controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Scroll() {
      Stack({ alignContent: Alignment.Center }) {
        Scroll() {
          Column() {
            // 关于手势操作
            this.tipList($r('app.string.list_tips_list_title_gesture_text'), this.gestureList);
            Blank()
              .layoutWeight(1)
          }
          .width('100%')
          .align(Alignment.TopStart)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .padding({ left: 16, right: 16 })
        .enabled(this.isShowView ? false : true)
        .foregroundFilter(this.isShowView ? uiEffect.createFilter().blur(20) : uiEffect.createFilter().blur(0))
        .animation({ duration: 200, curve: Curve.Linear })

        // 显示演示区域
        if (this.isShowView) {
          Stack() {
            Stack() {
              Web({ src: this.webUrl, controller: this.controller })
                .borderRadius(20)
                .onPageBegin(() => {
                  this.webIsLoading = true;
                })
                .onPageEnd(() => {
                  this.webIsLoading = false;
                })
              Column().width('100%').height('100%')
            }
            .width('100%')
            .height('100%')

            if (this.webIsLoading) {
              Column() {
                LoadingProgress()
                  .size({ width: 48, height: 48 })
                  .color($r('app.color.list_on_color'))
                Text($r('app.string.is_loading_text'))
                  .fontColor($r('app.color.list_on_color'))
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('80%')
          .height('90%')
          .backgroundColor($r('app.color.sheet_list_card_bg_color'))
          .borderRadius(20)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.7, y: 0.7 })
            .animation({ duration: 200, curve: Curve.Linear })))
        }

      }
      .width('100%')
      .height('100%')
      .gesture(
        PanGesture(this.panOptionRight)
          .onActionEnd((event: GestureEvent) => {
            // 开启滑动触感反馈
            if (this.appGeneralData.isHapticSwipe) {
              StartVibrator()
            }
            if (this.isShowView) {
              animateToImmediately({ duration: 200, curve: Curve.Linear }, () => {
                this.isShowView = false;
              })
            } else {
              this.toolInfos.pop();
            }
            Logger.info('[ContentView.PanGesture]', 'Pan end');
          })
      )
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}


@ComponentV2
export struct TypingText {
  @Local private displayText: string = '';
  private fullText: string = '';
  private currentIndex: number = 0;
  private timerId: number = 0;
  @Param @Require textContent: string;
  @Param @Require speed: number;
  @Param @Require autoStart: boolean;

  aboutToAppear(): void {
    this.fullText = this.textContent;
    if (this.autoStart) {
      this.start();
    }
  }

  aboutToDisappear(): void {
    this.stop();
  }

  start() {
    this.stop();
    this.displayText = '';
    this.currentIndex = 0;

    this.timerId = setInterval(() => {
      if (this.currentIndex < this.fullText.length) {
        this.displayText += this.fullText.charAt(this.currentIndex);
        this.currentIndex++;
      } else {
        this.stop();
      }
    }, this.speed);
  }

  stop() {
    if (this.timerId) {
      clearInterval(this.timerId)
    }
  }

  build() {
    Text(this.displayText)
      .fontColor(Color.Gray)
      .fontWeight(FontWeight.Regular)
      .margin({ bottom: 12 })
  }
}