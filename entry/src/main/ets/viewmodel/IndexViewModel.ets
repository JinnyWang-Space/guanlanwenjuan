import { DistributedDB, Survey, SurveyStatus, WindowUtil } from "common";
import { ShowListViewModel } from "./ShowListViewModel";
import { SideBarListViewModel } from "./SideBarListViewModel";
import { common } from "@kit.AbilityKit";
import { AppStorageV2, window } from "@kit.ArkUI";

// 创建窗口实例
let windowStage: window.WindowStage;

@ObservedV2
export class IndexViewModel {
  // 状态管理
  @Trace isShowSideBar: boolean = false;
  @Trace sideBarMainIndex: number = 0;
  @Trace refresh: boolean = false;
  @Trace surveys: Survey[] = [];
  // 私有属性
  @Trace windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;


  // 依赖注入
  // constructor(windowUtil: WindowUtil) {
  //   this.windowUtil = windowUtil;
  // }

}