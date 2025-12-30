import { cloudDatabase } from '@kit.CloudFoundationKit';

export class MarketCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "TemplateCategories";
  }

  // 模块 id
  id: string = '';
  // 模块名
  name: string = '';
  // 模块描述
  description: string = '';
}

export class SurveyTemplate extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "SurveyTemplate";
  }

  // 模板问卷 id
  id: string = '';
  // 所属模块 id
  category_id: string = '';
  // 模板问卷名称
  title: string = '';
  // 模板问卷描述
  description: string = '';
  // 模板问卷描述（英文）
  description_en: string = '';
  // 模板问卷使用数量
  usage_count: number = 0;
}

export class QuestionTemplate extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "QuestionTemplate";
  }

  // 模板问卷对应的问题 id
  id: string = '';
  // 模板问卷 id
  template_id: string = '';
  // 问题类型
  type: string = '';
  // 问题
  content: string = '';
  // 问题（英文）
  content_en: string = '';
  // 选项或文本
  options: string = '';
  // 选项或文本（英文）
  options_en: string = '';
  // 是否必填
  is_required: number = 0;
}

export class SurveyDescriptionTemplate extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "SurveyDescriptionTemplate";
  }

  // 模板问卷对应的问题 id
  id: string = '';
  // 模板问卷 id
  template_id: string = '';
  // 中文描述
  description_part_zh: string = '';
  // 英文描述
  description_part_en: string = '';
}

export class OptionTemplate extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "OptionTemplate";
  }

  // 模板问卷对应的问题选项 id
  id: string = '';
  // 模板问卷对应的问题 id
  template_question_id: string = '';
  // 中文描述
  option_part_zh: string = '';
  // 英文描述
  option_part_en: string = '';
}