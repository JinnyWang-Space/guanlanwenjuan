import {
  AccountCloud,
  AppGeneralViewModel,
  AppViewModel,
  createFile,
  ExitWithHuaweiButton,
  LoginWithHuaweiButton,
  readFile,
  StartVibrator,
  unlink,
  WidthBreakpointType,
  WindowUtil
} from "common"
import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { common } from "@kit.AbilityKit";
import Logger from "common/src/main/ets/utils/Logger";
import { cloudDatabase } from "@kit.CloudFoundationKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct AccountView {
  // 获取应用上下文
  @Local context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 在 PersistenceV2 中创建一个 type 为 AppViewModel 的键值对
  @Local appBasicData: AppViewModel =
    PersistenceV2.globalConnect({ type: AppViewModel, defaultCreator: () => new AppViewModel() })!;
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });

  build() {
    Column() {
      // 登录华为账号
      if (this.appBasicData.isHuaweiID) {
        Image(this.appBasicData.avatarUri)
          .width(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .height(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .borderRadius(new WidthBreakpointType(32, 32, 36).getValue(this.windowUtil.mainWindowInfo.widthBp))
        Text() {
          Span($r('app.string.app_greeting'))
          Span(`${this.appBasicData.nickName}`)
        }
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24 })

        Text(`WQIID：${this.appBasicData.WQIId}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 6 })
      }
      // 未登录华为账号
      else {
        SymbolGlyph($r('sys.symbol.person_crop_circle_fill'))
          .fontSize(new WidthBreakpointType(64, 64, 72).getValue(this.windowUtil.mainWindowInfo.widthBp))
          .fontColor([$r('app.color.list_on_color')])
        Text($r('app.string.app_log_in_prompt'))
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })
      }

      Blank()

      // 登录状态
      if (this.appBasicData.isHuaweiID) {
        ExitWithHuaweiButton({
          callback: () => {
            // 刷新华为账号状态
            this.appBasicData.isHuaweiID = false;
            this.appBasicData.nickName = '';
            this.appBasicData.avatarUri = '';
            this.appBasicData.WQIId = '';
            this.appBasicData.openId = '';

            unlink(this.context.filesDir + '/avatarDir/nickName')
            unlink(this.context.filesDir + '/avatarDir/avatarUri')
          }
        })
      }
      // 未登陆状态
      else {
        LoginWithHuaweiButton({
          callback: async (avatarUri: string, nickName: string, open_id: string) => {
            // 刷新华为账号状态
            this.appBasicData.isHuaweiID = true;
            this.appBasicData.openId = open_id;

            let databaseZone = cloudDatabase.zone('guanlanwenjuan');
            const accountCondition = new cloudDatabase.DatabaseQuery(AccountCloud);
            // 根据 openid 查询，获取 id
            accountCondition.equalTo('open_id', this.appBasicData.openId);
            let result = await databaseZone.query(accountCondition);
            // promptAction.openToast({ message: JSON.stringify(result) })

            // 是否成功访问到云数据库中的数据，进行昵称与头像的显示
            let isShow: boolean = false;

            // 未登录过的openID
            if (result.length === 0) {
              try {
                let account = new AccountCloud();
                account.id = 1;
                account.open_id = this.appBasicData.openId;
                let success = await databaseZone.upsert([account]);

                if (success) {
                  let result = await databaseZone.query(accountCondition);
                  // promptAction.openToast({ message: JSON.stringify(result) })
                  isShow = true;
                  this.appBasicData.WQIId = result[0].id.toString().padStart(9, '0');
                }
                Logger.info('[AccountView]', `Succeeded in upserting feedbackData, result: ${success}`);
              } catch (err) {
                Logger.error('[AccountView]', `Failed to upsert data, code: ${err.code}, message: ${err.message}`);
              }
            }
            // 登陆过的
            else {
              isShow = true;
              this.appBasicData.WQIId = result[0].id.toString().padStart(9, '0');
            }

            if (isShow) {
              // 保存昵称
              createFile(this.context, '/avatarDir/nickName', nickName, (destPath: string) => {
                readFile(`${this.context.filesDir}/avatarDir/nickName`, (buf: string) => {
                  this.appBasicData.nickName = buf;
                })
              })

              // 保存头像
              createFile(this.context, '/avatarDir/avatarUri', avatarUri, (destPath: string) => {
                readFile(`${this.context.filesDir}/avatarDir/avatarUri`, (buf: string) => {
                  this.appBasicData.avatarUri = buf;
                })
              })
            }
          }
        })
      }

      Blank().height(36)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .gesture(
      PanGesture(this.panOptionRight)
        .onActionEnd((event: GestureEvent) => {
          // 开启滑动触感反馈
          if (this.appGeneralData.isHapticSwipe) {
            StartVibrator()
          }
          this.toolInfos.pop();
          Logger.info('[ContentView.PanGesture]', 'Pan end');
        })
    )
  }
}
