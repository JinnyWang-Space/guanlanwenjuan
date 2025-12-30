import { AppAppearanceViewModel,
  AppGeneralViewModel,
  StartVibrator, Survey, WidthBreakpointType, WindowUtil } from "common";
import window from '@ohos.window';
import { AppStorageV2, PersistenceV2 } from "@kit.ArkUI";
import Logger from "common/src/main/ets/utils/Logger";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct SearchView {
  // 在 PersistenceV2 中创建一个 type 为 AppAppearanceViewModel 的键值对
  @Local appAppearanceData: AppAppearanceViewModel =
    PersistenceV2.globalConnect({ type: AppAppearanceViewModel, defaultCreator: () => new AppAppearanceViewModel() })!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 在 AppStorageV2中创建一个 key为 WindowUtil的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 创建导航器实例（子）
  @Consumer('pageInfo') pageInfos: NavPathStack = new NavPathStack();
  // 搜索文本
  @Local searchText: string = '';
  @Consumer('surveys') surveys: Survey[] = [];
  @Local surveysForSearch: Survey[] = [];

  @Monitor('searchText')
  searchTextChange() {
    this.getSurveyInfo();
  }

  // 创建滑动手势配置参数对象
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {

        Image(this.appAppearanceData.staticWallpaper)

        // 标题栏
        Row({ space: 12 }) {
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
            this.pageInfos.pop();
          })

          Search({ placeholder: $r('app.string.search_view_search_text'), value: this.searchText!! })
            .layoutWeight(1)
            .onClick(()=>{
              // 开启滑动触感反馈
              if (this.appGeneralData.isHapticButton) {
                StartVibrator()
              }
            })
        }
        .width('100%')
        .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
        .padding({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
          left: 16, right: 16
        })
        .zIndex(1)

        Scroll() {
          Column() {

            Blank()
              .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56 + 16)

            // Text(JSON.stringify(this.surveysForSearch))
            List({ space: 24 }) {
              ForEach(this.surveysForSearch, (surveyForSearch: Survey, surveyIndex: number) => {
                ListItem() {
                  // item 视图
                  Row() {
                    Row() {
                      Column() {
                      }
                      .width(48)
                      .height('100%')
                      .justifyContent(FlexAlign.Center)
                      .backgroundColor(Color.Gray)
                      .backgroundImage($r('app.media.surveyBackground'))
                      .borderRadius({
                        topLeft: 2,
                        bottomLeft: 2,
                        topRight: 8,
                        bottomRight: 8
                      })
                      .margin({ right: 16 })

                      Text(surveyForSearch.title)
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
                    // 开启列表项触感反馈
                    if (this.appGeneralData.isHapticListItem) {
                      StartVibrator()
                    }
                    this.pageInfos.pushPath({ name: 'CheckSurveyView', param: surveyForSearch.id });
                  })
                  .clickEffect({ level: ClickEffectLevel.LIGHT })
                }
              }, (surveyForSearch: Survey, surveyIndex: number) => JSON.stringify(surveyForSearch) + surveyIndex)
            }
            .width('100%')
            .layoutWeight(1)
            .lanes(new WidthBreakpointType(1, 2, 2).getValue(this.windowUtil.mainWindowInfo.widthBp), 32)
            .contentStartOffset(16)
            .contentEndOffset(24)
            .padding({ left: 16, right: 16 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)
      }
      .gesture(
        PanGesture(this.panOption)
          .onActionEnd((event: GestureEvent) => {
            // 开启滑动触感反馈
            if (this.appGeneralData.isHapticSwipe) {
              StartVibrator()
            }
            this.pageInfos.pop();
            Logger.info('[ContentView.PanGesture]', 'Pan end');
          })
      )
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }

  private getSurveyInfo() {
    if (this.searchText.trim().length === 0) {
      this.surveysForSearch = [];
    } else {
      const targetSurveys: Survey[] = [];
      this.surveys.map((survey: Survey) => {
        if (survey.title.includes(this.searchText)) {
          targetSurveys.push(survey);
        }
      })
      this.surveysForSearch = targetSurveys;
    }
  }
}

@Builder
export function SearchBuilder() {
  SearchView();
}