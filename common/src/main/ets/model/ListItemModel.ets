@ObservedV2
export class ListItemModel {
  label: Resource;
  @Trace isDivider: boolean;

  constructor(label: Resource, isDivider: boolean) {
    this.label = label;
    this.isDivider = isDivider;
  }
}