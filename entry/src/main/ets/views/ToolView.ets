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
    // promptAction.openToast({message:JSON.stringify(this.toolId)})
  }

  @Builder
  aboutView() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(64)
        .height(64)
        .borderRadius(15)
        .margin({ top: 16, bottom: 12 })
      Text('观澜问卷')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      Blank()
      Text('津ICP备2025039701号-1A')
        .fontSize(12)
        .fontColor($r('app.color.list_on_color'))
      Text('版权所有 © 2025 观澜问卷 保留一切权利')
        .fontSize(12)
        .margin({ bottom: 24 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  distributeView(){

  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 标题栏
        Row() {
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .width(40)
          .height(40)
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
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
        // .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)

        Scroll() {
          Column() {
            Blank().height(72)
            if (parseInt(this.toolId[1]) === 0) {
              this.aboutView();
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .backgroundColor($r('sys.color.sheet_panel_background_color'))
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