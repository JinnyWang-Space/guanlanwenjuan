@ObservedV2
export class AgreementViewModel {
  // 状态管理
  @Trace isLoading: boolean = true;
  @Trace currentUrl: string;
  // 私有属性
  private agreementId: number;
  private readonly privacyUrl: string =
    "https://www.jinnyspace.online/privacyAgreement";
  private readonly userUrl: string = "https://www.jinnyspace.online/userAgreement";

  constructor(agreementId: number) {
    this.agreementId = agreementId;
    this.currentUrl = this.getUrlByAgreementId();
  }

  // 根据协议 ID 获取 URL
  private getUrlByAgreementId(): string {
    return this.agreementId === 0 ? this.privacyUrl : this.userUrl;
  }

  // 页面开始加载
  onPageBegin(): void {
    this.isLoading = true;
  }

  // 页面加载完成
  onPageEnd(): void {
    this.isLoading = false;
  }

  // 获取协议标题
  get agreementTitle(): string {
    return this.agreementId === 0 ? '隐私声明' : '用户协议';
  }
}