import {
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  DistributedDB,
  FormInfo,
  getTargetTitle,
  MarketCloud,
  StartVibrator,
  Survey,
  SurveyTemplate,
  WidthBreakpointType,
  WindowUtil
} from "common";
import {
  AppStorageV2,
  PersistenceV2,
  promptAction,
  SymbolGlyphModifier,
  window,
  ChipGroupItemOptions,
} from "@kit.ArkUI";
import { SideBarListModel } from "../model/SideBarListModel";
import { SideBarListViewModel } from "../viewmodel/SideBarListViewModel";
import { ShowListModel } from "../model/ShowListModel";
import { ShowListViewModel } from "../viewmodel/ShowListViewModel";
import { abilityAccessCtrl, AbilityConstant, common } from "@kit.AbilityKit";
import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from "@hms.hds.hdsBaseComponent";
import { image } from "@kit.ImageKit";
import { generateBarcode, scanBarcode, scanCore } from "@kit.ScanKit";
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit'
import { FunctionComponent } from "@hms.ai.AgentFramework";
import Logger from "common/src/main/ets/utils/Logger";
import { cloudDatabase } from "@kit.CloudFoundationKit";
import i18n from "@ohos.i18n";
import { DotSheetBindBuilder } from "setting";
import { uiEffect } from "@kit.ArkGraphics2D";
import { vibrator } from "@kit.SensorServiceKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct ContentView {
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 创建变量用于监听是否显示侧边栏（子）
  @Consumer('isShowSideBar') isShowSidebar: boolean = false;
  // 创建侧边栏列表数据实例
  private mainVM: SideBarListModel[] = new SideBarListViewModel().mainVM;
  // 侧边栏当前所选item对应的索引值
  @Consumer('sideBarMainIndex') sideBarMainIndex: number = 0;
  // 创建主视图列表数据实例
  private showListVM: ShowListModel[] = new ShowListViewModel().mainVM;
  @Consumer('showList') showList: ShowListModel[] = [...this.showListVM];
  // 菜单栏创建问卷图标
  @Local menuIconModifier1: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.doc_plaintext')).fontSize('24vp').fontColor([Color.Gray]);
  // 修改菜单栏创建问卷图标 ———— 恢复
  @Local MenuIconModifierRestore: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.arrow_counterclockwise')).fontSize('24vp').fontColor([Color.Gray]);
  // 修改菜单栏创建问卷图标 ———— 立即发布
  @Local MenuIconModifierPublish: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.paperplane')).fontSize('24vp').fontColor([Color.Gray]);
  // 修改菜单栏创建问卷图标 ———— 结束发布
  @Local MenuIconModifierStopPublish: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.stop_circle')).fontSize('24vp').fontColor([Color.Gray]);
  // 修改菜单栏创建问卷图标 ———— 删除
  @Local MenuIconModifierTrash: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.trash')).fontSize('24vp').fontColor([Color.Gray]);
  // 设置菜单栏创建问卷图标 ———— 设置
  @Local MenuIconModifierSetting: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.gearshape')).fontSize('24vp').fontColor([Color.Gray]);
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;
  @Local allChipGroup: ChipGroupItemOptions[] = [];
  @Local targetChipGroup: ChipGroupItemOptions[] = [];
  @Local chipGroupSelectedIndex: number[] = [0];
  // 标题工具的位置，用在手机和折叠屏（智感握持）
  @Local positionRight: number = 16;

  // 监听握持手位置
  @Monitor('appTmpData.holdingHandStatus')
  holdingHandStatusChange() {
    // 开启智感握持
    if (this.appAppearanceData.isSmartGripDetection) {
      // 未握持
      if (this.appTmpData.holdingHandStatus === 0) {
        this.positionRight = 16;
      }
      // 左手握持
      else if (this.appTmpData.holdingHandStatus === 1) {
        this.positionRight = this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width) - 16 - 52;
      }
      // 右手握持
      else if (this.appTmpData.holdingHandStatus === 2) {
        this.positionRight = 16;
      }
      // 双手握持
      else if (this.appTmpData.holdingHandStatus === 3) {
        this.positionRight = 16;
      }
      // 未识别
      else {
        this.positionRight = 16;
      }
    }
  }

  // 监听侧边栏索引值变化
  @Monitor('sideBarMainIndex')
  async sideBarMainIndexChange() {
    if (this.sideBarMainIndex === 5 && this.appTmpData.isNetwork) {
      this.initMarket();
    }
  }

  // 监听语言模式变化
  @Monitor('appGeneralData.language')
  languageChange() {
    if (this.appGeneralData.language === 'en-Latn-US') {
      this.targetChipGroup = [];
      this.allChipGroup.map((chip: ChipGroupItemOptions) => {
        const textJSON: string[] = JSON.parse(chip.label.text) as string[];
        const label: string = textJSON[1];
        this.targetChipGroup.push({ label: { text: label } })
      })
    } else if (this.appGeneralData.language === 'zh-Hans') {
      this.targetChipGroup = [];
      this.allChipGroup.map((chip: ChipGroupItemOptions) => {
        const textJSON: string[] = JSON.parse(chip.label.text) as string[];
        const label: string = textJSON[0];
        this.targetChipGroup.push({ label: { text: label } })
      })
    }
  }

  // 修改菜单 —— 删除
  @Builder
  MenuView(surveyId: number, index: number) {
    if (this.sideBarMainIndex < 4) {
      Menu() {
        MenuItem({ symbolStartIcon: this.MenuIconModifierTrash, content: $r('app.string.move_to_trash') })
          .onClick(async () => {
            // 开启菜单项触感反馈
            if (this.appGeneralData.isHapticMenu) {
              StartVibrator()
            }
            const success: boolean = await this.distributedDB.deleteSurvey(surveyId, false);
            if (success) {
              this.surveys = await this.distributedDB.getAllSurveys();
              this.refresh = true;
              promptAction.openToast({ message: '已删除' })
            }
          })
      }
    }
    // 废纸篓页面菜单
    if (this.sideBarMainIndex === 4) {
      Menu() {
        MenuItem({ symbolStartIcon: this.MenuIconModifierRestore, content: $r('app.string.restore') })
          .onClick(async () => {
            // 开启菜单项触感反馈
            if (this.appGeneralData.isHapticMenu) {
              StartVibrator()
            }
            const success: boolean = await this.distributedDB.restoreSurvey(surveyId);
            if (success) {
              this.surveys = await this.distributedDB.getAllSurveys();
              this.refresh = true;
              promptAction.openToast({ message: '已恢复该问卷' })
            }
          })
        MenuItem({ symbolStartIcon: this.MenuIconModifierTrash, content: $r('app.string.permanently_delete') })
          .onClick(async () => {
            // 开启菜单项触感反馈
            if (this.appGeneralData.isHapticMenu) {
              StartVibrator()
            }
            const success: boolean = await this.distributedDB.deleteSurvey(surveyId, true);
            if (success) {
              this.surveys = await this.distributedDB.getAllSurveys();
              this.refresh = true;
              promptAction.openToast({ message: '已彻底删除' })
            }
          })
      }
    }
  }

  // 创建菜单
  @Builder
  createMenu() {
    Menu() {
      MenuItem({ symbolStartIcon: this.menuIconModifier1, content: $r('app.string.create_survey') })
        .onClick(() => {
          // 开启菜单项触感反馈
          if (this.appGeneralData.isHapticMenu) {
            StartVibrator()
          }
          this.pageInfos.pushPath({ name: 'CreateSurveyView' });
        })
    }
  }

  // 创建导航器实例（父）
  @Provider('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 用于监听是否显示设置半模态（父）
  @Consumer('isToolViewShow') isToolViewShow: boolean = false;

  // 设置菜单
  @Builder
  dotMenu() {
    Menu() {
      MenuItem({ symbolStartIcon: this.MenuIconModifierSetting, content: $r('app.string.settings_text') })
        .onClick(() => {
          // 开启菜单项触感反馈
          if (this.appGeneralData.isHapticMenu) {
            StartVibrator()
          }
          this.isToolViewShow = true;
        })
    }
  }

  // 创建全部问卷数据实例（子）
  @Consumer('surveys') surveys: Survey[] = [];
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);
  // 创建模块实例
  @Local marketCategories: MarketCloud[] = [];
  // 创建模板问卷实例
  @Local surveyTemplate: SurveyTemplate[] = [];

  async aboutToAppear(): Promise<void> {
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  @Local isFirstLoading: boolean = false;
  @Local isLoading: boolean = false;

  // 模板列表
  @Builder
  marketList(category_id: string, img: Resource) {
    Refresh({ refreshing: this.isLoading!! }) {
      List({
        space: new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp)
      }) {
        ForEach(this.surveyTemplate, (survey: SurveyTemplate, surveyIndex: number) => {
          if (survey.category_id === category_id) {
            ListItem() {
              // item 视图
              Row() {
                Row() {
                  Column() {

                  }
                  .width(48)
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .backgroundImage(img)
                  .backgroundImageSize(ImageSize.Cover)
                  .borderRadius({
                    topLeft: 2,
                    bottomLeft: 2,
                    topRight: 8,
                    bottomRight: 8
                  })
                  .margin({ right: 16 })

                  Column() {
                    // Text(survey.title)
                    Text(getTargetTitle(survey.title, this.appGeneralData.language === 'en-Latn-US' ? 1 : 0))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    // Text(`引用量：${survey.usage_count}`)
                    Text() {
                      Span($r('app.string.usage_count_text'))
                      Span('：')
                      Span(`${survey.usage_count}`)
                    }
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  }
                  .layoutWeight(1)
                  .height('100%')
                  .justifyContent(FlexAlign.End)
                  .alignItems(HorizontalAlign.Start)

                }
                .width('100%')
                .height(80)
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
                .padding({
                  top: 8,
                  bottom: 8,
                  left: 16,
                  right: 16
                })
              }
              .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                $r('app.color.list_card_bg_color'))
              .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                uiEffect.createFilter().blur(BlurStyle.NONE))
              .borderRadius(12)
              .padding({
                top: 4,
                bottom: 4,
                left: 6,
                right: 6
              })
              .onClick(() => {
                // 开启列表项震动
                if (this.appGeneralData.isHapticListItem) {
                  StartVibrator()
                }
                this.pageInfos.pushPath({ name: 'MarketSurveyView', param: survey.id });
              })
              .clickEffect({ level: ClickEffectLevel.LIGHT })
            }
          }
        }, (survey: SurveyTemplate, surveyIndex: number) => JSON.stringify(survey) + surveyIndex)
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .lanes(new WidthBreakpointType(1, 2, 2).getValue(this.windowUtil.mainWindowInfo.widthBp), 32)
      .contentEndOffset(24)
      .padding({
        left: this.isShowSidebar ?
          new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) :
          new WidthBreakpointType(16, 16, 32 + 140).getValue(this.windowUtil.mainWindowInfo.widthBp),
        right: this.isShowSidebar ?
          new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) :
          new WidthBreakpointType(16, 16, 32 + 140).getValue(this.windowUtil.mainWindowInfo.widthBp)
      })
      .animation({ duration: 500, curve: Curve.Friction })

    }
    .width('100%')
    .layoutWeight(1)
    .onRefreshing(() => {
      setTimeout(() => {
        if (this.appTmpData.isNetwork) {
          this.initMarket();
        }
      }, 2000)
      console.info('onRefreshing test');
    })

  }

  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  private panOptionLeft: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Left });
  // 创建 list 滑动控制器，用于控制问卷模板操作块进行滑动
  private chipScroller: ListScroller = new ListScroller();

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 标题栏
      Row() {
        // 标题
        Text(this.mainVM[this.sideBarMainIndex].label)
        // .width(
        //   !this.appAppearanceData.isSmartGripDetection ?
        //     new WidthBreakpointType(
        //       `${this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.width) - 16 * 3 - 12 * 2 -
        //         40 * 4}`,
        //       '',
        //       ''
        //     ).getValue(this.windowUtil.mainWindowInfo.widthBp) : '')
          .layoutWeight(1)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.MARQUEE })
          .margin({
            left:
            // this.isShowSidebar && this.appAppearanceData.isSideBarButtonShow ? 0 : 56
            //   ||
            !this.isShowSidebar && !this.appAppearanceData.isSideBarButtonShow ? 0 : 0
              || !this.isShowSidebar && this.appAppearanceData.isSideBarButtonShow ? 56 : 0
          })
          .animation({ duration: 400, curve: Curve.EaseInOut })

        Blank()

        // 搜索框 / 搜索按钮
        // 手机
        if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD) {
          if (!this.appAppearanceData.isSmartGripDetection) {
            Button() {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontWeight(FontWeight.Normal)
                .fontSize(24)
                .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            }
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .height(40)
            .width(40)
            .visibility(this.appAppearanceData.isSearchButtonShow ? Visibility.Visible : Visibility.None)
            .onClick(() => {
              // 开启按钮触感反馈
              if (this.appGeneralData.isHapticButton) {
                StartVibrator()
              }
              this.pageInfos.pushPath({ name: 'SearchView' });
            })
          }
        }
        // 除手机外的设备
        else {
          Button() {
            Row() {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontSize(16)
                .margin({ left: 12, right: 12 })
                .fontColor([$r('sys.color.search_icon_color')])
              Text($r('app.string.search_text'))
                .fontColor($r('sys.color.search_text_color'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
          }
          .width('30%')
          .height(40)
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .borderRadius(20)
          .visibility(this.appAppearanceData.isSearchButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            StartVibrator();
            this.pageInfos.pushPath({ name: 'SearchView' });
          })
        }

        if (!this.appAppearanceData.isSmartGripDetection ||
          this.windowUtil.mainWindowInfo.widthBp > WidthBreakpoint.WIDTH_MD) {
          // 扫码按钮
          Button() {
            SymbolGlyph($r('sys.symbol.line_viewfinder'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .margin({ left: 12 })
          .visibility(this.appAppearanceData.isScanButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            // 定义扫码参数options
            let options: scanBarcode.ScanOptions = {
              scanTypes: [scanCore.ScanType.ALL],
              enableMultiMode: true,
              enableAlbum: true
            };
            try {
              // 可调用getHostContext接口获取当前页面关联的Context
              scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options)
                .then((result: scanBarcode.ScanResult) => {
                  this.pageInfos.pushPath({ name: 'WriteSurveyView', param: result.originalValue });
                  // 解析码值结果跳转应用服务页
                  Logger.info('[Scan CPSample]',
                    `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result.originalValue)}`);
                })
                .catch((error: BusinessError) => {
                  Logger.error('[Scan CPSample]',
                    `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
                });
            } catch (error) {
              Logger.error('[Scan CPSample]',
                `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
            }
          })

          // 设置按钮
          Button() {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .bindMenu(this.dotMenu())
          .visibility(this.appAppearanceData.isSettingButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
          })
          .margin({ left: 12 })
        }

      }
      .width('100%')
      .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
      .justifyContent(FlexAlign.Start)
      .padding({
        top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
        left: 16, right: 16
      })
      .zIndex(1)

      // 将标题栏中的工具改为纵向布局（在手机和折叠屏），用于搭配智感握持
      if (this.appAppearanceData.isSmartGripDetection &&
        this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
        Column({ space: 12 }) {
          Button() {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .visibility(this.appAppearanceData.isSearchButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            this.pageInfos.pushPath({ name: 'SearchView' });
          })

          // 扫码按钮
          Button() {
            SymbolGlyph($r('sys.symbol.line_viewfinder'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .visibility(this.appAppearanceData.isScanButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            // 定义扫码参数options
            let options: scanBarcode.ScanOptions = {
              scanTypes: [scanCore.ScanType.ALL],
              enableMultiMode: true,
              enableAlbum: true
            };
            try {
              // 可调用getHostContext接口获取当前页面关联的Context
              scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options)
                .then((result: scanBarcode.ScanResult) => {
                  this.pageInfos.pushPath({ name: 'WriteSurveyView', param: result.originalValue });
                  // 解析码值结果跳转应用服务页
                  Logger.info('[Scan CPSample]',
                    `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result.originalValue)}`);
                })
                .catch((error: BusinessError) => {
                  Logger.error('[Scan CPSample]',
                    `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
                });
            } catch (error) {
              Logger.error('[Scan CPSample]',
                `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
            }
          })

          // 设置按钮
          Button() {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .bindMenu(this.dotMenu())
          .visibility(this.appAppearanceData.isSettingButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
          })
        }
        .zIndex(2)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .padding({
          top: 13,
          bottom: 13,
          left: 6,
          right: 6
        })
        .borderRadius(26)
        .position({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.windowSize.height) / 2 - 85,
          right: this.positionRight
        })
        .animation({ duration: 300, curve: Curve.Friction })
      }

      // 主体视图
      Scroll() {
        Column() {
          Blank()
            .height(
              new WidthBreakpointType(
                this.sideBarMainIndex < 5 ?
                  this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24 :
                  this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56,
                this.sideBarMainIndex < 5 ?
                  this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24 :
                  this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56,
                this.sideBarMainIndex < 5 ?
                  this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 +
                    38 : this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) +
                  56).getValue(this.windowUtil.mainWindowInfo.widthBp)
            )

          // Text(JSON.stringify(this.appTmpData.isNetwork))
          // Text(JSON.stringify(this.surveys))
          //
          // Text(`云数据库（模块）：${JSON.stringify(this.marketCategories)}`)
          // Text(`云数据库（问卷）${JSON.stringify(this.surveyTemplate)}`)
          // Text(`云数据库（问题）${JSON.stringify(this.questionTemplate)}`)
          //
          // Button().onClick(async () => {
          //   let databaseZone = cloudDatabase.zone('guanlanwenjuan');
          //   let condition = new cloudDatabase.DatabaseQuery(SurveyCloud);
          //   try {
          //     let survey = new SurveyCloud();
          //     survey.id = 3;
          //     survey.title = '问卷3';
          //     survey.description = '问卷3描述';
          //     survey.created_time = 0;
          //     survey.status = 'draft';
          //     survey.deleted = 0;
          //     let record = await databaseZone.upsert([survey]);
          //     Logger.info('[testTag]', `Succeeded in upserting a book, result: ${JSON.stringify(record)}`);
          //
          //   } catch (err) {
          //     Logger.error('[testTag]', `Failed to upsert a book, code: ${err.code}, message: ${err.message}`);
          //   }
          //
          //
          //   try {
          //     let resultArray = await databaseZone.query(condition);
          //     Logger.info('[testTag]', `Succeeded in querying data, result: ${JSON.stringify(resultArray)}`);
          //   } catch (err) {
          //     Logger.error('[testTag]', `Failed to query data, code: ${err.code}, message: ${err.message}`);
          //   }
          //
          // })

          // 侧边栏前 6 项
          if (this.sideBarMainIndex < 5) {
            // Text(this.appTmpData.continueText)
            //   .fontSize(30)
            //   .fontWeight(FontWeight.Bold)
            // Button().onClick(()=>{this.appTmpData.continueText+='小农思想'})
            List({ space: new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) }) {
              ForEach(this.showList, (item: ShowListModel, index: number) => {
                ListItem() {
                  Stack() {
                    // item 操作按钮，为了不与悬浮态效果冲突，改为 stack 视图，显示在最上层
                    if ((this.sideBarMainIndex === 0 && index !== 0) || (this.sideBarMainIndex > 0)) {
                      Button() {
                        SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
                          .fontSize(24)
                          .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                      }
                      .width(40)
                      .height(40)
                      .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
                      .zIndex(1)
                      .position({ top: 20, right: 12 })
                      .bindMenu(this.MenuView(item.id, index))
                      .onClick(() => {
                        // 开启按钮触感反馈
                        if (this.appGeneralData.isHapticButton) {
                          StartVibrator()
                        }
                      })
                    }
                    // item 视图
                    Row() {
                      Row() {
                        Column() {
                          if (this.sideBarMainIndex === 0 && index === 0) {
                            SymbolGlyph($r('sys.symbol.plus'))
                              .fontSize(24)
                          }
                        }
                        .width(48)
                        .height('100%')
                        .justifyContent(FlexAlign.Center)
                        .backgroundColor($r('sys.color.comp_background_tertiary'))
                        .backgroundImage(this.sideBarMainIndex === 0 && index === 0 ? '' :
                          $r('app.media.surveyBackground'))
                        .borderRadius({
                          topLeft: 2,
                          bottomLeft: 2,
                          topRight: 8,
                          bottomRight: 8
                        })
                        .margin({ right: 16 })

                        // 添加问卷 item
                        if (this.sideBarMainIndex === 0 && index === 0) {
                          // Text('添加问卷')
                          Text($r('app.string.create_survey'))
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                        }
                        // 展示问卷 item
                        else {
                          Column({ space: 12 }) {
                            Text(item.label)
                              .fontSize(16)
                              .fontWeight(FontWeight.Medium)
                              .maxLines(2)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(new Date(parseInt(item.deltaT)).toLocaleDateString())
                              .fontSize(14)
                              .fontColor(Color.Gray)
                              .margin({ bottom: 6 })
                          }
                          .layoutWeight(1)
                          .height('100%')
                          .justifyContent(FlexAlign.End)
                          .alignItems(HorizontalAlign.Start)
                          .margin({ right: 40 })
                        }
                      }
                      .width('100%')
                      .height(80)
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
                      .padding({
                        top: 8,
                        bottom: 8,
                        left: 16,
                        right: 16
                      })
                    }
                    .bindMenu(this.sideBarMainIndex === 0 && index === 0 ? this.createMenu : () => {
                    })
                    .backgroundColor(this.appAppearanceData.isComponentBlur ? '' :
                      $r('app.color.list_card_bg_color'))
                    .backgroundFilter(this.appAppearanceData.isComponentBlur ?
                      uiEffect.createFilter().blur(this.appAppearanceData.componentBlur) :
                      uiEffect.createFilter().blur(BlurStyle.NONE))
                    .borderRadius(12)
                    .padding({
                      top: 4,
                      bottom: 4,
                      left: 6,
                      right: 6
                    })
                    .onClick(() => {
                      // 开启列表项震动
                      if (this.appGeneralData.isHapticListItem) {
                        StartVibrator()
                      }
                      this.sideBarMainIndex === 0 && index === 0 ? () => {
                      } :
                        this.pageInfos.pushPath({
                          name: 'CheckSurveyView',
                          param: item.id
                        })
                    })
                  }
                  .clickEffect({ level: ClickEffectLevel.LIGHT })
                }
              }, (item: ShowListModel, index: number) => JSON.stringify(item) + index)
            }
            .width('100%')
            .layoutWeight(1)
            .listDirection(Axis.Vertical)
            .lanes(new WidthBreakpointType(1, 2, 2).getValue(this.windowUtil.mainWindowInfo.widthBp), 32)
            .contentEndOffset(24)
            .padding({
              left: this.isShowSidebar ?
                new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) :
                new WidthBreakpointType(16, 16, 32 + 140).getValue(this.windowUtil.mainWindowInfo.widthBp),
              right: this.isShowSidebar ?
                new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) :
                new WidthBreakpointType(16, 16, 32 + 140).getValue(this.windowUtil.mainWindowInfo.widthBp)
            })
            .animation({ duration: 500, curve: Curve.Friction })
          }
          // 侧边栏第 6 项 —— 问卷模板
          else {
            // 当前无网络
            if (!this.appTmpData.isNetwork) {
              Column() {
                Text('当前无网络，请先连接网络')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .margin({
                    bottom: new WidthBreakpointType(
                      this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24,
                      this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24,
                      this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 +
                        38).getValue(this.windowUtil.mainWindowInfo.widthBp)
                  })
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            }
            // 当前有网络
            else {
              Stack({ alignContent: Alignment.Top }) {
                Column() {
                  // ChipGroup({
                  //   items: this.targetChipGroup,
                  //   itemStyle: {
                  //     selectedBackgroundColor: $r('app.color.list_on_color'),
                  //   },
                  //   selectedIndexes: this.chipGroupSelectedIndex,
                  //   onChange: (selectedIndex: number[]) => {
                  //     this.chipGroupSelectedIndex = selectedIndex;
                  //   }
                  // })
                  //   .margin({
                  //     left: this.isShowSidebar ?
                  //       new WidthBreakpointType(0, 4, 0).getValue(this.windowUtil.mainWindowInfo.widthBp) :
                  //       new WidthBreakpointType(0, 4, 140).getValue(this.windowUtil.mainWindowInfo.widthBp),
                  //     right: this.isShowSidebar ?
                  //       new WidthBreakpointType(0, 4, 0).getValue(this.windowUtil.mainWindowInfo.widthBp) :
                  //       new WidthBreakpointType(0, 4, 140).getValue(this.windowUtil.mainWindowInfo.widthBp)
                  //   })
                  //   .animation({ duration: 500, curve: Curve.Friction })
                  //   .backgroundColor(Color.Orange)

                  // 利用 list 代替 ChipGroup，但格式仿照 ChipGroup 格式，因为功能不全
                  List({ space: 8, scroller: this.chipScroller }) {
                    ForEach(this.targetChipGroup, (item: ChipGroupItemOptions, index: number) => {
                      ListItem() {
                        Button() {
                          Text(item.label.text)
                            .width('auto')
                            .textAlign(TextAlign.Center)
                            .fontSize(14)
                        }
                        .height('100%')
                        .backgroundColor(this.chipGroupSelectedIndex[0] === index ?
                          $r('app.color.list_on_color') :
                          $r('sys.color.ohos_id_color_button_normal'))
                        .padding({ left: 16, right: 16 })
                        .onClick(() => {
                          // 开启列表项震动
                          if (this.appGeneralData.isHapticListItem) {
                            StartVibrator()
                          }
                          this.chipGroupSelectedIndex[0] = index;
                          this.getUIContext().animateTo({
                            duration: 300,
                            curve: Curve.Linear
                          }, () => {
                            this.chipScroller.scrollToIndex(index);
                          })
                        })
                      }
                      .padding({
                        top: 14,
                        bottom: 14
                      })
                    })
                  }
                  .width('100%')
                  .height(64)
                  .listDirection(Axis.Horizontal)
                  .scrollBar(BarState.Off)
                  .edgeEffect(EdgeEffect.Spring)
                  .contentStartOffset(this.isShowSidebar ?
                    new WidthBreakpointType(16, 4, 16).getValue(this.windowUtil.mainWindowInfo.widthBp) :
                    new WidthBreakpointType(16, 4, 156).getValue(this.windowUtil.mainWindowInfo.widthBp)
                  )
                  .contentEndOffset(this.isShowSidebar ?
                    new WidthBreakpointType(16, 4, 16).getValue(this.windowUtil.mainWindowInfo.widthBp) :
                    new WidthBreakpointType(16, 4, 156).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .animation({ duration: 500, curve: Curve.Friction })


                  // Refresh({ refreshing: this.isLoading!! }) {
                  if (this.chipGroupSelectedIndex[0] === 0) {
                    this.marketList('template_product & ux', $r('app.media.template_productUxImg'));
                  }
                  if (this.chipGroupSelectedIndex[0] === 1) {
                    this.marketList('template_personal_life', $r('app.media.personalImg'))
                  }
                  if (this.chipGroupSelectedIndex[0] === 2) {
                    this.marketList('template_college', $r('app.media.collegeImg'));
                  }
                  if (this.chipGroupSelectedIndex[0] === 3) {
                    this.marketList('template_adolescent_mental_health', $r('app.media.adolescentImg'))
                  }
                  // }
                  // .width('100%')
                  // .layoutWeight(1)
                  // .onRefreshing(() => {
                  //   setTimeout(() => {
                  //     if (this.appTmpData.isNetwork) {
                  //       this.initMarket();
                  //     }
                  //   }, 2000)
                  //   console.info('onRefreshing test');
                  // })
                }
                .width('100%')
                .layoutWeight(1)

                if (this.isFirstLoading) {
                  Column({ space: 6 }) {
                    LoadingProgress()
                      .size({ width: 48, height: 48 })
                      .color($r('app.color.list_on_color'))
                    Text($r('app.string.is_loading_text'))
                  }
                }
              }
            }
          }

        }
        .width('100%')
      }
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .foregroundFilter(this.isBackgroundBlur())
    .scale(this.isBackgroundScale())
    .animation({ duration: 300, curve: Curve.Linear })
    .gesture(
      PanGesture(this.panOptionRight)
        .onActionEnd((event: GestureEvent) => {
          // 开启滑动触感反馈
          if (this.appGeneralData.isHapticSwipe) {
            StartVibrator()
          }
          this.isShowSidebar = true;
          Logger.info('[ContentView.PanGesture]', 'Pan end');
        })
    )
    .gesture(
      PanGesture(this.panOptionLeft)
        .onActionEnd((event: GestureEvent) => {
          // 开启滑动触感反馈
          if (this.appGeneralData.isHapticSwipe) {
            StartVibrator()
          }
          this.isToolViewShow = true;
          Logger.info('[ContentView.PanGesture]', 'Pan end');
        })
    )
    .gesture(
      TapGesture({ count: 3 })
        .onAction((event: GestureEvent) => {
          if (event) {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            // 定义扫码参数options
            let options: scanBarcode.ScanOptions = {
              scanTypes: [scanCore.ScanType.ALL],
              enableMultiMode: true,
              enableAlbum: true
            };
            try {
              // 可调用getHostContext接口获取当前页面关联的Context
              scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options)
                .then((result: scanBarcode.ScanResult) => {
                  this.pageInfos.pushPath({ name: 'WriteSurveyView', param: result.originalValue });
                  // 解析码值结果跳转应用服务页
                  Logger.info('[Scan CPSample]',
                    `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result.originalValue)}`);
                })
                .catch((error: BusinessError) => {
                  Logger.error('[Scan CPSample]',
                    `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
                });
            } catch (error) {
              Logger.error('[Scan CPSample]',
                `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
            }
          }
        })
    )
    .gesture(
      TapGesture({ count: 2 })
        .onAction((event: GestureEvent) => {
          if (event) {
            // 开启按钮触感反馈
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            this.pageInfos.pushPath({ name: 'SearchView' });
          }
        })
    )
    .bindSheet(this.isToolViewShow!!, DotSheetBindBuilder(), {
      showClose: false,
      // width: new WidthBreakpointType('100%', '460vp', '460vp').getValue(this.windowUtil.mainWindowInfo.widthBp),
      detents: this.windowUtil.mainWindowInfo.widthBp === WidthBreakpoint.WIDTH_SM ? ['900'] : ['90%'],
      height: '90%',
      preferType: SheetType.CENTER,
      onWillDismiss: (dismissSheetAction: DismissSheetAction) => {
        // 三键，手势，esc返回
        if (dismissSheetAction.reason === DismissReason.PRESS_BACK) {
          dismissSheetAction.dismiss();
          this.isToolViewShow = false;
        }
        // 关闭按钮返回
        if (dismissSheetAction.reason === DismissReason.CLOSE_BUTTON) {
          dismissSheetAction.dismiss();
          this.isToolViewShow = false;
        }
      }
    })
  }

  // 从云数据库获取模板数据
  private async initMarket() {
    // 初始化存储区
    let databaseZone = cloudDatabase.zone('guanlanwenjuan');
    // 初始化查询
    let marketCloud = new cloudDatabase.DatabaseQuery(MarketCloud).orderByDesc('id');
    let surveyTemplate = new cloudDatabase.DatabaseQuery(SurveyTemplate);
    this.isFirstLoading = true;

    // 进行查询并赋值
    try {
      this.marketCategories = await databaseZone.query(marketCloud);
      this.surveyTemplate = await databaseZone.query(surveyTemplate);
      // promptAction.openToast({ message: JSON.stringify(this.marketCategories), duration: 50000 })
      this.allChipGroup = [];
      for (let i = 0; i < this.marketCategories.length; i++) {
        const market = this.marketCategories[i];
        this.allChipGroup.push({ label: { text: market.name } });
      }
      this.targetChipGroup = [];
      this.allChipGroup.map((chip: ChipGroupItemOptions) => {
        const textJSON: string[] = JSON.parse(chip.label.text) as string[];
        const label: string = textJSON[this.appGeneralData.language === 'en-Latn-US'?1:0];
        this.targetChipGroup.push({ label: { text: label } })
      })
      this.isFirstLoading = false;
      // Logger.error('[ChipGroup]', JSON.stringify(this.allChipGroup))
      this.isLoading = false;
      Logger.info('[ContentView.aboutAppear]',
        `Succeeded in querying data, result: ${JSON.stringify(this.marketCategories)}`);
    } catch (err) {
      Logger.error('[ContentView.aboutAppear]', `Failed to query data, code: ${err.code}, message: ${err.message}`);
    }

  }

  private isBackgroundScale(): ScaleOptions {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      if (this.isShowSidebar) {
        return { x: 0.98, y: 0.98 };
      }
    }
    return { x: 1, y: 1 };
  }

  private isBackgroundBlur(): uiEffect.Filter {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      if (this.isShowSidebar) {
        return uiEffect.createFilter().blur(15);
      }
    }
    return uiEffect.createFilter().blur(BlurStyle.NONE);
  }
}

@Builder
export function ContentPanelBuilder() {
  ContentView();
}