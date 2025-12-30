import { TipsListItemModel } from "../model/TipsModel";

export class TipsViewModel {
  // 关于手势列表
  private gestureList: TipsListItemModel[] = [
    // 左划操作
    new TipsListItemModel('swipe_left',
      $r('app.string.list_tips_list_title_gesture_text'),
      $r('app.string.list_tips_gesture_swipe_left_text'),
      270,
      true),
    // 右划操作
    new TipsListItemModel('swipe_right',
      $r('app.string.list_tips_list_title_gesture_text'),
      $r('app.string.list_tips_gesture_swipe_right_text'),
      270,
      false)
  ];
  // 关于账号列表
  private accountList: TipsListItemModel[] = [
    // 账号管理
    // new TipsListItemModel('account',
    //   $r('app.string.list_title_data_text'),
    //   $r('app.string.list_item_account_text'),
    //   false),
  ];

  // 获取所有列表数据（返回副本防止外部修改）
  getGestureList(): TipsListItemModel[] {
    return [...this.gestureList];
  };

  getAccountList(): TipsListItemModel[] {
    return [...this.accountList];
  };
}