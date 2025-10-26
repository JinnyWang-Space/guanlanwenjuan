export class SideBarListModel{
  id:number;
  label:Resource;
  symbol:Resource;
  count:number;

  constructor(id: number, label: Resource, symbol: Resource, count: number) {
    this.id = id;
    this.label = label;
    this.symbol = symbol;
    this.count = count;
  }
}