import { abilityAccessCtrl, bundleManager, Permissions, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';

// 校验当前是否已经授权
export async function checkPermissionGrant(permission: Permissions, callback: Function = () => {
}): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  // 获取应用程序的 accessTokenID
  let tokenId: number = 0;
  try {
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    Logger.error('[CheckPermission.checkPermissionGrant]',
      `Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
  }

  // 校验应用是否被授予权限
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    Logger.error('[CheckPermission.checkPermissionGrant]',
      `Failed to check access token. Code is ${err.code}, message is ${err.message}`);
  }

  callback(grantStatus);
  return grantStatus;

}

export async function checkPermissions(): Promise<void> {
  let grantStatus: boolean = await checkPermissionGrant('ohos.permission.GET_NETWORK_INFO') ===
  abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  // 申请权限
  if (!grantStatus) {

  }
  // 已经授权，可以继续访问目标操作
  else {

  }
}

// 动态向用户申请权限
// 使用 UIExtensionAbility: 将common.UIAbilityContext 替换为 common.UIExtensionContext
export function reqPermissionsFormUser(permissions: Permissions[], context: common.UIAbilityContext,callback:Function=()=>{}): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  // requestPermissionFormUser会判断权限的授权状态来决定是否唤起弹窗
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: number[] = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问操作
        callback(true);
      } else {
        // 当用户拒绝授权时，系统应提示用户必须授予相应权限才能使用当前页面的功能，
        // 并指导用户前往系统设置开启所需权限
        callback(false);
        return;
      }
    }
    // 授权成功
  }).catch((err: BusinessError) => {
    Logger.error('[CheckPermission.reqPermissionsFormUser]',
      `Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
  })
}

export function reqPermissionsFormUserAgain(permission: Permissions[], context: common.UIAbilityContext,callback:Function=()=>{}): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  atManager.requestPermissionOnSetting(context, permission).then((data: Array<abilityAccessCtrl.GrantStatus>) => {
    callback(data);
    Logger.info('[CheckPermission.reqPermissionsFormUserAgain]', 'data:' + JSON.stringify(data));
  }).catch((err: BusinessError) => {
    Logger.error('[CheckPermission.reqPermissionsFormUserAgain]',
      `data: ${JSON.stringify(err.code)}, ${JSON.stringify(err.message)}}`);
  });
}