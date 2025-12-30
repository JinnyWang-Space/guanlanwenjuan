export class WidthBreakpointType<T> {
  xs?:T;
  sm: T;
  md: T;
  lg: T;
  xl?:T;
  xxl?:T;

  constructor(sm: T, md: T, lg: T) {
    this.sm = sm;
    this.md = md;
    this.lg = lg;
  }

  getValue(widthBp: WidthBreakpoint): T {
    if (widthBp === WidthBreakpoint.WIDTH_XS || widthBp === WidthBreakpoint.WIDTH_SM) {
      return this.sm;
    }
    if (widthBp === WidthBreakpoint.WIDTH_MD) {
      return this.md;
    } else {
      return this.lg;
    }
  }
}