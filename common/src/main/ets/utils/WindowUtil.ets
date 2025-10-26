import { window } from "@kit.ArkUI";

export enum ImmersiveType {
  NORMAL,
  IMMERSIVE,
  FULLSCREEN_IMMERSIVE
}

export class WindowUtil {
  public uiContext?: UIContext;
  public mainWindow: window.Window;
  public mainWindowInfo: WindowInfo = new WindowInfo();
  public onStatusTypeChange: (statusType: window.WindowStatusType) => void = (statusType: window.WindowStatusType) => {
    this.mainWindowInfo
  }
  public onWindowSizeChange: (windowSize: window.Size) => void = (windowSize: window.Size) => {
    this.mainWindowInfo!.windowSize = windowSize;
    this.mainWindowInfo!.widthBp = this.uiContext!.getWindowWidthBreakpoint();
    this.mainWindowInfo!.heightBp = this.uiContext!.getWindowHeightBreakpoint();
  }
  public onAvoidAreaChange: (avoidOptions: window.AvoidAreaOptions) => void =
    (avoidOptions: window.AvoidAreaOptions) => {
      if (avoidOptions.type === window.AvoidAreaType.TYPE_SYSTEM) {
        this.mainWindowInfo.AvoidSystem = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_CUTOUT) {
        this.mainWindowInfo.AvoidCutout = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_SYSTEM_GESTURE) {
        this.mainWindowInfo.AvoidSystemGesture = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_KEYBOARD) {
        this.mainWindowInfo.AvoidKeyboard = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        this.mainWindowInfo.AvoidNavigationIndicator = avoidOptions.area;
      }
    }

  constructor(mainWindow: window.Window) {
    this.mainWindow = mainWindow;
  }

  setImmersiveType(type: ImmersiveType) {
    if (type === ImmersiveType.NORMAL) {
      this.mainWindow.setWindowLayoutFullScreen(false)
        .then(() => {

        })
        .catch(() => {

        })

    } else if (type === ImmersiveType.IMMERSIVE) {
      this.mainWindow.setWindowLayoutFullScreen(true);
      this.mainWindow.setWindowDecorVisible(false);
      this.mainWindow.setWindowDecorHeight(64);
    } else if (type === ImmersiveType.FULLSCREEN_IMMERSIVE) {

    }
    this.mainWindowInfo.isImmersive = type
  }

  setUIContext() {
    this.uiContext = this.mainWindow.getUIContext();
  }

  updateWindowInfo(): void {
    let width: number = this.mainWindow.getWindowProperties().windowRect.width;
    let height: number = this.mainWindow.getWindowProperties().windowRect.height;
    let windowSize: window.Size = {
      width: width,
      height: height
    };
    this.mainWindowInfo.windowSize = windowSize;
    this.mainWindowInfo.widthBp = this.uiContext!.getWindowWidthBreakpoint();
    this.mainWindowInfo.heightBp = this.uiContext!.getWindowHeightBreakpoint();
    this.mainWindow.on('windowSizeChange', this.onWindowSizeChange);

    this.mainWindowInfo.AvoidSystem = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    this.mainWindowInfo.AvoidNavigationIndicator =
      this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    this.mainWindowInfo.AvoidCutout = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
    this.mainWindowInfo.AvoidSystemGesture =
      this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
    this.mainWindowInfo.AvoidKeyboard = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
    this.mainWindow.on('avoidAreaChange', this.onAvoidAreaChange);
  }

  release(): void {
    this.mainWindow.off('windowSizeChange');
    this.mainWindow.off('avoidAreaChange');
  }
}

@ObservedV2
export class WindowInfo {
  // 沉浸式模式
  @Trace isImmersive: ImmersiveType = ImmersiveType.NORMAL;
  // 窗口尺寸
  @Trace windowSize: window.Size = { width: 0, height: 0 };
  // 窗口断点
  @Trace widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_XS;
  @Trace heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
  // 避让区域
  // 状态栏区域
  @Trace AvoidSystem?: window.AvoidArea;
  // 底部导航栏区域
  @Trace AvoidNavigationIndicator?: window.AvoidArea;
  // 刘海屏区域
  @Trace AvoidCutout?: window.AvoidArea;
  // 手势区域
  @Trace AvoidSystemGesture?: window.AvoidArea;
  // 软键盘区域
  @Trace AvoidKeyboard?: window.AvoidArea;
}