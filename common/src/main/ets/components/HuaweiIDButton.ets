import { loginComponentManager, LoginWithHuaweiIDButton } from "@hms.core.account.LoginComponent";
import { BusinessError } from "@kit.BasicServicesKit";
import { cancelAuthorization, dealAllError, getAvatarAndNickName } from "../utils/AccountUtil";
import { PersistenceV2, promptAction } from "@kit.ArkUI";
import LoggerUtils from "../utils/Logger";
import { AppViewModel } from "../viewmodel/AppViewModel";

@ComponentV2
export struct LoginWithHuaweiButton {
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
  @Param callback: Function = () => {
  };
  // 构造 LoginWithHuaweiIDButton 组件的控制器
  private controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
    /**
     * 当应用使用自定义的登录页时，如果用户未同意协议，需要设置协议状态为 NOT_ACCEPTED，当用户同意协议后再设置
     * 协议状态为 ACCEPTED，才可以使用华为账号一键登录功能
     */
      .setAgreementStatus(loginComponentManager.AgreementStatus.ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          dealAllError(error);
          return;
        }
        if (response) {
          // 获取到 Authorization Code
          const authorizationCode = response.authorizationCode;
          getAvatarAndNickName(this.getUIContext(), (avatarUri: string, nickName: string) => {

            this.callback(avatarUri,nickName);

          })
          // this.callback();
          LoggerUtils.info('[Mine.controller]', `Succeeded in getting response.`);
          return;
        }
      })
      .onClickEvent((error: BusinessError, clickEvent: loginComponentManager.ClickEvent) => {
        if (error) {

          return;
        }
        LoggerUtils.info('[Mine.controller]', `onClickEvent clickEvent: ${clickEvent}`);
      });

  build() {

    LoginWithHuaweiIDButton({
      params: {
        // LoginWithHuaweiIDButton支持的样式
        style: loginComponentManager.Style.BUTTON_RED,
        // 账号登陆按钮在登录过程中展示加载态
        extraStyle: {
          buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
            show: true
          })
        },
        // LoginWithHuaweiIDButton的边框圆角半径
        borderRadius: 24,
        // LoginWithHuaweiIDButton支持的登陆类型
        loginType: loginComponentManager.LoginType.ID,
        // LoginWithHuaweiIDButton支持按钮的样式跟随深浅色模式
        supportDarkMode: true,
        // 是否需要获取用户风险等级
        riskLevel: true
      },
      controller: this.controller
    })
      .width('60%')
      .height(40)

  }
}

@ComponentV2
export struct ExitWithHuaweiButton {
  @Param callback: Function = () => {
  };

  build() {

    Button() {
      Text('退出账号')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Red)
    }
    .width('60%')
    .height(40)
    .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
    .onClick(() => {
      cancelAuthorization(this.getUIContext(), () => {
        this.callback();
      })
    })

  }
}