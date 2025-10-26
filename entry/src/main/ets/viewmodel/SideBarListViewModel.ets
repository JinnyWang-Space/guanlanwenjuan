import { SideBarListModel } from "../model/SideBarListModel";

export class SideBarListViewModel{
  mainVM:SideBarListModel[] = [
    new SideBarListModel(0,$r('app.string.side_bar_all'),$r('sys.symbol.doc_plaintext'),0),
    new SideBarListModel(1,$r('app.string.side_bar_collecting'),$r('sys.symbol.doc_plaintext_and_pencil'),0),
    new SideBarListModel(2,$r('app.string.side_bar_collected'),$r('sys.symbol.checkmark_clipboard'),0),
    new SideBarListModel(3,$r('app.string.side_bar_no_collect'),$r('sys.symbol.doc'),0),
    new SideBarListModel(4,$r('app.string.side_bar_delete'),$r('sys.symbol.trash'),0)
  ]
}