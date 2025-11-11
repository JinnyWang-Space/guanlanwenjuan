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
  // 选项或文本
  options: string = '';
  // 是否必填
  is_required: number = 0;
}