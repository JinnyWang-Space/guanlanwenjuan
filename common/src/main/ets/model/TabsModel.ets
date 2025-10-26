export class TabsModel{
  id:number;
  label:Resource;
  icon:Resource;

  constructor(id: number, label: Resource, icon: Resource) {
    this.id = id;
    this.label = label;
    this.icon = icon;
  }

}