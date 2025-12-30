// 验证工具类
export class ValidatorUtils {
  // 手机号正则（中国大陆）
  private static readonly PHONE_REGEX = /^(?:(?:\+|00)86)?1[3-9]\d{9}$/;

  // 邮箱正则（通用）
  private static readonly EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  // 更严格的邮箱正则
  private static readonly STRICT_EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  // 验证手机号
  static isPhoneNumber(text: string): boolean {
    if (!text || text.trim() === '') return false;
    return ValidatorUtils.PHONE_REGEX.test(text.trim());
  }

  // 验证邮箱
  static isEmail(text: string): boolean {
    if (!text || text.trim() === '') return false;
    return ValidatorUtils.STRICT_EMAIL_REGEX.test(text.trim());
  }

  // 判断输入类型
  static getInputType(text: string): 'phone' | 'email' | 'unknown' {
    if (ValidatorUtils.isPhoneNumber(text)) {
      return 'phone';
    } else if (ValidatorUtils.isEmail(text)) {
      return 'email';
    }
    return 'unknown';
  }
}