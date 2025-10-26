export class ShowListModel {
  id: number;
  label: string;
  deltaT: string;

  constructor(id: number, label: string, deltaT: string) {
    this.id = id;
    this.label = label;
    this.deltaT = deltaT;
  }
}