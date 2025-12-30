import { ListItemModel } from "common";

export class SettingsListItemModel extends ListItemModel{
  id:string;
  list_title:Resource;

  constructor(id:string,list_title:Resource,label: Resource, isDivider: boolean) {
    super(label, isDivider);
    this.id = id;
    this.list_title = list_title;
  }
}