@ObservedV2
export class Survey {
  id?: number = undefined;
  // 问卷名
  title: string = '';
  // 问卷描述
  description: string = '';
  // 问卷中的问题数组
  @Trace questions: Question[] = [];
  // 问卷创建时间
  createdTime: number = Date.now();
  // 问卷状态
  status: SurveyStatus = SurveyStatus.DRAFT;
  // 发布时间
  publishedTime?: number = undefined;
  // 关闭时间
  closedTime?: number = undefined;
  // 是否删除
  deleted: boolean = false;
  id_cloud:string=  '';
}

@ObservedV2
export class Question {
  id: string = '';
  // 问题类型
  type: QuestionType = QuestionType.SINGLE_CHOICE;
  // 问题
  content: string = '';
  // 选项
  @Trace options: string[] = [];
  // 是否必答
  required: boolean = false;

  constructor() {
    this.id = this.generateId();
  }

  // 生成唯一ID
  private generateId(): string {
    return 'q_' + Date.now() + '_' + Math.floor(Math.random() * 10000).toString();
  }
}

export enum QuestionType {
  // SINGLE_CHOICE = 'Single',     // 单选题
  // MULTIPLE_CHOICE = 'Multiple', // 多选题
  // TEXT_ANSWER = 'Text'          // 文本题
  SINGLE_CHOICE = '单选', // 单选题
  MULTIPLE_CHOICE = '多选', // 多选题
  TEXT_ANSWER = '文本' // 文本题
}

export enum SurveyStatus {
  DRAFT = 'draft', //未收集
  COLLECTING = 'collecting', // 正在收集
  CLOSED = 'closed' // 收集完成
}

@ObservedV2
export class Submission {
  id: string = '';
  survey_id:string = '';
}

@ObservedV2
export class Answer {
  id: string = '';
  // 提交表 id
  submission_id: string = '';
  // 问题 id
  question_id: string = '';
  // 选择题或文本
  answer_value: string = '';
  // 多选
  answer_options: string[] = [];
}