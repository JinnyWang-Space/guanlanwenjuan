@ObservedV2
export class AppViewModel {
  // 是否同意使用
  @Trace isAgree: boolean = false;
  // 是否开始使用
  @Trace isStart: boolean = false;
  // 是否登录华为账号
  @Trace isHuaweiID: boolean = false;

  @Trace avatarUri:string = '';
  @Trace nickName:string = '';
}