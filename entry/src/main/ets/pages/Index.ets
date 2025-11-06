import { AppStorageV2, PersistenceV2, promptAction, window } from '@kit.ArkUI'
import {
  access,
  AppViewModel,
  createFile,
  DistributedDB,
  ExitWithHuaweiButton,
  FormInfo,
  getListFile,
  LoginWithHuaweiButton,
  mkdir,
  readFile,
  readWriteFile,
  Survey,
  SurveyStatus,
  WidthBreakpointType,
  WindowUtil
} from 'common';
import { HdsSideBar } from '@hms.hds.HdsSideBar';
import { sideBarPanelBuilder } from '../view/SideBarView';
import { ContentPanelBuilder } from '../view/ContentView';
import { HdsNavigation, HdsNavigationAttribute } from '@hms.hds.hdsBaseComponent';
import { common } from '@kit.AbilityKit';
import { ShowListModel } from '../model/ShowListModel';
import { ShowListViewModel } from '../viewmodel/ShowListViewModel';
import { SideBarListModel } from '../model/SideBarListModel';
import { SideBarListViewModel } from '../viewmodel/SideBarListViewModel';
import { fileUri } from '@kit.CoreFileKit';

// 创建窗口实例
let windowStage: window.WindowStage;

// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});


@Entry
@ComponentV2
struct Index {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
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
  }

  onBackPress(): boolean | void {
    if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_LG) {
      if (this.isShowSidebar) {
        this.isShowSidebar = false;
        return true;
      } else {
        return false;
      }
    }
  }

  onPageShow(): void {
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
      this.sideBarMainIndex = parseInt(this.formInfo.targetSideBarMainIndex.toString());
      this.formInfo.targetSideBarMainIndex = -1;
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
    // 刷新侧边栏主列表
    this.getSBMainItem();
  }

  build() {
    HdsNavigation(this.pageInfos) {
      // 如果完成引导，显示主页
      if (this.appBasicData.isStart) {
        Stack({ alignContent: Alignment.TopStart }) {
          // 侧边栏按钮
          Button() {
            SymbolGlyph(this.isShowSidebar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
              .hitTestBehavior(HitTestMode.None)
          }
          .id('side_bar_button')
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .onClick(() => {
            this.isShowSidebar = !this.isShowSidebar;
          })
          .zIndex(1)
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
            sideBarColor: $r('sys.color.hds_sidebar_overlay'),
            sideBarPanelBuilder: (): void => this.sideBarBuilder(),
            contentPanelBuilder: (): void => this.contentBuilder(),
            sideBarContainerType: this.getSideBarType(),
            onChange: (isShowSideBar: boolean) => {
              this.isShowSidebar = isShowSideBar;
              // promptAction.openToast({ message: JSON.stringify(this.isShowSidebar) })
            }
          })
        }
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
              dismissSheetAction.dismiss();
            }
            // 关闭按钮返回
            if (dismissSheetAction.reason === DismissReason.CLOSE_BUTTON) {
              dismissSheetAction.dismiss();
            }
          }
        })
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  // 判断侧边栏是否显示
  private getIsSideBar(): void {
    if (this.getUIContext().getWindowWidthBreakpoint() < WidthBreakpoint.WIDTH_LG) {
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
  @Local operationBox: string[] = ['取消', '同意'];
  // 创建滑块控制器
  private swiperController: SwiperController = new SwiperController();
  @Local avatarUri: string = '';
  @Local nickName: string = '';
  @Local swiperBox: string[] = ['', ''];

  aboutToAppear(): void {
    this.avatarUri = this.appBasicData.avatarUri;
    this.nickName = this.appBasicData.nickName;
    if (this.appBasicData.isHuaweiID) {
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

            if (index === 0) {
              Column() {
                // 顶部填充区域
                Blank()
                  .height(new WidthBreakpointType(120, 72, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                Image($r('app.media.startIcon'))
                  .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .borderRadius(12)
                Text('观澜问卷')
                  .fontSize(26)
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 24 })
                // 应用简介
                Text('聆听世界的声音')
                  .fontSize(new WidthBreakpointType(14, 14, 16).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.Gray)
                  .margin({ top: 16 })
                Blank()
                Row() {
                  SymbolGlyph($r('sys.symbol.security_shield'))
                    .fontColor([$r('app.color.list_on_color')])
                    .fontSize(24)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)

                Text() {
                  Span('本应用提供问卷管理、跨端协同和分布式管理等服务，本应用需用户联网、登录华为账号、开启跨应用关联等功能以便为您提供更好的服务。我们将遵守')
                  Span('隐私声明').fontColor($r('app.color.list_on_color')).onClick(() => {
                    this.loginInfos.pushPath({ name: 'AgreementView', param: 0 })
                  })
                  Span('、')
                  Span('用户协议').fontColor($r('app.color.list_on_color')).onClick(() => {
                    this.loginInfos.pushPath({ name: 'AgreementView', param: 1 })
                  })
                  Span('。点击“同意”表示您已同意使用。')
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
                        this.swiperController.showNext();
                      }
                    })
                  })
                }
              }
              .width('100%')
              .height('100%')
            } else if (index === 1) {
              Column() {
                // 顶部填充区域
                Blank()
                  .height(new WidthBreakpointType(120, 72, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))

                if (this.appBasicData.isHuaweiID) {
                  Image(this.avatarUri)
                    .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                    .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                    .borderRadius(new WidthBreakpointType(32, 32, 36).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  Text(`你好，${this.nickName}`)
                    .fontSize(26)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 24 })
                } else {
                  SymbolGlyph($r('sys.symbol.person_crop_circle_fill'))
                    .fontSize(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                    .fontColor([$r('app.color.list_on_color')])
                  Text('请登录')
                    .fontSize(26)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 24 })
                }

                Blank()

                // Button().onClick(() => {
                //   getListFile(`${this.context.filesDir}/avatarDir`)
                // })

                // 登录状态
                if (this.appBasicData.isHuaweiID) {
                  ExitWithHuaweiButton({
                    callback: () => {
                      // 刷新华为账号状态
                      this.appBasicData.isHuaweiID = false;
                    }
                  })
                }
                // 未登陆状态
                else {
                  LoginWithHuaweiButton({
                    callback: (avatarUri: string, nickName: string) => {
                      // 刷新华为账号状态
                      this.appBasicData.isHuaweiID = true;

                      this.swiperBox.push('');

                      // 保存昵称
                      createFile(this.context, '/avatarDir/nickName', nickName, (destPath: string) => {
                        readFile(`${this.context.filesDir}/avatarDir/nickName`, (buf: string) => {
                          this.nickName = buf;
                          this.appBasicData.nickName = buf;
                        })
                      })

                      // 保存头像
                      createFile(this.context, '/avatarDir/avatarUri', avatarUri, (destPath: string) => {
                        readFile(`${this.context.filesDir}/avatarDir/avatarUri`, (buf: string) => {
                          this.avatarUri = buf;
                          this.appBasicData.avatarUri = buf;
                        })
                      })
                    }
                  })

                }

              }
              .width('100%')
              .height('100%')
            } else {
              Column() {
                // 顶部填充区域
                Blank()
                  .height(new WidthBreakpointType(120, 72, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))

                Image($r('app.media.startIcon'))
                  .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .borderRadius(12)

                Text('欢迎使用')
                  .fontSize(24)
                  .margin({ top: 24 })

                Text('一起聆听世界的声音')
                  .fontSize(new WidthBreakpointType(14, 14, 16).getValue(this.windowUtil.mainWindowInfo.widthBp))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.Gray)
                  .margin({ top: 16 })

                Blank()

                Button() {
                  Text('点击进入')
                }
                .width('50%')
                .height(40)
                .backgroundColor($r('app.color.list_on_color'))
                .onClick(() => {
                  this.appBasicData.isStart = true;
                })
              }
              .width('100%')
              .height('100%')
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding(16)
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