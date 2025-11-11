import {
  AppTmpViewModel,
  AppViewModel,
  checkPermissionGrant,
  DistributedDB,
  MarketCloud,
  Question,
  QuestionCloud,
  QuestionTemplate,
  reqPermissionsFormUser,
  reqPermissionsFormUserAgain,
  savePixelMapToAlbum,
  Survey,
  SurveyCloud,
  SurveyDescription,
  SurveyStatus,
  SurveyTemplate,
  WidthBreakpointType,
  WindowUtil
} from "common";
import {
  AppStorageV2,
  PersistenceV2,
  promptAction,
  SymbolGlyphModifier,
  TipsDialogV2,
  AdvancedDialogV2Button,
  window
} from "@kit.ArkUI";
import { SideBarListModel } from "../model/SideBarListModel";
import { SideBarListViewModel } from "../viewmodel/SideBarListViewModel";
import { ShowListModel } from "../model/ShowListModel";
import { ShowListViewModel } from "../viewmodel/ShowListViewModel";
import { abilityAccessCtrl, AbilityConstant, common } from "@kit.AbilityKit";
import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from "@hms.hds.hdsBaseComponent";
import { image } from "@kit.ImageKit";
import { generateBarcode, scanBarcode, scanCore } from "@kit.ScanKit";
import { BusinessError } from '@kit.BasicServicesKit'
import { FunctionComponent } from "@hms.ai.AgentFramework";
import Logger from "common/src/main/ets/utils/Logger";
import { cloudDatabase } from "@kit.CloudFoundationKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct ContentView {
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
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

  @Monitor('sideBarMainIndex')
  async sideBarMainIndexChange() {
    if (this.sideBarMainIndex === 5 && this.appTmpData.isNetwork) {
      this.initMarket();
    }
  }

  // 修改菜单 —— 删除
  @Builder
  MenuView(surveyId: number, index: number) {
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
    // 废纸篓页面菜单
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
  // 创建模块实例
  @Local marketCategories: cloudDatabase.DatabaseObject[] = [];
  // 创建模板问卷实例
  @Local surveyTemplate: cloudDatabase.DatabaseObject[] = [];

  async aboutToAppear(): Promise<void> {
    await this.distributedDB.setDistributedTables(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  // 二维码图片
  @Local pixelMap: image.PixelMap | undefined = undefined;
  @Local isLoading: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 标题栏
      Row() {
        // 标题
        Text(this.mainVM[this.sideBarMainIndex].label)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .margin({ left: this.isShowSidebar ? 0 : 56 })
          .animation({ duration: 400, curve: Curve.EaseInOut })

        Blank()

        // 搜索
        if (this.windowUtil.mainWindowInfo.widthBp < WidthBreakpoint.WIDTH_MD) {
          Button() {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontWeight(FontWeight.Normal)
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .height(40)
          .width(40)
          .margin({ right: 12 })
          .onClick(() => {
            this.pageInfos.pushPath({ name: 'SearchView' });
          })
        } else {
          Search()
            .width('30%')
            .margin({ right: 12 })
            .onClick(() => {
              this.pageInfos.pushPath({ name: 'SearchView' });
            })
        }

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
        .margin({ right: 12 })
        .onClick(() => {
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
            .height(
              new WidthBreakpointType(
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24,
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 24,
                this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 +
                  38).getValue(this.windowUtil.mainWindowInfo.widthBp)
            )

          // Text(JSON.stringify(this.appTmpData.isNetwork))
          // Text(JSON.stringify(this.surveys))

          // Text(`云数据库（模块）：${JSON.stringify(this.marketCategories)}`)
          // Text(`云数据库（问卷）${JSON.stringify(this.surveyTemplate)}`)
          // Text(`云数据库（问题）${JSON.stringify(this.questionTemplate)}`)

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

          // 获取生成码后显示
          if (this.pixelMap) {
            Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
          }

          // 侧边栏前 6 项
          if (this.sideBarMainIndex < 5) {
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
                        .backgroundColor($r('sys.color.comp_background_tertiary'))
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
                          .padding({ right: 40 })
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
              Refresh({ refreshing: this.isLoading!! }) {
                List({ space: new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) }) {
                  ForEach(this.surveyTemplate, (survey: SurveyTemplate, surveyIndex: number) => {
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
                          .backgroundColor($r('sys.color.comp_background_tertiary'))
                          .borderRadius({
                            topLeft: 2,
                            bottomLeft: 2,
                            topRight: 8,
                            bottomRight: 8
                          })
                          .margin({ right: 16 })

                          Text(survey.title)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .layoutWeight(1)
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
                        this.pageInfos.pushPath({ name: 'MarketSurveyView', param: survey.id });
                      })
                      .clickEffect({ level: ClickEffectLevel.LIGHT })
                    }
                  }, (survey: SurveyTemplate, surveyIndex: number) => JSON.stringify(survey) + surveyIndex)
                }
                .width('100%')
                .layoutWeight(1)
                .listDirection(Axis.Vertical)
                .lanes(new WidthBreakpointType(1, 2, 2).getValue(this.windowUtil.mainWindowInfo.widthBp), 32)
                .contentEndOffset(24)
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
          }

        }
        .width('100%')
        .padding({
          left: this.isShowSidebar ?
            new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) :
            new WidthBreakpointType(16, 16, 32 + 140).getValue(this.windowUtil.mainWindowInfo.widthBp),
          right: this.isShowSidebar ?
            new WidthBreakpointType(16, 16, 32).getValue(this.windowUtil.mainWindowInfo.widthBp) :
            new WidthBreakpointType(16, 16, 32 + 140).getValue(this.windowUtil.mainWindowInfo.widthBp)
        })
        .animation({ duration: 400, curve: Curve.EaseInOut })
      }
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
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
        }
        // 关闭按钮返回
        if (dismissSheetAction.reason === DismissReason.CLOSE_BUTTON) {
          dismissSheetAction.dismiss();
        }
      }
    })
  }

  // 从云数据库获取模板数据
  private async initMarket() {
    // 初始化存储区
    let databaseZone = cloudDatabase.zone('guanlanwenjuan');
    // 初始化查询
    let marketCloud = new cloudDatabase.DatabaseQuery(MarketCloud);
    let surveyTemplate = new cloudDatabase.DatabaseQuery(SurveyTemplate);
    // 进行查询并赋值
    try {
      this.marketCategories = await databaseZone.query(marketCloud);
      this.surveyTemplate = await databaseZone.query(surveyTemplate);
      this.isLoading = false;
      Logger.info('[ContentView.aboutAppear]',
        `Succeeded in querying data, result: ${JSON.stringify(this.marketCategories)}`);
    } catch (err) {
      Logger.error('[ContentView.aboutAppear]', `Failed to query data, code: ${err.code}, message: ${err.message}`);
    }
  }
}

@Builder
export function ContentPanelBuilder() {
  ContentView();
}

@ComponentV2
export struct DotSheetBind {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
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
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
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
                Column() {
                  Row() {
                    // if (index === 0) {
                    //   Text(item)
                    //     .fontSize(16)
                    //     .fontWeight(FontWeight.Medium)
                    //   Blank()
                    //   Toggle({ type: ToggleType.Switch, isOn: this.appBasicData.isDistributeDataSync!! })
                    //     .selectedColor($r('app.color.list_on_color'))
                    //     .onChange((isOn: boolean) => {
                    //       if (isOn) {
                    //         checkPermissionGrant('ohos.permission.DISTRIBUTED_DATASYNC',
                    //           (grantStatus: abilityAccessCtrl.GrantStatus) => {
                    //             if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
                    //               if (this.appBasicData.isDistributedFirst) {
                    //                 reqPermissionsFormUser(['ohos.permission.DISTRIBUTED_DATASYNC'], this.context,
                    //                   (isDataSync: boolean) => {
                    //                     this.appBasicData.isDistributeDataSync = isDataSync;
                    //                   });
                    //                 this.appBasicData.isDistributedFirst = false;
                    //               } else {
                    //                 reqPermissionsFormUserAgain(['ohos.permission.DISTRIBUTED_DATASYNC'], this.context,
                    //                   (grantStatus: Array<abilityAccessCtrl.GrantStatus>) => {
                    //                     if (grantStatus[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
                    //                       this.appBasicData.isDistributeDataSync = true;
                    //                     } else {
                    //                       this.appBasicData.isDistributeDataSync = false;
                    //                     }
                    //                   });
                    //               }
                    //             }
                    //           })
                    //       } else {
                    //         promptAction.openToast({
                    //           message: '应用内无法关闭该权限，请到系统设置-应用和元服务-观澜问卷中关闭”设备发现和连接“',
                    //           duration: 3000
                    //         })
                    //       }
                    //     })
                    // }
                    // if (index === 1) {
                    Row() {
                      Text(item)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                      Blank()
                      SymbolGlyph($r('sys.symbol.chevron_right'))
                        .fontSize(24)
                        .fontColor([$r('sys.color.font_on_secondary')])
                    }
                    .width('100%')
                    .onClick(() => {
                      this.toolInfos.pushPath({ name: 'ToolView', param: [item, index.toString()] as string[] });
                      // this.toolInfos.pushPath({ name: 'ToolView' });
                    })

                    // }
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
                  .clickEffect({ level: ClickEffectLevel.LIGHT })

                  if (index < 1) {
                    Divider().padding({ left: 16, right: 16 })
                  }
                }

              }
              .padding({
                top: 2,
                bottom: 2,
                left: 4,
                right: 4
              })
              .backgroundColor($r('sys.color.ohos_fa_list_card_bg'))
            })
          }
          .width('100%')
          // .backgroundColor(Color.Orange)
          .borderRadius(15)
        }
        .padding({ left: 16, right: 16 })
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}

@Builder
export function DotSheetBindBuilder() {
  DotSheetBind();
}