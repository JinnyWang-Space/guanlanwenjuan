import { Survey, SurveyStatus } from "common";
import { ShowListModel } from "../model/ShowListModel";

@ObservedV2
export class ShowListViewModel {
  mainVM: ShowListModel[] = [
    new ShowListModel(0, '添加问卷', '0'),
    // new ShowListModel(0, $r('app.string.create_survey'), '0'),
  ]
}