import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { PersistenceV2, promptAction } from "@kit.ArkUI";
import { AppAppearanceViewModel, AppGeneralViewModel, StartVibrator } from "common";
import {
  AboutView,
  AccountView,
  BackgroundView,
  ChangelogView,
  ComponentView,
  FeedbackView,
  PrivacyAgreementView,
  SHCView,
  SoundNotificationView,
  TipsView,
  UserAgreementView
} from "setting";
import { uiEffect } from "@kit.ArkGraphics2D";

@ComponentV2
export struct ToolView {
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 标题信息
  private toolId: string[] = this.toolInfos.getParamByName('ToolView')[0] as string[];
  // 用于监听是否显示设置半模态（子）
  @Consumer('isToolViewShow') isToolViewShow: boolean = false;
  // 是否展示 tips 演示视图，用于缩放（父）
  @Provider('isShowView') isShowView: boolean = false;

  aboutToAppear(): void {
    promptAction.openToast({ message: JSON.stringify(this.toolId[1]) })
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.appAppearanceData.staticWallpaper) {
          Image(this.appAppearanceData.staticWallpaper)
        }
        // 标题栏
        Row() {
          // 返回上一步按钮
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            this.toolInfos.pop();
          })
          .margin({ right: 12 })

          Text(this.toolId[0])
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
          Blank()
          // 关闭按钮
          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            this.isToolViewShow = false;
          })
        }
        .width('100%')
        .padding(16)
        .zIndex(1)

        Scroll() {
          Column() {
            Blank().height(72)
            if (this.toolId[1] === 'feedback') {
              FeedbackView()
            } else if (this.toolId[1] === 'account') {
              AccountView()
            } else if (this.toolId[1] === 'wallpaper') {
              BackgroundView()
            } else if (this.toolId[1] === 'component') {
              ComponentView()
            } else if (this.toolId[1] === 'show/hide components') {
              SHCView()
            } else if (this.toolId[1] === 'sounds & notifications') {
              SoundNotificationView()
            } else if (this.toolId[1] === 'tips') {
              TipsView()
            } else if (this.toolId[1] === 'changelog') {
              ChangelogView()
            } else if (this.toolId[1] === 'about') {
              AboutView()
            } else if (this.toolId[1] === 'privacy agreement') {
              PrivacyAgreementView()
            } else if (this.toolId[1] === 'user agreement') {
              UserAgreementView()
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        // .backgroundFilter(this.isShowView ? uiEffect.createFilter().blur(20) :
        //   uiEffect.createFilter().blur(BlurStyle.NONE))
        .scale(this.isShowView ? { x: 0.9, y: 0.9 } : { x: 1, y: 1 })
        .animation({ duration: 200, curve: Curve.Linear })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bind_sheet_bg_color'))
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}

@Builder
export function ToolBuilder() {
  ToolView();
}