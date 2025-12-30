import {
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  AppViewModel,
  OffGripDetection,
  OnGripDetection,
  StartVibrator,
  WidthBreakpointType,
  WindowUtil
} from "common";
import { application, common, ConfigurationConstant } from "@kit.AbilityKit";
import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { HdsNavigation, HdsNavigationAttribute } from "@kit.UIDesignKit";
import { SettingsListItemModel } from "../model/SettingsModel";
import { SettingsViewModel } from "../../../../Index";
import { i18n } from "@kit.LocalizationKit";
import { requestAnimationFramePolyfill } from "@mcui/mccharts/src/main/ets/utils";
import Logger from "common/src/main/ets/utils/Logger";
import { uiEffect } from "@kit.ArkGraphics2D";
import { motion } from "@kit.MultimodalAwarenessKit";
import { deviceInfo } from "@kit.BasicServicesKit";

// 创建窗口实例
let windowStage: window.WindowStage;

// 设置半模态页面
@ComponentV2
export struct DotSheetBind {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 用于监听是否显示设置半模态（子）
  @Consumer('isToolViewShow') isToolViewShow: boolean = false;
  // 获取服务列表
  @Local supportList: SettingsListItemModel[] = new SettingsViewModel().getSupportList();
  // 获取数据列表
  @Local dataList: SettingsListItemModel[] = new SettingsViewModel().getDataList();
  // 获取视觉列表
  @Local appearanceList: SettingsListItemModel[] = new SettingsViewModel().getAppearanceList();
  // 获取通用列表
  @Local generalList: SettingsListItemModel[] = new SettingsViewModel().getGeneralList();
  // 获取指南列表
  @Local guideList: SettingsListItemModel[] = new SettingsViewModel().getGuideList();
  // 获取关于列表
  @Local aboutList: SettingsListItemModel[] = new SettingsViewModel().getAboutList();
  // 语言模式盒子
  @Local languageBox: Resource[] = [$r('app.string.list_language_follow_system_text'),
    $r('app.string.list_language_simplified_chinese_text'),
    $r('app.string.list_language_english_text')];
  // 深浅色模式盒子
  @Local colorModeBox: Resource[] = [$r('app.string.list_color_mode_follow_system_text'),
    $r('app.string.list_color_mode_light_text'),
    $r('app.string.list_color_mode_dark_text')];

  aboutToAppear(): void {
    // 半模态控制在栈顶页面，防止上次入栈的页面直接关闭未返回栈顶
    this.toolInfos.pop();

    // 如果 sdk 版本低于 20 或者 设备类型不是 phone，则去掉外观列表中的”智感握持功能“，该功能需要api>=20和手机
    if (deviceInfo.sdkApiVersion < 20 || deviceInfo.deviceType !== 'phone') {
      this.appearanceList.splice(3, 1);
      this.appearanceList[2].isDivider = false;
    }
    // 如果 设备类型不是 phone ，则去掉通用列表中的”音效与通知“
    if (deviceInfo.deviceType !== 'phone') {
      this.generalList.splice(2, 1);
      this.generalList[1].isDivider = false;
    }
  }

  // 监听语言模式变化
  @Monitor('appGeneralData.languageId')
  languageChange() {
    if (this.appGeneralData.languageId === 0) {
      application.getApplicationContext().setLanguage(i18n.System.getSystemLanguage());
    } else if (this.appGeneralData.languageId === 1) {
      application.getApplicationContext().setLanguage('zh-Hans');
    } else {
      application.getApplicationContext().setLanguage('en-Latn-US');
    }
  }

  // 语言模式菜单
  @Builder
  languageMenu() {
    Select([{ value: this.languageBox[0] }, { value: this.languageBox[1] }, { value: this.languageBox[2] }])
      .selected(this.appGeneralData.languageId!!)
      .value(this.languageBox[this.appGeneralData.languageId])
      .selectedOptionFontColor(Color.White)
      .selectedOptionBgColor($r('app.color.list_on_color'))
      .onSelect(() => {
        // 开启菜单项触感反馈
        // if (this.appGeneralData.isHapticMenu) {
        //   StartVibrator()
        // }
        if (this.appGeneralData.languageId === 0) {
          this.appGeneralData.language = i18n.System.getSystemLanguage();
        }
        if (this.appGeneralData.languageId === 1) {
          this.appGeneralData.language = 'zh-Hans';
        }
        if (this.appGeneralData.languageId === 2) {
          this.appGeneralData.language = 'en-Latn-US';
        }
      })
      .onClick(() => {
        // 开启菜单项触感反馈
        if (this.appGeneralData.isHapticMenu) {
          StartVibrator()
        }
      })
  }

  // 监听语言模式变化
  @Monitor('appGeneralData.colorModeId')
  darkModeChange() {
    if (this.appGeneralData.colorModeId === 0) {
      application.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } else if (this.appGeneralData.colorModeId === 1) {
      application.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } else {
      application.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    }
  }

  // 深浅色菜单
  @Builder
  colorModeMenu() {
    Select([{ value: this.colorModeBox[0] }, { value: this.colorModeBox[1] }, { value: this.colorModeBox[2] }])
      .selected(this.appGeneralData.colorModeId!!)
      .value(this.colorModeBox[this.appGeneralData.colorModeId])
      .selectedOptionFontColor(Color.White)
      .selectedOptionBgColor($r('app.color.list_on_color'))
      .onSelect(() => {
        // 开启菜单项触感反馈
        if (this.appGeneralData.isHapticMenu) {
          StartVibrator()
        }
      })
      .onClick(() => {
        // 开启菜单项触感反馈
        if (this.appGeneralData.isHapticMenu) {
          StartVibrator()
        }
      })
  }

  // 设置列表 item
  @Builder
  settingList(list_title: Resource, settingList: SettingsListItemModel[]) {
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
      ForEach(settingList, (item: SettingsListItemModel) => {
        ListItem() {
          Column() {
            Stack() {
              if (item.id === 'smart grip detection') {
                Toggle({ isOn: this.appAppearanceData.isSmartGripDetection!!, type: ToggleType.Switch })
                  .selectedColor($r('app.color.list_on_color'))
                  .zIndex(1)
                  .position({ top: 12, right: 12 })
                  .onChange((isOn: boolean) => {
                    if (isOn) {
                      OnGripDetection((data: motion.HoldingHandStatus) => {
                        this.appTmpData.holdingHandStatus = data;
                      });
                    } else {
                      OffGripDetection();
                    }
                  })
                  .onClick(() => {
                    // 开启按钮触感反馈
                    StartVibrator()
                  })
              }
              if (item.id === 'language') {
                Row() {
                  this.languageMenu()
                }
                .zIndex(1)
                .position({ top: 6, right: 12 })
              }
              if (item.id === 'color mode') {
                Row() {
                  this.colorModeMenu()
                }
                .zIndex(1)
                .position({ top: 6, right: 12 })
              }
              Row() {
                Row() {
                  Text(item.label)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  if (item.id === 'account') {
                    Row({ space: 6 }) {
                      if (this.appBasicData.isHuaweiID) {
                        Circle({ width: 6, height: 6 })
                          .foregroundColor(Color.Green)
                        Text($r('app.string.list_account_huawei_id_text'))
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                      } else {
                        Circle({ width: 6, height: 6 })
                          .foregroundColor(Color.Gray)
                        Text($r('app.string.list_account_unknown_text'))
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                      }
                    }
                    .margin({ right: 4 })
                  }
                  if (item.id !== 'smart grip detection' && item.id !== 'language' && item.id !== 'color mode') {
                    SymbolGlyph($r('sys.symbol.chevron_right'))
                      .fontSize(24)
                      .fontColor([$r('sys.color.font_tertiary')])
                  }
                }
                .width('100%')
              }
              .width('100%')
              .height(52)
              .alignItems(VerticalAlign.Center)
              .padding({ left: 12, right: 12 })
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
              .clickEffect({ level: ClickEffectLevel.LIGHT })
            }

            if (item.isDivider) {
              Divider().padding({ left: 12, right: 12 })
            }
          }
        }
        .padding({
          top: 2,
          bottom: 2,
          left: 4,
          right: 4
        })
        .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
          $r('app.color.sheet_list_card_bg_color'))
        .backgroundFilter(this.appAppearanceData.isComponentBlur ?
          uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
          uiEffect.createFilter().blur(BlurStyle.NONE))
        .onClick(() => {
          // 开启列表项触感反馈
          if (this.appGeneralData.isHapticListItem) {
            StartVibrator()
          }
          if (item.id !== 'smart grip detection' && item.id !== 'language' && item.id !== 'color mode') {
            this.toolInfos.pushPath({ name: 'ToolView', param: [item.label, item.id] as string[] });
          }
        })
      })
    }
    .width('100%')
    .borderRadius(15)
    .margin({ bottom: 16 })
  }

  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });

  build() {
    HdsNavigation(this.toolInfos) {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.appAppearanceData.staticWallpaper) {
          Image(this.appAppearanceData.staticWallpaper)
        }

        // 标题栏
        Row() {
          // Text('设置')
          Text($r('app.string.settings_text'))
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

            // 服务列表
            this.settingList($r('app.string.list_title_support_text'), this.supportList);
            // 数据列表
            this.settingList($r('app.string.list_title_data_text'), this.dataList);
            // 视觉列表
            this.settingList($r('app.string.list_title_appearance_text'), this.appearanceList);
            // 通用列表
            this.settingList($r('app.string.list_title_general_text'), this.generalList);
            // 指南列表
            this.settingList($r('app.string.list_title_guide_text'), this.guideList);
            // 关于列表
            this.settingList($r('app.string.list_title_about_us_text'), this.aboutList);

            Blank()
              .height(new WidthBreakpointType(16, 16, 0).getValue(this.windowUtil.mainWindowInfo.widthBp))

          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .backgroundColor($r('app.color.bind_sheet_bg_color'))
      .gesture(
        PanGesture(this.panOptionRight)
          .onActionEnd((event: GestureEvent) => {
            // 开启滑动触感反馈
            if (this.appGeneralData.isHapticSwipe) {
              StartVibrator()
            }
            this.isToolViewShow = false;
            Logger.info('[ContentView.PanGesture]', 'Pan end');
          })
      )
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .mode(NavigationMode.Stack)
  }
}

@Builder
export function DotSheetBindBuilder() {
  DotSheetBind();
}