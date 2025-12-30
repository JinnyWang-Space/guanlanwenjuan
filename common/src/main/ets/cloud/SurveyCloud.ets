import { cloudDatabase } from '@kit.CloudFoundationKit';
import { SurveyStatus } from '../model/Survey';

export class SurveyCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Survey";
  }

  id: string = '';
  // 问卷名
  title: string = '';
  // 问卷描述
  description: string = '';
  // 问卷创建时间
  created_time: Date = new Date;
  // 问卷状态
  status: string = '';
  // 发布时间
  published_time: Date = new Date;
  // 关闭时间
  closed_time: Date = new Date;
  // 是否删除
  deleted: boolean = false;
}

export class SurveyDescription extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "SurveyDescription";
  }

  id: string = '';
  // 问卷 id
  survey_id: string = '';
  // 问卷描述切片
  description_part: string = '';
}

export class QuestionCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Question";
  }

  // 问题 id
  id: string = '';
  // 问题对应的问卷 id
  survey_id: string = '';
  // 问题类型
  type: string = '';
  // 问题
  content: string = '';
  // 选项或文本
  options: string = '';
  // 是否必填
  required: boolean = true;
}

export class OptionCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Option";
  }

  // 问卷对应的问题选项 id
  id: string = '';
  // 问卷对应的问题 id
  question_id: string = '';
  // 选项片段
  option_part: string = '';
}

export class SubmissionCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Submission";
  }

  // 问题 id
  id: string = '';
  // 问题对应的问卷 id
  survey_id: string = '';
  // 开始时间
  begin_time: Date = new Date;
  // 提交时间
  submit_time: Date = new Date;
  // 答题时长
  duration_seconds: number = 0;
  // 设备 id
  device_id: string = '';
  // ip 地址
  ip_address: string = ''
}

export class AnswerCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Answer";
  }

  // 问题 id
  id: string = '';
  // 提交记录表 id
  submission_id: string = '';
  // 问题 id
  question_id: string = '';
  // 单选或文本
  answer_value: string = '';
  // 多选
  answer_options: string = '';
  // 创建时间
  created_time: Date = new Date;
}