import { Survey, WindowUtil } from "common";
import window from '@ohos.window';
import { AppStorageV2 } from "@kit.ArkUI";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct SearchView {
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

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
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
            this.pageInfos.pop();
          })

          Search({ placeholder: '请输入您要搜索的问卷', value: this.searchText!! })
            .layoutWeight(1)
        }
        .width('100%')
        .height(this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height) + 56)
        .padding({
          top: this.getUIContext().px2vp(this.windowUtil.mainWindowInfo.AvoidSystem?.topRect.height),
          left: 16, right: 16
        })
        .zIndex(1)
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

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
                    this.pageInfos.pushPath({ name: 'CheckSurveyView', param: surveyForSearch.id });
                  })
                  .clickEffect({ level: ClickEffectLevel.LIGHT })
                }
              }, (surveyForSearch: Survey, surveyIndex: number) => JSON.stringify(surveyForSearch) + surveyIndex)
            }
            .width('100%')
            .layoutWeight(1)
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
      .backgroundColor($r('sys.color.background_secondary'))
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