import { HdsNavDestination, HdsNavDestinationAttribute } from "@hms.hds.hdsBaseComponent";
import { webview } from "@kit.ArkWeb";
import { AgreementViewModel } from "../viewmodel/AgreementViewModel";

@ComponentV2
export struct AgreementView {
  // 创建导航器实例（父）
  @Consumer('loginInfo') loginInfos: NavPathStack = new NavPathStack();
  // 获取参数 —— 服务文件 id, readonly 声明为只读，不可修改
  private readonly agreementId: number = this.loginInfos.getParamByName('AgreementView')[0] as number;
  // 创建 agreementVM 实例
  private agreementVM?: AgreementViewModel;
  // 创建 web 控制器实例
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    this.agreementVM = new AgreementViewModel(this.agreementId);
  }

  // 导航栏
  @Builder
  navBar() {
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
  }

  // Web 视图
  @Builder
  webView() {
    Stack({ alignContent: Alignment.Center }) {
      // Web 视图
      Web({ src: this.agreementVM?.currentUrl, controller: this.controller })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .onPageBegin(() => {
          this.agreementVM?.onPageBegin();
        })
        .onPageEnd(() => {
          this.agreementVM?.onPageEnd();
        })
      // 是否显示加载状态
      if (this.agreementVM?.isLoading) {
        Column({ space: 24 }) {
          LoadingProgress()
            .size({ width: 64, height: 64 })
            .color($r('app.color.list_on_color'))
          Text($r('app.string.is_loading_text'))
        }

      }
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(Color.Pink)
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 导航栏
        this.navBar();

        Column() {
          Blank()
            .height(40 + 16 + 12)
          Scroll() {
            // Web 视图
            this.webView();
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