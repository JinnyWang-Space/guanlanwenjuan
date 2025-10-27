// beans/Survey.ts
@ObservedV2
export class Survey {
  id?: number = undefined;
  title: string = '';
  description: string = '';
  @Trace questions: Array<Question> = [];
  createdTime: number = Date.now();
}

@ObservedV2
export class Question {
  id: string = '';
  type: QuestionType = QuestionType.SINGLE_CHOICE;
  content: string = '';
  @Trace options: Array<string> = ['选项1', '选项2'];
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
