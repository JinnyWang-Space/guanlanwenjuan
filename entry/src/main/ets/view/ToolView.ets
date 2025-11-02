import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { promptAction } from "@kit.ArkUI";

@ComponentV2
export struct ToolView {
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 标题信息
  private toolId: string[] = this.toolInfos.getParamByName('ToolView')[0] as string[];
  // 用于监听是否显示设置半模态（子）
  @Consumer('isToolViewShow') isToolViewShow: boolean = false;

  aboutToAppear(): void {

  }

  @Builder
  aboutView() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(56)
        .height(56)
        .borderRadius(12)
        .margin({ bottom: 12 })
      Text('观澜问卷')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      Blank()
      Text('津ICP备2025039701号-1A')
        .fontSize(12)
        .fontColor('#ff4ba2f6')
      Text('版权所有 © 2025 观澜问卷 保留一切权利')
        .fontSize(12)
        .margin({ bottom: 24 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.button_background_color_transparent'))
          .onClick(() => {
            this.toolInfos.pop();
          })
          .margin({ right: 12 })

          Text(this.toolId[0])
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
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

        Scroll() {
          Column() {
            Blank().height(72)
            if (parseInt(this.toolId[1]) === 0) {
              this.aboutView();
            } else {
              Text('sdco')
              //
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .backgroundColor(Color.Gray)
  }
}

@Builder
export function ToolBuilder() {
  ToolView();
}