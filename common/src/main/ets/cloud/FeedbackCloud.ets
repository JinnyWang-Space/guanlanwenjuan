import { cloudDatabase } from '@kit.CloudFoundationKit';

export class FeedbackCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Feedback";
  }

  // 意见反馈 id
  id: string = '';
  // 反馈类型
  type: string = '';
  // 联系方式类型
  contact_type: string = '';
  // 联系方式内容
  contact_content: string = '';
  // 设备类型
  device_type: string = '';
  // 设备名称
  device_content: string = '';
  // 设备sdk
  device_sdk: string = '';
}

export class FeedbackContentCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "FeedbackContent";
  }

  // 意见反馈内容 id
  id: string = '';
  // 内容对应的意见反馈 id
  feedback_id: string = '';
  // 反馈内容
  content: string = '';
}