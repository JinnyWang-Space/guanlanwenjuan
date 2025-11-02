import { AppStorageV2, promptAction, window } from '@kit.ArkUI'
import { DistributedDB, Survey, SurveyStatus, WindowUtil } from 'common';
import { HdsSideBar } from '@hms.hds.HdsSideBar';
import { sideBarPanelBuilder } from '../view/SideBarView';
import { ContentPanelBuilder } from '../view/ContentView';
import { HdsNavigation, HdsNavigationAttribute } from '@hms.hds.hdsBaseComponent';
import { common } from '@kit.AbilityKit';
import { ShowListModel } from '../model/ShowListModel';
import { ShowListViewModel } from '../viewmodel/ShowListViewModel';
import { SideBarListModel } from '../model/SideBarListModel';
import { SideBarListViewModel } from '../viewmodel/SideBarListViewModel';

// 创建窗口实例
let windowStage: window.WindowStage;

@Entry
@ComponentV2
struct Index {
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
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
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);
  // 用于监听是否刷新显示全部问卷列表
  @Provider('refresh') refresh: boolean = false;

  async aboutToAppear(): Promise<void> {
    // 判断侧边栏是否显示
    this.getIsSideBar();
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext)
    this.surveys = await this.distributedDB.getAllSurveys();
    // 刷新侧边栏主列表
    this.getSBMainItem();
    // 刷新侧边栏主列表item的数量
    this.getSBMainItemNum();
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
          isShowSideBar: this.isShowSidebar!!,
          minSideBarWidth: 280,
          sideBarColor: $r('sys.color.hds_sidebar_overlay'),
          sideBarPanelBuilder: (): void => this.sideBarBuilder(),
          contentPanelBuilder: (): void => this.contentBuilder(),
          sideBarContainerType: this.getSideBarType()
        })
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
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