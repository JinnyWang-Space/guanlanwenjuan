import { ShowListModel } from "../model/ShowListModel";

export class ShowListViewModel {
  mainVM: ShowListModel[] = [
    new ShowListModel(0, '添加问卷', '0'),
    new ShowListModel(0, '未知名问卷', '22分钟前')
  ]
}