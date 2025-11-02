import { ShowListModel } from "../model/ShowListModel";

export class ShowListViewModel {
  mainVM: ShowListModel[] = [
    new ShowListModel(0, '添加问卷', '0'),
  ]
  marketVM: ShowListModel[] = [
    new ShowListModel(0, '大学生学习习惯与学业压力调查', '0'),
    new ShowListModel(1, '校园生活满意度与社团活动参与度调查', '0'),
    new ShowListModel(2, '食堂服务与校园餐饮需求调查', '0'),
    new ShowListModel(3, '大学生职业规划与就业指导需求调查', '0')
  ]
}