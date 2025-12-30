import { i18n } from "@kit.LocalizationKit";
import { motion } from '@kit.MultimodalAwarenessKit';

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
  // OPENID
  @Trace openId: string = '';
  // 观澜问卷用户id
  @Trace WQIId:string = '';
  // 未命名问卷 id
  @Trace unnamedSurveyId: number = 1;
}

// 外观数据中心
@ObservedV2
export class AppAppearanceViewModel {
  // 壁纸
  @Trace staticWallpaper: string = '';
  // 壁纸 id
  @Trace staticWallpaperId: number = 1;
  // 是否开启组件高斯模糊
  @Trace isComponentBlur: boolean = false;
  // 组件高斯模糊
  @Trace componentBlur: number = 20;
  // 是否显示全部的按钮控件
  @Trace isButtonsShow: boolean = true;
  // 是否显示侧边栏按钮，是否显示扫一扫按钮，是否显示搜索按钮，是否显示设置按钮，是否开启智感握持
  @Trace isSideBarButtonShow: boolean = true;
  @Trace isScanButtonShow: boolean = true;
  @Trace isSearchButtonShow: boolean = true;
  @Trace isSettingButtonShow: boolean = true;
  // 是否开启智感握持
  @Trace isSmartGripDetection: boolean = false;
}

// 通用设置数据中心
@ObservedV2
export class AppGeneralViewModel {
  // 语言模式 id
  @Trace languageId: number = 0;
  // 语言模式文本
  @Trace language: string = i18n.System.getSystemLanguage();
  // 深浅色模式 id
  @Trace colorModeId: number = 0;
  // 是否开启震动反馈
  @Trace isHapticFeedback: boolean = false;
  // 按钮震感，滑动震感，列表项震感，菜单项震感
  @Trace isHapticButton: boolean = false;
  @Trace isHapticSwipe: boolean = false;
  @Trace isHapticListItem: boolean = false;
  @Trace isHapticMenu: boolean = false;
}

// 暂存数据中心
@ObservedV2
export class AppTmpViewModel {
  // 是否有网
  @Trace isNetwork: boolean = false;
  // 当前握持手
  @Trace holdingHandStatus: motion.HoldingHandStatus = motion.HoldingHandStatus.NOT_HELD;
  // 是否正在系统分享
  @Trace isSystemShare: boolean = false;
  // 当前系统分享图片uri
  @Trace systemShareImgUri: string = '';
  // 是否开启应用接续
  @Trace isContinue: boolean = false;
  // 接续的侧边栏索引值
  @Trace continueSideBarIndex: number = 0;
  // 接续的模板问卷 id
  @Trace marketSurveyId: string = '';
  // 接续的check问卷 id
  @Trace checkSurveyId: string = '';
  @Trace isContinueCreate: boolean = false;
}

