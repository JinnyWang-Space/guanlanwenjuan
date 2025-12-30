import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import {
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  copyFile,
  createFile,
  mediaPicker,
  readFile,
  readWriteFile,
  StartVibrator,
  unlink,
  WidthBreakpointType,
  WindowUtil
} from "common";
import { common } from "@kit.AbilityKit";
import { uiEffect } from "@kit.ArkGraphics2D";
import Logger from "common/src/main/ets/utils/Logger";
import { fileIo, fileUri } from "@kit.CoreFileKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct BackgroundView {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
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
      // 预览图
      PreviewView({ isComponent: false, componentBlur: 0, isSystemShare: false });

      Button() {
        Text($r('app.string.list_wallpaper_static_text'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }
      .backgroundColor($r('app.color.list_on_color'))
      .padding({
        top: 12,
        bottom: 12,
        left: 36,
        right: 36
      })
      .onClick(() => {
        // 开启按钮触感反馈
        if (this.appGeneralData.isHapticButton) {
          StartVibrator()
        }
        mediaPicker(0, 1, (uris: string[]) => {
          if (uris[0] !== undefined) {
            // 创建壁纸文件名称
            let filName: string = 'staticWallpaperDir/wallpaper-' + this.appAppearanceData.staticWallpaperId.toString();
            // 保存壁纸
            readWriteFile(this.context, filName, uris[0], (dstPath: string) => {
              this.appAppearanceData.staticWallpaper = fileUri.getUriFromPath(dstPath);
            })
            let unlinkId: number = this.appAppearanceData.staticWallpaperId - 1;
            let unLinkPath: string = `${this.context.filesDir}/staticWallpaperDir/wallpaper-${unlinkId}`
            unlink(unLinkPath);
            this.appAppearanceData.staticWallpaperId = this.appAppearanceData.staticWallpaperId + 1;
          }
        });
      })
      .margin({ bottom: 12 })

      Button() {
        Text($r('app.string.list_wallpaper_clear_text'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }
      .backgroundColor(Color.Red)
      .padding({
        top: 12,
        bottom: 12,
        left: 36,
        right: 36
      })
      .onClick(async () => {
        // 开启按钮触感反馈
        if (this.appGeneralData.isHapticButton) {
          StartVibrator()
        }
        try {
          let unlinkId: number = this.appAppearanceData.staticWallpaperId - 1;
          let unLinkPath: string = `${this.context.filesDir}/staticWallpaperDir/wallpaper-${unlinkId}`
          await unlink(unLinkPath);
          this.appAppearanceData.staticWallpaper = '';
          this.appAppearanceData.staticWallpaperId += 1;
        } catch (error) {
          promptAction.openToast({ message: '失败' })
        }
      })

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

@ComponentV2
export struct PreviewView {
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  @Param @Require isComponent: boolean;
  @Param @Require componentBlur: number;
  @Param @Require isSystemShare: boolean;

  build() {
    Column() {
      // 预览图
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('sys.color.background_secondary'))
          .borderRadius(15)
          .shadow({
            color: 0XE0E0E0,
            radius: 15,
            offsetY: new WidthBreakpointType(8, 6, 6).getValue(this.windowUtil.mainWindowInfo.widthBp)
          })

        // Image(fileUri.getUriFromPath(this.appAppearanceData.staticWallpaper))
        if (this.appTmpData.isSystemShare) {
          if (this.appTmpData.systemShareImgUri) {
            Image(this.appTmpData.systemShareImgUri)
              .borderRadius(15)
          }
        } else {
          if (this.appAppearanceData.staticWallpaper) {
            Image(this.appAppearanceData.staticWallpaper)
              .borderRadius(15)
          }
        }


        TextClock()
          .format('hh:mm')
          .fontSize(10)
          .fontColor($r('sys.color.font'))
          .fontWeight(FontWeight.Bold)
          .position({ top: '2%', left: 12 })

        SymbolGlyph($r('sys.symbol.battery_100percent'))
          .fontSize(12)
          .fontColor([$r('sys.color.font')])
          .fontWeight(FontWeight.Bold)
          .position({ top: '2%', right: 12 })

        // 侧边栏按钮
        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.close_sidebar'))
              .fontWeight(FontWeight.Normal)
              .fontSize(12)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
              .hitTestBehavior(HitTestMode.None)
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .size({ width: 20, height: 20 })

          Text($r('app.string.list_appearance_sidebar_text'))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 8 })
        }
        .width('100%')
        .position({
          top: this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG ? '6%' : '10%',
          left: 12
        })

        if (this.isComponent) {
          Row() {
            Row() {
              Column() {
                SymbolGlyph($r('sys.symbol.plus'))
                  .fontSize(new WidthBreakpointType(
                    24 * 0.5,
                    24 * 0.5,
                    24 * 0.25,
                  ).getValue(this.windowUtil.mainWindowInfo.widthBp))
              }
              .width(new WidthBreakpointType(
                48 * 0.5,
                48 * 0.5,
                48 * 0.25,
              ).getValue(this.windowUtil.mainWindowInfo.widthBp),)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius({
                topLeft: new WidthBreakpointType(
                  2 * 0.5,
                  2 * 0.5,
                  2 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp),
                bottomLeft: new WidthBreakpointType(
                  2 * 0.5,
                  2 * 0.5,
                  2 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp),
                topRight: new WidthBreakpointType(
                  8 * 0.5,
                  8 * 0.5,
                  8 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp),
                bottomRight: new WidthBreakpointType(
                  8 * 0.5,
                  8 * 0.5,
                  8 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp),
              })
              .margin({
                right: new WidthBreakpointType(
                  16 * 0.5,
                  16 * 0.5,
                  16 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp),
              })

              // 添加问卷 item
              Text($r('app.string.list_component_create_survey_text'))
                .fontSize(new WidthBreakpointType(
                  16 * 0.5,
                  16 * 0.5,
                  16 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp),)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height(new WidthBreakpointType(
              80 * 0.5,
              80 * 0.5,
              80 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp),)
            .stateStyles({
              normal: {
                .backgroundColor('')
              },
              pressed: {
                .backgroundColor(Color.Gray)
                .borderRadius(new WidthBreakpointType(
                  12 * 0.5,
                  12 * 0.5,
                  12 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp))
              },
              focused: {
                .backgroundColor(Color.Gray)
                .borderRadius(new WidthBreakpointType(
                  12 * 0.5,
                  12 * 0.5,
                  12 * 0.25,
                ).getValue(this.windowUtil.mainWindowInfo.widthBp))
              }
            })
            .padding({
              top: new WidthBreakpointType(
                8 * 0.5,
                8 * 0.5,
                8 * 0.25,
              ).getValue(this.windowUtil.mainWindowInfo.widthBp),
              bottom: new WidthBreakpointType(
                8 * 0.5,
                8 * 0.5,
                8 * 0.25,
              ).getValue(this.windowUtil.mainWindowInfo.widthBp),
              left: new WidthBreakpointType(
                16 * 0.5,
                16 * 0.5,
                16 * 0.25,
              ).getValue(this.windowUtil.mainWindowInfo.widthBp),
              right: new WidthBreakpointType(
                16 * 0.5,
                16 * 0.5,
                16 * 0.25,
              ).getValue(this.windowUtil.mainWindowInfo.widthBp),
            })
          }
          .width(
            new WidthBreakpointType(
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width * 0.5) - 24,
              this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width * 0.5) - 24,
              (this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width * 0.25) -
                344 * 0.25) / 2 - 32 * 0.35,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp)
          )
          .borderRadius(
            new WidthBreakpointType(
              12 * 0.5,
              12 * 0.5,
              12 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .padding({
            top:
            new WidthBreakpointType(
              4 * 0.5,
              4 * 0.5,
              4 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp),
            bottom: new WidthBreakpointType(
              4 * 0.5,
              4 * 0.5,
              4 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp),
            left: new WidthBreakpointType(
              6 * 0.5,
              6 * 0.5,
              6 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp),
            right: new WidthBreakpointType(
              6 * 0.5,
              6 * 0.5,
              6 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp),
          })
          .position({
            top: this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG ? '15%' : '25%',
            left: new WidthBreakpointType(
              12,
              12,
              172 * 0.25,
            ).getValue(this.windowUtil.mainWindowInfo.widthBp)
          })
          .backgroundColor(this.appAppearanceData.isComponentBlur ? '' : $r('app.color.list_card_bg_color'))
          .backgroundFilter(this.appAppearanceData.isComponentBlur ?
            uiEffect.createFilter().blur(this.componentBlur) : uiEffect.createFilter().blur(BlurStyle.NONE))
        }

        // 底部小白条
        Row()
          .width('30%')
          .height(2)
          .borderRadius(1)
          .backgroundColor(Color.Gray)
          .margin({ bottom: 4 })
      }
      .align(Alignment.Bottom)
      .width(
        new WidthBreakpointType(
          this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width * 0.5),
          this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width * 0.4),
          this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width * 0.25),
        ).getValue(this.windowUtil.mainWindowInfo.widthBp))
      .height(
        new WidthBreakpointType(
          this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.height * 0.5),
          this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.height * 0.4),
          this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.height * 0.25),
        ).getValue(this.windowUtil.mainWindowInfo.widthBp))
      .backgroundColor($r('sys.color.background_secondary'))
      .margin({ top: 24 })
      .borderRadius(15)


      // 预览文本
      Text($r('app.string.list_appearance_preview_text'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font'))
        .margin({ top: 24, bottom: 16 })
    }
  }
}
