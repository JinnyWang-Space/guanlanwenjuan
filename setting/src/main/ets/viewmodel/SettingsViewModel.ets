import { SettingsListItemModel } from "../model/SettingsModel";

export class SettingsViewModel {
  // 服务列表
  private supportList: SettingsListItemModel[] = [
    // 意见反馈
    new SettingsListItemModel('feedback',
      $r('app.string.list_title_support_text'),
      $r('app.string.list_item_feedback_text'),
      false)
  ];
  // 数据列表
  private dataList: SettingsListItemModel[] = [
    // 账号管理
    new SettingsListItemModel('account',
      $r('app.string.list_title_data_text'),
      $r('app.string.list_item_account_text'),
      false),
  ];
  // 视觉列表
  private appearanceList: SettingsListItemModel[] = [
    // 背景
    new SettingsListItemModel('wallpaper',
      $r('app.string.list_title_appearance_text'),
      $r('app.string.list_item_wallpaper_text'),
      true),
    // 组件
    new SettingsListItemModel('component',
      $r('app.string.list_title_appearance_text'),
      $r('app.string.list_item_component_text'),
      true),
    // 控间显隐
    new SettingsListItemModel('show/hide components',
      $r('app.string.list_title_appearance_text'),
      $r('app.string.list_item_show_hide_components_text'),
      true),
    // 智感握持
    new SettingsListItemModel('smart grip detection',
      $r('app.string.list_title_appearance_text'),
      $r('app.string.list_item_holding_hand_text'),
      false)
  ];
  // 通用列表
  private generalList: SettingsListItemModel[] = [
    // 语言模式
    new SettingsListItemModel('language',
      $r('app.string.list_title_general_text'),
      $r('app.string.list_item_language_text'),
      true),
    // 深浅色模式
    new SettingsListItemModel('color mode',
      $r('app.string.list_title_general_text'),
      $r('app.string.list_item_color_mode_text'),
      true),
    // 音效与通知
    new SettingsListItemModel('sounds & notifications',
      $r('app.string.list_title_general_text'),
      $r('app.string.list_item_sounds_notifications_text'),
      false)
  ];
  // 指南列表
  private guideList: SettingsListItemModel[] = [
    // 使用提示
    new SettingsListItemModel('tips',
      $r('app.string.list_title_guide_text'),
      $r('app.string.list_item_tips_text'),
      true),
    // 更新日志
    new SettingsListItemModel('changelog',
      $r('app.string.list_title_guide_text'),
      $r('app.string.list_item_changelog_text'),
      false)
  ];
  // 关于列表
  private aboutList: SettingsListItemModel[] = [
    // 关于
    new SettingsListItemModel('about',
      $r('app.string.list_title_about_us_text'),
      $r('app.string.list_item_about_text'),
      true),
    // 隐私声明
    new SettingsListItemModel('privacy agreement',
      $r('app.string.list_title_about_us_text'),
      $r('app.string.list_item_privacy_agreement_text'),
      true),
    // 用户协议
    new SettingsListItemModel('user agreement',
      $r('app.string.list_title_about_us_text'),
      $r('app.string.list_item_user_agreement_text'),
      false)
  ];

  // 获取所有列表数据（返回副本防止外部修改）
  getSupportList(): SettingsListItemModel[] {
    return [...this.supportList];
  };

  getDataList(): SettingsListItemModel[] {
    return [...this.dataList];
  };

  getAppearanceList(): SettingsListItemModel[] {
    return [...this.appearanceList];
  };

  getGeneralList(): SettingsListItemModel[] {
    return [...this.generalList];
  };

  getGuideList(): SettingsListItemModel[] {
    return [...this.guideList];
  };

  getAboutList(): SettingsListItemModel[] {
    return [...this.aboutList];
  };
}