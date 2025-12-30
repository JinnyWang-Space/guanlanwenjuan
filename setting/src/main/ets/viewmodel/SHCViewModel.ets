import { SNListItemModel } from "../model/SNModel";

export class SHCViewModel {
  // 控制按钮
  private buttonsList: SNListItemModel[] = [
    // 控制按钮总操作块
    new SNListItemModel('haptic_all',
      $r('app.string.list_shc_list_title_button_text'),
      $r('app.string.list_shc_button_all_text'),
      true,
      true),
    // 侧边栏按钮
    new SNListItemModel('haptic_button',
      $r('app.string.list_shc_list_title_button_text'),
      $r('app.string.list_shc_button_sidebar_text'),
      true,
      true),
    // 搜索按钮
    new SNListItemModel('haptic_swipe',
      $r('app.string.list_shc_list_title_button_text'),
      $r('app.string.list_shc_button_search_text'),
      true,
      true),
    // 扫一扫按钮
    new SNListItemModel('haptic_list_item',
      $r('app.string.list_shc_list_title_button_text'),
      $r('app.string.list_shc_button_scan_text'),
      true,
      true),
    // 设置按钮
    new SNListItemModel('haptic_list_item',
      $r('app.string.list_shc_list_title_button_text'),
      $r('app.string.list_shc_haptic_settings_text'),
      true,
      false)
  ];

  // 获取所有列表数据（返回副本防止外部修改）
  getButtonsList(): SNListItemModel[] {
    return [...this.buttonsList];
  };
}