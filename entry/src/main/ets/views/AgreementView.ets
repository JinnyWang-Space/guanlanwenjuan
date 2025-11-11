import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { webview } from "@kit.ArkWeb";

@ComponentV2
export struct AgreementView {
  // 创建导航器实例（父）
  @Consumer('loginInfo') loginInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 问卷 id
  private agreementId: number = this.loginInfos.getParamByName('AgreementView')[0] as number;

  @Local privacyUrl:string="https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1815786421986826816"
  @Local userUrl:string="https://www.jinnyspace.online/"
  controller: webview.WebviewController = new webview.WebviewController();

  @Builder
  privacyView() {
    Web({src:this.privacyUrl,controller:this.controller})
      .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  userView() {
    Column() {
      Web({src:this.userUrl,controller:this.controller})
        .backgroundColor($r('sys.color.comp_background_primary'))
    }
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
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
            this.loginInfos.pop();
          })
        }
        .width('100%')
        .height(40 + 16 + 12)
        .justifyContent(FlexAlign.Start)
        .zIndex(1)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('sys.color.comp_background_primary'))

        Column() {
          Blank()
            .height(40 + 16 + 12)
          Scroll() {
            if (this.agreementId === 0) {
              this.privacyView();
            } else {
              this.userView();
            }
          }
          .width('100%')
          .layoutWeight(1)
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .backgroundColor($r('sys.color.comp_background_primary'))
  }
}

@Builder
export function AgreementBuilder() {
  AgreementView();
}