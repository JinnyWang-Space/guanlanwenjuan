import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window, promptAction } from '@kit.ArkUI';
import { WindowUtil, ImmersiveType, FormInfo, AppTmpViewModel } from 'common';
import { systemShare } from '@kit.ShareKit';
import Logger from 'common/src/main/ets/utils/Logger';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  // 窗口实例
  windowUtil?: WindowUtil;
  // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
  appTmpData: AppTmpViewModel = AppStorageV2.connect(AppTmpViewModel, () => new AppTmpViewModel())!;
  // 创建卡片数据实例
  formInfo: FormInfo = AppStorageV2.connect(FormInfo, () => new FormInfo())!;

  // 冷启动
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      Logger.error('[EntryAbility.onCreate]', 'Failed to set colorMode. Cause: ', JSON.stringify(err));
    }
    Logger.info('[EntryAbility.onCreate]', 'Ability onCreate');

    // 是否为系统分享
    this.getShareData(want, launchParam);

    // 应用接续
    this.receiveContinueData(want, launchParam);

    // 获取router事件中传递的targetPage参数
    this.formDataHandle(want);
  }

  // 热启动
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info('[EntryAbility.onNewWant]', 'Ability onNewWant');

    // 是否为系统分享
    this.getShareData(want, launchParam);

    // 应用接续
    this.receiveContinueData(want, launchParam);

    // 获取router事件中传递的targetPage参数
    this.formDataHandle(want);
  }

  onDestroy(): void {
    Logger.info('[EntryAbility.onDestroy]', '%{public}s', 'Ability onDestroy');
  }

  // 正常启动
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info('[EntryAbility.onWindowStageCreate]', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error('[EntryAbility.onWindowStageCreate]', 'Failed to load the content. Cause: ', JSON.stringify(err));
        return;
      }
      Logger.info('[EntryAbility.onWindowStageCreate]', 'Succeeded in loading the content.');

      // 初始化窗口工具
      this.initWindowUtil(windowStage);
    });
  }

  // 迁移启动
  onWindowStageRestore(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info('[EntryAbility.onWindowStageRestore]', 'Ability onWindowStageRestore');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error('[EntryAbility.onWindowStageRestore]', 'Failed to load the content. Cause: %{public}s',
          JSON.stringify(err));
        return;
      }
      Logger.info('[EntryAbility.onWindowStageRestore]', 'Succeeded in loading the content.');

      // 初始化窗口工具
      this.initWindowUtil(windowStage);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    Logger.info('[EntryAbility.onWindowStageDestroy]', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Logger.info('[EntryAbility.onForeground]', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    Logger.info('[EntryAbility.onBackground]', 'Ability onBackground');
  }

  // 设备 A 传递的应用接续数据
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult | Promise<AbilityConstant.OnContinueResult> {
    // 传递的数据
    const sideBarMainIndex = this.appTmpData.continueSideBarIndex;
    let marketSurveyId = this.appTmpData.marketSurveyId;
    let checkSurveyId = this.appTmpData.checkSurveyId;
    if (sideBarMainIndex) {
      wantParam['sideBarMainIndex'] = sideBarMainIndex;
    }
    if (marketSurveyId) {
      checkSurveyId = '';
      wantParam['marketSurveyId'] = marketSurveyId;
    }
    // if (checkSurveyId) {
    //   marketSurveyId = '';
    //   wantParam['checkSurveyId'] = checkSurveyId;
    // }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  // 初始化窗口工具
  initWindowUtil(windowStage: window.WindowStage) {
    this.windowUtil = AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
    this.windowUtil!.setUIContext();
    this.windowUtil!.setImmersiveType(ImmersiveType.IMMERSIVE);
    this.windowUtil!.updateWindowInfo();
  }

  // 获取router事件中传递的targetPage参数
  formDataHandle(want: Want) {
    if (want?.parameters?.params) {
      // want.parameters.params对应postCardAction()中params内容
      let params: Record<string | number, Object> = JSON.parse(want.parameters.params as string);
      let targetPage = '';
      if (params.targetPage !== undefined) {
        targetPage = params.targetPage as string;
      }
      let targetSideBarMainIndex = -1;
      if (params.targetSideBarMainIndex !== undefined) {
        targetSideBarMainIndex = params.targetSideBarMainIndex as number;
      }
      this.formInfo.targetPage = targetPage;
      this.formInfo.targetSideBarMainIndex = targetSideBarMainIndex;
      Logger.info('[EntryAbility.onNewWant]', `onCreate selectPage: ${targetPage},${targetSideBarMainIndex}`);
    }
  }

  // 获取系统分享数据
  getShareData(want: Want, launchParam: AbilityConstant.LaunchParam) {
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      systemShare.getSharedData(want)
        .then((data: systemShare.SharedData) => {
          data.getRecords().forEach((record: systemShare.SharedRecord) => {
            // 处理分享数据
            // 在 AppStorageV2 中创建一个 type 为 AppTmpViewModel 的键值对
            this.appTmpData.isSystemShare = true;
            this.appTmpData.systemShareImgUri = record.uri!;
          });
        })
        .catch((error: BusinessError) => {
          console.error(`Failed to getSharedData. Code: ${error.code}, message: ${error.message}`);
          this.context.terminateSelf();
        });
    }
  }

  // 设备 B 接收的应用接续数据
  receiveContinueData(want: Want, launchParam: AbilityConstant.LaunchParam) {
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      // 侧边栏 id
      let sideBarMainIndex: number = 0;
      // 模板问卷 id
      let marketSurveyId: string = '';
      // check 问卷 id
      let checkSurveyId: string = '';
      // 开启应用接续
      this.appTmpData.isContinue = true;
      if (want.parameters != undefined) {
        sideBarMainIndex = want.parameters.sideBarMainIndex as number;
        marketSurveyId = want.parameters.marketSurveyId as string;
        checkSurveyId = want.parameters.checkSurveyId as string;
        // 给暂存数据中心赋值
        this.appTmpData.continueSideBarIndex = sideBarMainIndex;
        this.appTmpData.marketSurveyId = marketSurveyId;
        this.appTmpData.checkSurveyId = checkSurveyId;
      }
    }
  }
}