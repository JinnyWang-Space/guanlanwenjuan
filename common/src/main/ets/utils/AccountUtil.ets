import { authentication } from "@kit.AccountKit";
import { util } from "@kit.ArkTS";
import { BusinessError } from "@kit.BasicServicesKit";
import Logger from "./Logger";

// 账号服务类
// 登录请求
export function loginWithHuaweiID(UIContext: UIContext, callback: Function = () => {
}) {
  // 创建授权请求，并设置参数
  const huaweiIdProvider = new authentication.HuaweiIDProvider();
  const loginRequest = huaweiIdProvider.createAuthorizationWithHuaweiIDRequest();
  // 默认值为 true，若账号未登录则强制拉起账号登录页
  loginRequest.forceAuthorization = true;
  loginRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;
  loginRequest.state = util.generateRandomUUID(); // 建议使用generateRandomUUID生成state

  // 执行登录请求，并处理结果
  try {
    const controller = new authentication.AuthenticationController(UIContext.getHostContext());
    controller.executeRequest(loginRequest, (error: BusinessError<Object>, data) => {
      if (error) {
        dealAllError(error);
        return;
      }
      const loginWithHuaweiIDResponse = data as authentication.LoginWithHuaweiIDResponse;
      const state = loginWithHuaweiIDResponse.state;
      if (state !== undefined && loginRequest.state !== state) {
        Logger.error('[AccountKit.loginWithHuaweiID]',
          `Failed to login. The state is different, response state: ${state}`);
        return;
      }
      Logger.info('[AccountKit.loginWithHuaweiID]', `Succeeded in login.`);
      const loginWithHuaweiIDCredential = loginWithHuaweiIDResponse.data!;
      const code = loginWithHuaweiIDCredential.authorizationCode;
      const idToken = loginWithHuaweiIDCredential.idToken;
      const openID = loginWithHuaweiIDCredential.openID;
      const unionID = loginWithHuaweiIDCredential.unionID;
      // 开发者处理 code, idToken
      callback(code, idToken, openID, unionID);
    });
  } catch (error) {
    dealAllError(error);
  }
}

// 取消账号授权
export function cancelAuthorization(UIContext: UIContext, callback: Function = () => {
}) {
  // 创建取消授权请求，并设设置参数
  const cancelRequest = new authentication.HuaweiIDProvider().createCancelAuthorizationRequest();
  // 用于防跨站点请求伪造
  cancelRequest.state = util.generateRandomUUID(); // 建议使用generateRandomUUID生成state

  try {
    const controller = new authentication.AuthenticationController(UIContext.getHostContext());
    controller.executeRequest(cancelRequest, (error: BusinessError<Object>, data) => {
      if (error) {
        dealAllError(error);
        return;
      }
      const cancelAuthorizationResponse = data as authentication.CancelAuthorizationResponse;
      const state = cancelAuthorizationResponse.state;
      if (state !== undefined && cancelRequest.state !== state) {
        Logger.error('[AccountKit.cancelAuthorization]',
          `Failed to cancel. The state is different, response state: ${state}`);
        return;
      }
      Logger.info('[AccountKit.cancelAuthorization]', 'Succeeded in canceling.');
      callback();
    });
  } catch (error) {
    dealAllError(error);
  }
}

// 获取头像和昵称
export function getAvatarAndNickName(UIContext: UIContext, callback: Function) {
  // 创建授权请求，并设置参数
  const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
  // 获取头像昵称需要传如下scope
  authRequest.scopes = ['profile'];
  // 若开发者需要进行服务端开发，则需要传如下permission获取authorizationCode
  // authRequest.permissions = ['serviceauthcode'];
  // 用户是否需要登录授权，该值为true且用户登录或未授权时，会拉起用户登录或授权页面
  authRequest.forceAuthorization = true;
  // 用于防跨站点请求伪造
  authRequest.state = util.generateRandomUUID();
  // 执行授权请求
  try {
    const controller = new authentication.AuthenticationController(UIContext.getHostContext());
    controller.executeRequest(authRequest).then((data) => {
      const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
      const state = authorizationWithHuaweiIDResponse.state;
      if (state !== undefined && authRequest.state !== state) {
        Logger.error('AccountKit.getAvatarAndNickName',
          `Failed to authorize. The state is different, response stste: ${state}`);
        return;
      }
      Logger.error('AccountKit.getAvatarAndNickName', 'Succeeded in authentication.');
      const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse.data!;
      const avatarUri = authorizationWithHuaweiIDCredential.avatarUri!;
      const nickName = authorizationWithHuaweiIDCredential.nickName!;
      const unionID = authorizationWithHuaweiIDCredential.unionID;
      const openID = authorizationWithHuaweiIDCredential.openID;
      const authorizationCode = authorizationWithHuaweiIDCredential.authorizationCode;
      // 开发者处理以上变量
      Logger.error('AccountKit.getAvatarAndNickName', `AvatarUri: ${avatarUri}`);
      Logger.error('AccountKit.getAvatarAndNickName', `nickName: ${nickName}`);
      // hilog.info(0x00000, 'testTag', `UnionID: ${unionID}`);
      // hilog.info(0x00000, 'testTag', `OpenID: ${openID}`);
      // hilog.info(0x00000, 'testTag', `AuthorizationCode: ${authorizationCode}`);
      // 返回头像和名称
      callback(avatarUri, nickName);
    }).catch((err: BusinessError) => {
      dealAllError(err);
    });
  } catch (error) {
    dealAllError(error);
  }
}

// 错误处理
export function dealAllError(error: BusinessError | BusinessError<Object>): void {
  Logger.error('[AccountKit.dealAllError]', `Failed to auth. Code: ${error.code}, message: ${error.message}`);
  // 在应用登录涉及 UI 交互场景下，建议按照如下错误码指导提示用户
  if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
    // 用户未登录华为账号，请登录华为账号并重试或者尝试使用其他方式登录
  } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
    // 网络异常，请检查当前网络状态并重试或者尝试使用其他方式登录
  } else if (error.code === ErrorCode.ERROR_CODE_INTERNAL_ERROR) {
    // 登录失败，请尝试使用其他方式登录
  } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
    // 用户取消授权
  } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
    // 系统服务异常，请稍后重试或者尝试使用其他方式登录
  } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
    // 重复请求，应用无需处理
  } else {
    // 应用登录失败，请尝试是用其他方式登录
  }
}

export enum ErrorCode {
  // 账号未登录
  ERROR_CODE_LOGIN_OUT = 1001502001,
  // 网络错误
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  // 内部错误
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  // 用户取消授权
  ERROR_CODE_USER_CANCEL = 1001502012,
  // 系统服务异常
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  // 重复请求
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
}