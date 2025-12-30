import { AppStorageV2, PersistenceV2, promptAction, window } from '@kit.ArkUI'
import {
  access,
  AccountCloud,
  AppAppearanceViewModel,
  AppGeneralViewModel,
  AppTmpViewModel,
  AppViewModel,
  createFile,
  DistributedDB,
  ExitWithHuaweiButton,
  FormInfo,
  LoginWithHuaweiButton,
  mkdir,
  OffGripDetection,
  OnGripDetection,
  readFile,
  readWriteFile,
  StartVibrator,
  Survey,
  SurveyStatus,
  unlink,
  WidthBreakpointType,
  WindowUtil
} from 'common';
import { HdsSideBar } from '@hms.hds.HdsSideBar';
import { sideBarPanelBuilder } from '../views/SideBarView';
import { ContentPanelBuilder } from '../views/ContentView';
import { hdsEffect, HdsNavigation, HdsNavigationAttribute } from '@hms.hds.hdsBaseComponent';
import { abilityAccessCtrl, application, common, ConfigurationConstant } from '@kit.AbilityKit';
import { ShowListModel } from '../model/ShowListModel';
import { ShowListViewModel } from '../viewmodel/ShowListViewModel';
import { SideBarListModel } from '../model/SideBarListModel';
import { SideBarListViewModel } from '../viewmodel/SideBarListViewModel';
import { connection } from '@kit.NetworkKit';
import { BusinessError, commonEventManager } from "@kit.BasicServicesKit"
import { i18n } from '@kit.LocalizationKit';
import { uiEffect } from '@kit.ArkGraphics2D';
import { motion } from '@kit.MultimodalAwarenessKit';
import { PreviewView } from 'setting';
import { fileUri } from '@kit.CoreFileKit';
import { cloudDatabase } from '@kit.CloudFoundationKit';
import Logger from 'common/src/main/ets/utils/Logger';

// 创建窗口实例
let windowStage: window.WindowStage;

// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});

@Entry
@ComponentV2
struct Index {
  private static netConnection: connection.NetConnection | undefined = undefined;
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  @Local appTmpData: AppTmpViewModel =
    AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（父）
  @Provider('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 侧边栏
  @BuilderParam sideBarBuilder: () => void = sideBarPanelBuilder;
  // 内容区
  @BuilderParam contentBuilder: () => void = ContentPanelBuilder;
  // 是否显示侧边栏按钮，默认位 false
  @Provider('isShowSideBar') isShowSidebar: boolean = false;
  // 用于监听侧边栏当前所选item对应的索引值
  @Provider('sideBarMainIndex') sideBarMainIndex: number = 0;
  // 创建侧边栏列表数据实例
  private mainVM: SideBarListModel[] = new SideBarListViewModel().mainVM;
  @Provider('sideBarMainList') sideBarMainList: SideBarListModel[] = [...this.mainVM];
  // 创建主视图列表数据实例
  private showListVM: ShowListModel[] = new ShowListViewModel().mainVM;
  @Provider('showList') showList: ShowListModel[] = [...this.showListVM];
  @Provider('surveys') surveys: Survey[] = [];
  private distributedDB: DistributedDB =
    new DistributedDB(this.context);
  // 用于监听是否刷新显示全部问卷列表
  @Provider('refresh') refresh: boolean = false;
  @Local formInfo: FormInfo = AppStorageV2.connect(FormInfo, () => new FormInfo())!;

  async aboutToAppear(): Promise<void> {
    // 判断侧边栏是否显示
    this.getIsSideBar();
    await this.distributedDB.setDistributedTables(this.context)
    this.surveys = await this.distributedDB.getAllSurveys();
    // 刷新侧边栏主列表
    this.getSBMainItem();
    // 刷新侧边栏主列表item的数量
    this.getSBMainItemNum();
    // 查看账号资源文件夹是否存在，若不存在新建文件夹
    access(`${this.context.filesDir}/avatarDir`, (isExist: boolean) => {
      if (!isExist) {
        mkdir(this.context.filesDir, 'avatarDir');
      }
    });
    access(`${this.context.filesDir}/staticWallpaperDir`, (isExist: boolean) => {
      if (!isExist) {
        mkdir(this.context.filesDir, 'staticWallpaperDir');
      }
    });
  }

  aboutToDisappear(): void {
    // 关闭智感握持
    OffGripDetection();
    // 取消监听
    Index.netConnection?.unregister(() => {
      console.error('connection unregister success');
    });
  }

  onBackPress(): boolean | void {
    if (!this.appTmpData.isSystemShare) {
      if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
        if (this.isShowSidebar) {
          this.isShowSidebar = false;
          return true;
        } else {
          return false;
        }
      }
    } else {
      this.appTmpData.isSystemShare = false;
      return true;
    }
  }


  onPageShow(): void {

    // 是否进行应用接续
    if (this.appTmpData.isContinue) {
      // promptAction.openToast({message:`isContinue: ${this.appTmpData.isContinue}, index: ${this.appTmpData.continueSideBarIndex}`})
      if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
        this.isShowSidebar = false;
      }
      this.isToolViewShow = false;
      if (this.appTmpData.continueSideBarIndex) {
        setTimeout(() => {
          this.sideBarMainIndex = this.appTmpData.continueSideBarIndex;
        }, 50)
      }
      if (this.appTmpData.marketSurveyId) {
        setTimeout(() => {
          this.pageInfos.pushPath({ name: 'MarketSurveyView', param: this.appTmpData.marketSurveyId });
        }, 50)
      }
      if (this.appTmpData.checkSurveyId) {
        setTimeout(() => {
          this.pageInfos.pushPath({ name: 'CheckSurveyView', param: this.appTmpData.checkSurveyId });
        }, 50)
      }
    }

    // 初始化网络信息，设置监听并判断是否有网
    if (Index.netConnection === undefined) {
      this.initNetwork();
    }
    // 判断是否开启智感握持
    if (this.appAppearanceData.isSmartGripDetection) {
      OnGripDetection((data: motion.HoldingHandStatus) => {
        this.appTmpData.holdingHandStatus = data;
      });
    }
    // 设置语言模式
    if (this.appGeneralData.languageId === 0) {
      application.getApplicationContext().setLanguage(i18n.System.getSystemLanguage());
    } else if (this.appGeneralData.languageId === 1) {
      application.getApplicationContext().setLanguage('zh-Hans');
    } else {
      application.getApplicationContext().setLanguage('en-Latn-US');
    }
    // 设置颜色模式
    if (this.appGeneralData.colorModeId === 0) {
      application.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } else if (this.appGeneralData.colorModeId === 1) {
      application.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } else {
      application.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    }

    if (this.formInfo.targetPage.trim().length !== 0) {
      // promptAction.openToast({ message: JSON.stringify(this.formInfo.targetPage) })
      if (this.formInfo.targetPage === 'CreateSurveyView') {
        this.sideBarMainIndex = 0;
      }
      // 先清空栈，防止堆栈
      this.pageInfos.pop();
      // 入栈目标页面
      this.pageInfos.pushPath({ name: this.formInfo.targetPage })
      // 将卡片数据清空
      this.formInfo.targetPage = '';
    }
    if (this.formInfo.targetSideBarMainIndex != -1) {
      // 缓存变量
      let sidebarIndex: number = parseInt(this.formInfo.targetSideBarMainIndex.toString());
      // 增加一个定时器，让@Monitor能够监听到侧边栏索引值的变化，
      // 但是不能直接在定时器中将formInfo信息直接放到sideBarMainIndex，增加一个缓存变量进行传递
      setTimeout(() => {
        this.sideBarMainIndex = sidebarIndex;
      }, 50)
      this.formInfo.targetSideBarMainIndex = -1;
    }
  }

  onPageHide(): void {
    // 关闭智感握持
    OffGripDetection();
  }

  // 监听是否进行系统分享
  @Monitor('appTmpData.isSystemShare')
  systemShareChange() {
    if (this.appTmpData.isSystemShare) {
      this.isShowSidebar = false;
      this.isToolViewShow = false;
      this.pageInfos.pop();
    }
  }

  // 实时监听是否刷新全部问卷列表
  @Monitor('refresh')
  async refreshChange() {
    if (this.refresh) {
      // 刷新所有问卷信息
      this.surveys = await this.distributedDB.getAllSurveys();
      // 刷新侧边栏主列表
      this.getSBMainItem();
      // 刷新侧边栏主列表 item 的数量
      this.getSBMainItemNum();
      // 刷新完毕
      this.refresh = false;
    }
  }

  // 实时监听侧边栏 item 索引值，刷新显示列表
  @Monitor('sideBarMainIndex')
  sideBarMainIndexChange() {
    this.appTmpData.continueSideBarIndex = this.sideBarMainIndex
    // 刷新侧边栏主列表
    this.getSBMainItem();
  }

  // 用于监听是否显示设置半模态（父）
  @Provider('isToolViewShow') isToolViewShow: boolean = false;
  @Local selectedSystemShare: number = -1;

  build() {
    HdsNavigation(this.pageInfos) {
      // 如果完成引导，显示主页
      if (this.appBasicData.isStart) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.appAppearanceData.staticWallpaper) {
            Image(this.appAppearanceData.staticWallpaper)
          }
          // 侧边栏按钮
          Button() {
            SymbolGlyph(this.isShowSidebar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
              .hitTestBehavior(HitTestMode.None)
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .size({ width: 40, height: 40 })
          .visibility(this.appAppearanceData.isSideBarButtonShow ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            // 开启按钮触感
            if (this.appGeneralData.isHapticButton) {
              StartVibrator()
            }
            // 修改按钮状态
            this.isShowSidebar = !this.isShowSidebar;
          })
          .animation({ duration: 250, curve: Curve.Linear })
          .zIndex(1)
          .position({ top: 0, left: 0 })
          .margin({
            top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 8,
            left: 16
          })


          // 侧边栏容器
          HdsSideBar({
            contentAreaMask: true,
            isShowSideBar: this.isShowSidebar,
            $isShowSideBar: (isShowSideBar: boolean) => {
              this.isShowSidebar = !isShowSideBar;
            },
            minSideBarWidth: 280,
            sideBarPanelBuilder: (): void => this.sideBarBuilder(),
            contentPanelBuilder: (): void => this.contentBuilder(),
            sideBarContainerType: this.getSideBarType(),
            onChange: (isShowSideBar: boolean) => {
              // 开启滑动触感反馈
              if (this.appGeneralData.isHapticSwipe) {
                StartVibrator()
              }
              this.isShowSidebar = isShowSideBar;
            }
          }).enabled(this.appTmpData.isSystemShare ? false : true)

          // 接收系统分享
          if (this.appTmpData.isSystemShare) {
            Column() {
              Text($r('app.string.system_share_is_static_wallpaper_text'))
                .fontSize(20)
                .fontWeight(FontWeight.Bolder)
              PreviewView({ isComponent: false, componentBlur: 0, isSystemShare: true })

              Row({ space: 12 }) {
                ForEach([$r('app.string.button_cancel_text'), $r('app.string.button_confirm_text')],
                  (item: Resource, index: number) => {
                    Button() {
                      Text(item)
                        .fontSize(16)
                        .fontWeight(FontWeight.Regular)
                        .fontColor(index === 0 ? Color.Red : Color.White)
                    }
                    .backgroundColor(index === 0 ? $r('sys.color.ohos_id_color_button_normal') :
                      $r('app.color.list_on_color'))
                    .padding({
                      top: 8,
                      bottom: 8,
                      left: 36,
                      right: 36
                    })
                    .onClick(() => {
                      this.appTmpData.isSystemShare = false;
                      this.selectedSystemShare = index;
                      if (this.selectedSystemShare === 1) {
                        // 创建壁纸文件名称
                        let filName: string =
                          'staticWallpaperDir/wallpaper-' + this.appAppearanceData.staticWallpaperId.toString();
                        // 保存壁纸
                        readWriteFile(this.context, filName, this.appTmpData.systemShareImgUri, (dstPath: string) => {
                          this.appAppearanceData.staticWallpaper = fileUri.getUriFromPath(dstPath);
                        })
                        let unlinkId: number = this.appAppearanceData.staticWallpaperId - 1;
                        let unLinkPath: string = `${this.context.filesDir}/staticWallpaperDir/wallpaper-${unlinkId}`
                        unlink(unLinkPath);
                        this.appAppearanceData.staticWallpaperId = this.appAppearanceData.staticWallpaperId + 1;
                      }
                    })
                  })
              }
              .padding({ left: 16, right: 16 })
              .margin({ top: 16 })
            }
            .padding({
              top: 24,
              bottom: 36,
              left: 16,
              right: 16
            })
            .backgroundColor(this.appAppearanceData.staticWallpaper === '' ? $r('app.color.list_card_bg_color') : '')
            .backgroundBlurStyle(this.appAppearanceData.staticWallpaper === '' ? BlurStyle.NONE :
              BlurStyle.BACKGROUND_THIN)
            .borderRadius(15)
          }
        }
        .backgroundColor($r('sys.color.background_secondary'))
        .backgroundFilter(uiEffect.createFilter().blur(15))
        .scale(this.isBackgroundScale())
        .animation({ duration: 300, curve: Curve.Linear })
      }
      // 如果未处于刚下载使用，显示登录页面
      if (!this.appBasicData.isStart) {
        Stack({ alignContent: Alignment.TopStart }) {
        }
        .bindSheet(!this.appBasicData.isStart!!, LoginBuilder(), {
          showClose: false,
          // width: new WidthBreakpointType('100%', '460vp', '460vp').getValue(this.windowUtil.mainWindowInfo.widthBp),
          // detents: this.windowUtil.mainWindowInfo.widthBp === WidthBreakpoint.WIDTH_SM ? ['900'] : ['90%'],
          // height: '90%',
          preferType: SheetType.CENTER,
          onWillDismiss: (dismissSheetAction: DismissSheetAction) => {
            // 三键，手势，esc返回
            if (dismissSheetAction.reason === DismissReason.PRESS_BACK) {
              // dismissSheetAction.dismiss();
              this.context.terminateSelf();
            }
            // 关闭按钮返回
            if (dismissSheetAction.reason === DismissReason.CLOSE_BUTTON) {
              // dismissSheetAction.dismiss();
              this.context.terminateSelf();
            }
          }
        })
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .foregroundFilter(this.isBackgroundBlur())
    .animation({ duration: 300, curve: Curve.Linear })
  }

  // 是否开启背景缩小
  private isBackgroundScale(): ScaleOptions {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      if (this.isShowSidebar || this.isToolViewShow || this.appTmpData.isSystemShare) {
        return { x: 0.98, y: 0.98 };
      }
    } else if (this.windowUtil.mainWindowInfo.widthBp >= WidthBreakpoint.WIDTH_LG) {
      if (this.isToolViewShow || this.appTmpData.isSystemShare) {
        return { x: 0.98, y: 0.98 };
      }
    }
    return { x: 1, y: 1 };
  }

  // 是否开启背景模糊
  private isBackgroundBlur(): uiEffect.Filter {
    if (this.isToolViewShow) {
      return uiEffect.createFilter().blur(15);
    }
    return uiEffect.createFilter().blur(0)
  }

  // 一系列网络监听事件
  private initNetwork() {
    // 创建 NetConnection 对象
    Index.netConnection = connection.createNetConnection();
    // 注册监听
    Index.netConnection.register(() => {
      console.error('connection register success');
    });

    // 监听网络是否可用
    Index.netConnection!.on('netAvailable', (data) => {
      console.error('NetJudge netAvailable');
      this.appTmpData.isNetwork = this.judgeHasNet();
    });

    // 监听网络是否关闭
    Index.netConnection.on('netUnavailable', () => {
      console.error('NetJudge netUnavailable ');
      this.appTmpData.isNetwork = this.judgeHasNet();
    });

    // 监听网络变化
    Index.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
      console.error('NetJudge netCapabilitiesChange ');
      this.appTmpData.isNetwork = this.judgeHasNet();
    });

    // 监听网络变化
    Index.netConnection.on('netConnectionPropertiesChange', (data: connection.NetConnectionPropertyInfo) => {
      this.appTmpData.isNetwork = this.judgeHasNet();
    });

    // 监听网络丢失
    Index.netConnection.on('netLost', () => {
      this.appTmpData.isNetwork = this.judgeHasNet();
    });

  }

  // 获取网络是否开启，返回布尔值
  judgeHasNet(): boolean {
    try { // Get current network connection
      let netHandle = connection.getDefaultNetSync();

      // 0-100 Reserved connections for the system
      if (!netHandle || netHandle.netId < 100) {
        return false;
      }

      // Get the properties of the connection
      let netCapability = connection.getNetCapabilitiesSync(netHandle);
      let cap = netCapability.networkCap;
      if (!cap) {
        return false;
      }

      for (let em of cap) {
        if (connection.NetCap.NET_CAPABILITY_VALIDATED === em) {
          return true;
        }
      }
    } catch (e) {
      // let err = e as BusinessError;
      console.info('get netInfo error ：' + JSON.stringify(e));
    }
    return false;
  }

  // 判断侧边栏是否显示
  private getIsSideBar(): void {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      this.isShowSidebar = false;
    } else {
      this.isShowSidebar = true;
    }
  }

  // 获得侧边栏与内容区的显示关系
  private getSideBarType(): SideBarContainerType {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      return SideBarContainerType.Overlay;
    }
    return SideBarContainerType.Embed;
  }

  // 刷新侧边栏对应的显示列表
  private getSBMainItem(): void {
    this.showList = [];
    if (this.sideBarMainIndex === 0) {
      this.showList = [...this.showListVM];
      this.surveys.forEach((survey: Survey) => {
        if (!survey.deleted) {
          this.showList.push(new ShowListModel(survey.id!, survey.title, survey.createdTime.toString()));
        }
      })
    }
    if (this.sideBarMainIndex === 1) {
      this.surveys.forEach((survey: Survey) => {
        if (!survey.deleted && survey.status === SurveyStatus.COLLECTING) {
          this.showList.push(new ShowListModel(survey.id!, survey.title, survey.createdTime.toString()));
        }
      })
    }
    if (this.sideBarMainIndex === 2) {
      this.surveys.forEach((survey: Survey) => {
        if (!survey.deleted && survey.status === SurveyStatus.CLOSED) {
          this.showList.push(new ShowListModel(survey.id!, survey.title, survey.createdTime.toString()));
        }
      })
    }
    if (this.sideBarMainIndex === 3) {
      this.surveys.forEach((survey: Survey) => {
        if (!survey.deleted && survey.status === SurveyStatus.DRAFT) {
          this.showList.push(new ShowListModel(survey.id!, survey.title, survey.createdTime.toString()));
        }
      })
    }
    if (this.sideBarMainIndex === 4) {
      this.surveys.forEach((survey: Survey) => {
        if (survey.deleted) {
          this.showList.push(new ShowListModel(survey.id!, survey.title, survey.createdTime.toString()));
        }
      })
    }
  }

  // 刷新侧边栏主列表 item 的数量
  private getSBMainItemNum(): void {
    for (let i = 0; i < 5; i++) {
      const list: SideBarListModel = this.sideBarMainList[i];
      let count: number = 0;
      // 全部问卷
      if (i === 0) {
        this.surveys.map((survey: Survey) => {
          if (!survey.deleted) {
            count = count + 1;
          }
        })
        list.count = count;
      }
      // 正在收集
      if (i === 1) {
        this.surveys.map((survey: Survey) => {
          if (!survey.deleted && survey.status === SurveyStatus.COLLECTING) {
            count = count + 1;
          }
        })
        list.count = count;
      }
      // 收集完成
      if (i === 2) {
        this.surveys.map((survey: Survey) => {
          if (!survey.deleted && survey.status === SurveyStatus.CLOSED) {
            count = count + 1;
          }
        })
        list.count = count;
      }
      // 未收集
      if (i === 3) {
        this.surveys.map((survey: Survey) => {
          if (!survey.deleted && survey.status === SurveyStatus.DRAFT) {
            count = count + 1;
          }
        })
        list.count = count;
      }
      // 废纸篓
      if (i === 4) {
        this.surveys.map((survey: Survey) => {
          if (survey.deleted) {
            count = count + 1;
          }
        })
        list.count = count;
      }
      this.sideBarMainList.splice(i, 1, list);
    }
  }
}

@ComponentV2
export struct LoginView {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（父）
  @Provider('loginInfo') loginInfos: NavPathStack = new NavPathStack();
  @Local swiperIndex: number = 0;
  // private operationBox: string[] = ['取消', '同意'];
  private operationBox: Resource[] =
    [$r('app.string.app_statement_operation_text_cancel'), $r('app.string.app_statement_operation_text_agree')];
  // 创建滑块控制器
  private swiperController: SwiperController = new SwiperController();
  @Local swiperBox: string[] = ['', ''];

  aboutToAppear(): void {
    if (this.appBasicData.isAgree) {
      this.swiperBox = ['', '', ''];
    }
  }

  build() {
    HdsNavigation(this.loginInfos) {
      Swiper(this.swiperController) {
        ForEach(this.swiperBox, (item: string, index: number) => {
          Stack() {
            Row() {
              if (this.appBasicData.isAgree && index !== 0) {
                Button() {
                  SymbolGlyph($r('sys.symbol.chevron_left'))
                    .fontSize(24)
                    .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                }
                .width(40)
                .height(40)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .onClick(() => {
                  this.swiperController.showPrevious();
                })
              }

              Blank()
              if (this.appBasicData.isAgree && index < this.swiperBox.length - 1) {
                Button() {
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(24)
                    .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                }
                .width(40)
                .height(40)
                .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                .onClick(() => {
                  this.swiperController.showNext();
                })
              }

            }
            .width('100%')
            .zIndex(1)

            // 引导页面 —— 1
            if (index === 0) {
              Column() {
                // 顶部填充区域
                Blank()
                  .height(new WidthBreakpointType(120, 72, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                // 应用图标
                Image($r('app.media.startIcon'))
                  .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .borderRadius(12)
                // 应用名称
                Text($r('app.string.app_name'))
                  .fontSize(26)
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 24 })
                // 应用主题
                Text($r('app.string.app_slogan'))
                  .fontSize(new WidthBreakpointType(14, 14, 16).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.Gray)
                  .margin({ top: 16 })
                Blank()
                Row() {
                  SymbolGlyph($r('sys.symbol.security_shield'))
                    .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
                    .fontColor([$r('sys.color.font'), $r('app.color.list_on_color')])
                    .fontSize(24)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)

                Text() {
                  // Span('本应用提供问卷创建、分发和统计等服务，本应用需用户联网、登录华为账号等功能以便为您提供更好的服务。我们将遵守')
                  Span($r('app.string.app_statement_part_1'))
                  // Span('隐私声明')
                  Span($r('app.string.app_statement_part_2'))
                    .fontColor($r('app.color.list_on_color')).onClick(() => {
                    this.loginInfos.pushPath({ name: 'AgreementView', param: 0 })
                  })
                  Span($r('app.string.app_statement_part_3'))
                  Span($r('app.string.app_statement_part_4'))
                    .fontColor($r('app.color.list_on_color')).onClick(() => {
                    this.loginInfos.pushPath({ name: 'AgreementView', param: 1 })
                  })
                  Span($r('app.string.app_statement_part_5'))
                }
                .fontSize(10)
                .fontColor(Color.Gray)
                .margin({ top: 16, bottom: 24 })

                // 操作按钮
                Row({ space: 24 }) {
                  ForEach(this.operationBox, (item: string, index: number) => {
                    Button() {
                      Text(item)
                        .fontColor(index === 0 ? $r('app.color.list_on_color') : $r('sys.color.font_normal'))
                    }
                    .layoutWeight(1)
                    .height(40)
                    .backgroundColor(index === 0 ? $r('sys.color.ohos_id_color_button_normal') :
                      $r('app.color.list_on_color'))
                    .onClick(() => {
                      if (index === 0) {
                        this.context.terminateSelf();
                      } else {
                        this.swiperIndex = 1;
                        this.appBasicData.isAgree = true;
                        this.swiperBox.push('');
                        this.swiperController.showNext();
                      }
                    })
                  })
                }
              }
              .width('100%')
              .height('100%')
            }
            // 引导页面 —— 2
            else if (index === 1) {
              Column() {
                // 顶部填充区域
                Blank()
                  .height(new WidthBreakpointType(120, 72, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))

                // 登录状态
                if (this.appBasicData.isHuaweiID) {
                  Image(this.appBasicData.avatarUri)
                    .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                    .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                    .borderRadius(new WidthBreakpointType(32, 32, 36).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  // Text(`你好，${this.nickName}`)
                  Text() {
                    Span($r('app.string.app_greeting'))
                    Span(`${this.appBasicData.nickName}`)
                  }
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 24 })

                  Text(`WQIID:${this.appBasicData.WQIId}`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: 6 })
                }
                // 未登录状态
                else {
                  SymbolGlyph($r('sys.symbol.person_crop_circle_fill'))
                    .fontSize(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                    .fontColor([$r('app.color.list_on_color')])
                  // Text('请登录')
                  Text($r('app.string.app_log_in_prompt'))
                    .fontSize(26)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 24 })
                }

                Blank()

                // 登录状态
                if (this.appBasicData.isHuaweiID) {
                  ExitWithHuaweiButton({
                    callback: () => {
                      // 刷新华为账号状态
                      this.appBasicData.isHuaweiID = false;
                      this.appBasicData.nickName = '';
                      this.appBasicData.avatarUri = '';
                      this.appBasicData.WQIId = '';
                      this.appBasicData.openId = '';

                      unlink(this.context.filesDir + '/avatarDir/nickName')
                      unlink(this.context.filesDir + '/avatarDir/avatarUri')
                    }
                  })
                }
                // 未登陆状态
                else {
                  LoginWithHuaweiButton({
                    callback: async (avatarUri: string, nickName: string, open_id: string) => {
                      // 刷新华为账号状态
                      this.appBasicData.isHuaweiID = true;
                      this.appBasicData.openId = open_id;

                      let databaseZone = cloudDatabase.zone('guanlanwenjuan');
                      const accountCondition = new cloudDatabase.DatabaseQuery(AccountCloud);
                      // 根据 openid 查询，获取 id
                      accountCondition.equalTo('open_id', this.appBasicData.openId);
                      let result = await databaseZone.query(accountCondition);
                      // promptAction.openToast({ message: JSON.stringify(result) })

                      // 是否成功访问到云数据库中的数据，进行昵称与头像的显示
                      let isShow:boolean = false;

                      // 未登录过的openID
                      if (result.length === 0) {
                        try {
                          let account = new AccountCloud();
                          account.id = 1;
                          account.open_id = this.appBasicData.openId;
                          let success = await databaseZone.upsert([account]);

                          if (success) {
                            let result = await databaseZone.query(accountCondition);
                            // promptAction.openToast({ message: JSON.stringify(result) })
                            isShow = true;
                            this.appBasicData.WQIId = result[0].id.toString().padStart(9, '0');
                          }
                          Logger.info('[AccountView]', `Succeeded in upserting feedbackData, result: ${success}`);
                        } catch (err) {
                          Logger.error('[AccountView]', `Failed to upsert data, code: ${err.code}, message: ${err.message}`);
                        }
                      }
                      // 登陆过的
                      else {
                        isShow = true;
                        this.appBasicData.WQIId = result[0].id.toString().padStart(9, '0');
                      }

                      if (isShow) {
                        // 保存昵称
                        createFile(this.context, '/avatarDir/nickName', nickName, (destPath: string) => {
                          readFile(`${this.context.filesDir}/avatarDir/nickName`, (buf: string) => {
                            this.appBasicData.nickName = buf;
                          })
                        })

                        // 保存头像
                        createFile(this.context, '/avatarDir/avatarUri', avatarUri, (destPath: string) => {
                          readFile(`${this.context.filesDir}/avatarDir/avatarUri`, (buf: string) => {
                            this.appBasicData.avatarUri = buf;
                          })
                        })
                      }
                    }
                  })
                }

              }
              .width('100%')
              .height('100%')
            }
            // 引导页面 —— 3
            else {
              Column() {
                // 顶部填充区域
                Blank()
                  .height(new WidthBreakpointType(120, 72, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))

                Image($r('app.media.startIcon'))
                  .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .borderRadius(12)

                // Text('欢迎使用')
                Text($r('app.string.app_welcome_prompt_part_1'))
                  .fontSize(24)
                  .margin({ top: 24 })

                // Text('一起聆听世界的声音')
                Text($r('app.string.app_welcome_prompt_part_2'))
                  .fontSize(new WidthBreakpointType(14, 14, 16).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.Gray)
                  .margin({ top: 16 })

                Blank()

                Button() {
                  // Text('点击进入')
                  Text($r('app.string.app_started_text'))
                }
                .width('50%')
                .height(40)
                .backgroundColor($r('app.color.list_on_color'))
                .onClick(() => {
                  this.appBasicData.isStart = true;

                  // setTimeout(() => {
                  //   if (this.appBasicData.isDistributedFirst) {
                  //     checkPermissionGrant('ohos.permission.DISTRIBUTED_DATASYNC',
                  //       (grantStatus: abilityAccessCtrl.GrantStatus) => {
                  //
                  //         if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
                  //           reqPermissionsFormUser(['ohos.permission.DISTRIBUTED_DATASYNC'], this.context,
                  //             (isDataSync: boolean) => {
                  //               this.appBasicData.isDistributeDataSync = isDataSync;
                  //             });
                  //           this.appBasicData.isDistributedFirst = false;
                  //         }
                  //       })
                  //   }
                  // }, 500)

                })
              }
              .width('100%')
              .height('100%')
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({
            top: 16,
            bottom: new WidthBreakpointType(48, 24, 16).getValue(this.windowUtil.mainWindowInfo.widthBp),
            left: 16,
            right: 16
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .loop(false)
      .indicator(false)
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }
}

@Builder
function LoginBuilder() {
  LoginView();
}