import { ListItemModel } from "common";

@ObservedV2
export class SHCListItemModel extends ListItemModel {
  id: string;
  list_title: Resource;
  @Trace is_on: boolean;

  constructor(id: string, list_title: Resource, label: Resource, is_on: boolean, isDivider: boolean) {
    super(label, isDivider);
    this.id = id;
    this.list_title = list_title;
    this.is_on = is_on;
  }
}