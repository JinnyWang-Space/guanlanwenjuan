import { ListItemModel } from "common";

@ObservedV2
export class TipsListItemModel extends ListItemModel {
  id: string;
  list_title: Resource;
  @Trace rotate_angle: number;

  constructor(id: string, list_title: Resource, label: Resource, rotate_angle: number, isDivider: boolean) {
    super(label, isDivider);
    this.id = id;
    this.list_title = list_title;
    this.rotate_angle = rotate_angle;
  }
}