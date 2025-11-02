import { DistributedDB, Survey, SurveyStatus, WindowUtil } from "common";
import { AppStorageV2, promptAction, SymbolGlyphModifier, window } from "@kit.ArkUI";
import { SideBarListModel } from "../model/SideBarListModel";
import { SideBarListViewModel } from "../viewmodel/SideBarListViewModel";
import { ShowListModel } from "../model/ShowListModel";
import { ShowListViewModel } from "../viewmodel/ShowListViewModel";
import { common } from "@kit.AbilityKit";
import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from "@hms.hds.hdsBaseComponent";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct ContentView {
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
  // 修改菜单栏创建问卷图标 ———— 删除
  @Local MenuIconModifierTrash: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.trash')).fontSize('24vp').fontColor([Color.Gray]);
  // 设置菜单栏创建问卷图标 ———— 设置
  @Local MenuIconModifierSetting: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.gearshape')).fontSize('24vp').fontColor([Color.Gray]);
  // 用于监听是否刷新显示全部问卷列表
  @Consumer('refresh') refresh: boolean = false;

  // 一系列修改菜单
  @Builder
  MenuView(surveyId: number) {
    if (this.sideBarMainIndex < 4) {
      Menu() {
        MenuItem({ symbolStartIcon: this.MenuIconModifierTrash, content: "删除" })
          .onClick(async () => {
            const success: boolean = await this.distributedDB.deleteSurvey(surveyId, false);
            if (success) {
              this.surveys = await this.distributedDB.getAllSurveys();
              this.refresh = true;
              promptAction.openToast({ message: '已删除' })
            }
          })
      }
    }
    if (this.sideBarMainIndex === 4) {
      Menu() {
        MenuItem({ symbolStartIcon: this.MenuIconModifierRestore, content: "恢复" })
          .onClick(async () => {
            const success: boolean = await this.distributedDB.restoreSurvey(surveyId);
            if (success) {
              this.surveys = await this.distributedDB.getAllSurveys();
              this.refresh = true;
              promptAction.openToast({ message: '已恢复该问卷' })
            }
          })
        MenuItem({ symbolStartIcon: this.MenuIconModifierTrash, content: "永久删除" })
          .onClick(async () => {
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
      MenuItem({ symbolStartIcon: this.menuIconModifier1, content: "创建问卷" })
        .onClick(() => {
          this.pageInfos.pushPath({ name: 'CreateSurveyView' })
        })
    }
  }

  // 创建导航器实例（父）
  @Provider('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 用于监听是否显示设置半模态（父）
  @Provider('isToolViewShow') isToolViewShow: boolean = false;

  // 设置菜单
  @Builder
  dotMenu() {
    Menu() {
      MenuItem({ symbolStartIcon: this.MenuIconModifierSetting, content: "设置" })
        .onClick(() => {
          this.isToolViewShow = true;
        })
    }
  }

  // 创建全部问卷数据实例（子）
  @Consumer('surveys') surveys: Survey[] = [];
  // 创建数据库实例
  private distributedDB: DistributedDB =
    new DistributedDB(this.getUIContext().getHostContext() as common.UIAbilityContext);
  @Local marketList: ShowListModel[] = [...new ShowListViewModel().marketVM];

  async aboutToAppear(): Promise<void> {
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 标题栏
      Row() {
        Text(this.mainVM[this.sideBarMainIndex].label)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .margin({ left: this.isShowSidebar ? 0 : 56 })
          .animation({ duration: 400, curve: Curve.EaseInOut })

        Blank()

        Search()
          .width('30%')
          .margin({ right: 12 })
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
      }
      .width('100%')
      .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
      .justifyContent(FlexAlign.Start)
      .padding({
        top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
        left: 16, right: 16
      })
      .zIndex(1)
      .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

      // 主体视图
      Scroll() {
        Column() {
          Blank()
            .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 38)

          Text(JSON.stringify(this.surveys))

          if (this.sideBarMainIndex < 5) {
            List({ space: 32 }) {
              ForEach(this.showList, (item: ShowListModel, index: number) => {
                ListItem() {
                  Stack() {
                    // item 操作按钮，为了不与悬浮态效果冲突，改为 stack 视图，显示在最上层
                    if ((this.sideBarMainIndex === 0 && index !== 0) || (this.sideBarMainIndex > 0)) {
                      Button() {
                        SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
                          .fontSize(24)
                          .fontColor([Color.Gray])
                      }
                      .width(40)
                      .height(40)
                      .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
                      .zIndex(1)
                      .position({ top: 20, right: 16 })
                      .bindMenu(this.MenuView(item.id))
                    }
                    // item 视图
                    Row() {
                      Row() {
                        Column() {
                          SymbolGlyph($r('sys.symbol.plus'))
                            .fontSize(24)
                        }
                        .width(48)
                        .height('100%')
                        .justifyContent(FlexAlign.Center)
                        .backgroundColor(Color.Gray)
                        .borderRadius({
                          topLeft: 2,
                          bottomLeft: 2,
                          topRight: 8,
                          bottomRight: 8
                        })
                        .margin({ right: 16 })

                        if (this.sideBarMainIndex === 0 && index === 0) {
                          Text('添加问卷')
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                        } else {
                          Column({ space: 12 }) {
                            Text(item.label)
                              .fontSize(16)
                              .fontWeight(FontWeight.Medium)
                            Text(new Date(parseInt(item.deltaT)).toLocaleDateString())
                              .fontSize(14)
                              .fontColor(Color.Gray)
                              .margin({ bottom: 6 })
                          }
                          .height('100%')
                          .justifyContent(FlexAlign.End)
                          .alignItems(HorizontalAlign.Start)
                        }

                        Blank()

                        if (index !== 0) {

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
                    .backgroundColor($r('sys.color.comp_background_primary'))
                    .borderRadius(12)
                    .padding({
                      top: 4,
                      bottom: 4,
                      left: 6,
                      right: 6
                    })
                    .onClick(() => {
                      this.sideBarMainIndex === 0 && index === 0 ? () => {
                      } :
                        this.pageInfos.pushPath({ name: 'CheckSurveyView', param: item.id })
                    })
                  }
                }
              }, (item: ShowListModel, index: number) => JSON.stringify(item) + index)
            }
            .width('100%')
            .layoutWeight(1)
            .listDirection(Axis.Vertical)
            .lanes(2, 32)
            .contentEndOffset(24)
            .padding({ left: this.isShowSidebar ? 32 : 32 + 140, right: this.isShowSidebar ? 32 : 32 + 140 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
          } else {
            List({ space: 32 }) {
              ForEach(this.marketList, (item: ShowListModel, index: number) => {
                ListItem() {
                  // item 视图
                  Row() {
                    Row() {
                      Column() {
                        SymbolGlyph($r('sys.symbol.plus'))
                          .fontSize(24)
                      }
                      .width(48)
                      .height('100%')
                      .justifyContent(FlexAlign.Center)
                      .backgroundColor(Color.Gray)
                      .borderRadius({
                        topLeft: 2,
                        bottomLeft: 2,
                        topRight: 8,
                        bottomRight: 8
                      })
                      .margin({ right: 16 })

                      Column({ space: 12 }) {
                        Text(item.label)
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
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
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius(12)
                  .padding({
                    top: 4,
                    bottom: 4,
                    left: 6,
                    right: 6
                  })
                  .onClick(() => {
                    this.pageInfos.pushPath({ name: 'MarketSurveyView', param: index });
                  })
                }
              }, (item: ShowListModel, index: number) => JSON.stringify(item) + index)
            }
            .width('100%')
            .layoutWeight(1)
            .listDirection(Axis.Vertical)
            .lanes(2, 32)
            .contentEndOffset(24)
            .padding({ left: this.isShowSidebar ? 32 : 32 + 140, right: this.isShowSidebar ? 32 : 32 + 140 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
          }

        }
      }
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .bindSheet(this.isToolViewShow!!, DotSheetBindBuilder(), {
      showClose: false,
      width: 460,
      height: '90%',
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

@Builder
export function ContentPanelBuilder() {
  ContentView();
}

@ComponentV2
export struct DotSheetBind{
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 用于监听是否显示设置半模态（子）
  @Consumer('isToolViewShow') isToolViewShow: boolean = false;

  aboutToAppear(): void {
    // 半模态控制在栈顶页面，防止上次入栈的页面直接关闭未返回栈顶
    this.toolInfos.pop();
  }

  build() {
    HdsNavigation(this.toolInfos) {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Row() {
          Text('设置')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
          Blank()
          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(24)
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.button_background_color_transparent'))
          .onClick(() => {
            this.isToolViewShow = false;
          })
        }
        .width('100%')
        .padding(16)
        .zIndex(1)

        Column() {
          Blank().height(72)
          List() {
            ForEach(['关于'], (item: string, index: number) => {
              ListItem() {
                Row() {
                  Text(item)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(24)
                }
                .width('100%')
                .height(48)
                .alignItems(VerticalAlign.Center)
                .padding({ left: 16, right: 16 })
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
                .onClick(() => {
                  this.toolInfos.pushPath({ name: 'ToolView', param: [item,index.toString()] as string[] });
                  // this.toolInfos.pushPath({ name: 'ToolView' });
                })
              }
              .padding(2)
            })
          }
          .width('100%')
          // .backgroundColor(Color.Orange)
          .borderRadius(16)
        }
        .padding({ left: 16, right: 16 })
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}

@Builder
export function DotSheetBindBuilder(){
  DotSheetBind();
}