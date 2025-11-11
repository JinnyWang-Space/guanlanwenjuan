@ObservedV2
export class AppViewModel {
  // 是否同意使用
  @Trace isAgree: boolean = false;
  // 是否开始使用
  @Trace isStart: boolean = false;
  // 是否登录华为账号
  @Trace isHuaweiID: boolean = false;
  // 用户头像 uri
  @Trace avatarUri: string = '';
  // 用户昵称
  @Trace nickName: string = '';
  // 是否开启跨设备同步
  @Trace isDistributeDataSync: boolean = false;
  @Trace isDistributedFirst: boolean = true;
}

@ObservedV2
export class AppTmpViewModel {
  // 是否有网
  @Trace isNetwork: boolean = false;
}