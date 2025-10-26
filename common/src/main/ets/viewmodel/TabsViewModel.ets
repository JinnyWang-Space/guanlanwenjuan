import { TabsModel } from "../model/TabsModel";

export class TabsViewModel {
  tabsViewModel: TabsModel[] = [
    new TabsModel(0, $r('app.string.tab_bar_home'), $r('sys.symbol.house_fill')),
    // new TabsModel(1, $r('app.string.tab_bar_select'), $r('sys.symbol.checkmark_clipboard_fill')),
    new TabsModel(1, $r('app.string.tab_bar_mine'), $r('sys.symbol.person_crop_circle_fill_1'))
  ]
}