import { SNListItemModel } from "../model/SNModel";

export class SNViewModel {
  // 触感反馈
  private hapticList: SNListItemModel[] = [
    // 触感反馈总操作块
    new SNListItemModel('haptic_all',
      $r('app.string.list_sn_list_title_haptic_text'),
      $r('app.string.list_sn_haptic_all_text'),
      true,
      true),
    // 按钮触感
    new SNListItemModel('haptic_button',
      $r('app.string.list_sn_list_title_haptic_text'),
      $r('app.string.list_sn_haptic_button_text'),
      true,
      true),
    // 滑动触感
    new SNListItemModel('haptic_swipe',
      $r('app.string.list_sn_list_title_haptic_text'),
      $r('app.string.list_sn_haptic_swipe_text'),
      true,
      true),
    // 列表项触感
    new SNListItemModel('haptic_list_item',
      $r('app.string.list_sn_list_title_haptic_text'),
      $r('app.string.list_sn_haptic_list_item_text'),
      true,
      true),
    // 菜单触感
    new SNListItemModel('haptic_menu',
      $r('app.string.list_sn_list_title_haptic_text'),
      $r('app.string.list_sn_haptic_menu_text'),
      true,
      false),
  ];

  // 获取所有列表数据（返回副本防止外部修改）
  getHapticList(): SNListItemModel[] {
    return [...this.hapticList];
  };
}