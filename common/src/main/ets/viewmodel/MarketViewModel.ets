import { Question, QuestionType, Survey, SurveyStatus } from "../../../../Index";

class MarketSurveyModel extends Survey {
  id?: number = undefined;
  // 问卷名
  title: string = '';
  // 问卷描述
  description: string = '';
  // 问卷中的问题数组
  questions: Question[] = [];
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

  constructor(id: number, title: string, description: string, questions: Question[], createdTime: number,
    status: SurveyStatus, publishedTime: number, closedTime: number, deleted: boolean) {
    super();
    this.id = id;
    this.title = title;
    this.description = description;
    this.questions = questions;
    this.createdTime = createdTime;
    this.status = status;
    this.publishedTime = publishedTime;
    this.closedTime = closedTime;
    this.deleted = deleted;
  }
}

class MarketQuestionModel extends Question {
  id: string = '';
  // 问题类型
  type: QuestionType = QuestionType.SINGLE_CHOICE;
  // 问题
  content: string = '';
  // 选项
  options: string[] = ['选项1', '选项2'];
  // 是否必答
  required: boolean = false;

  constructor(id: string, type: QuestionType, content: string, options: string[], required: boolean) {
    super();
    this.id = id;
    this.type = type;
    this.content = content;
    this.options = options;
    this.required = required;
  }
}

export class SurveyViewModel {
  marketSurvey: MarketSurveyModel[] = [
    new MarketSurveyModel(0, '大学生学习习惯与学业压力调查',
      '亲爱的同学，你好！为了更好地了解大家的学习习惯和面临的学业压力，我们开展了此次匿名问卷调查。你的宝贵意见将有助于学校和相关机构提供更有针对性的支持。问卷大约需要3-5分钟，感谢你的参与！',
      [
        new MarketQuestionModel('0', QuestionType.SINGLE_CHOICE, '你平均每天用于自主学习（不包括上课）的时间是？',
          ['1小时以下', '1-2小时', '2-4小时', '4小时以上'], true),
        new MarketQuestionModel('1', QuestionType.SINGLE_CHOICE, '你认为当前你的学业压力主要来源于？',
          ['课程难度与考试', '未来就业或升学', ' 同辈竞争', '自我期望', '其他'], true),
        new MarketQuestionModel('2', QuestionType.MULTIPLE_CHOICE, '你通常使用哪些方式来提升学习效率？（可多选）',
          ['制定详细的学习计划', '使用思维导图等工具', '与同学组成学习小组', '利用图书馆或在线资源（如MOOC）',
            '使用番茄工作法等时间管理法', '基本不采用特殊方法'], true),
        new MarketQuestionModel('3', QuestionType.SINGLE_CHOICE,
          '你认为学校的现有图书馆/自习室资源能够满足你的学习需求。', ['是', '否'], true),
        new MarketQuestionModel('4', QuestionType.TEXT_ANSWER,
          '为了帮助你更好地学习，你希望学校或学院在哪些方面提供更多的支持或资源？（例如：讲座辅导、学习空间、软件工具等）', [],
          true),
      ]
      , 0, SurveyStatus.DRAFT, 0, 0, false),
    new MarketSurveyModel(1, '校园生活满意度与社团活动参与度调查',
      '嗨，同学！丰富多彩的校园生活是大学记忆的重要组成部分。我们希望通过这份问卷，了解你对校园生活各方面的满意度以及参与社团活动的情况，以便未来能组织更符合大家兴趣的活动。你的反馈至关重要！',
      [
        new MarketQuestionModel('0', QuestionType.SINGLE_CHOICE, ' 总体上，你对当前的校园生活感到满意吗？',
          ['非常满意', '比较满意', '一般', '不太满意', '非常不满意'], true),
        new MarketQuestionModel('1', QuestionType.SINGLE_CHOICE, ' 你主要通过哪些途径了解校园活动信息？（可多选）',
          ['学校官方微信公众号/网站', '宿舍楼下海报/宣传栏', '班级/年级群通知', '社团自身宣传', '同学/朋友告知',
            '基本不关注'], true),
        new MarketQuestionModel('2', QuestionType.SINGLE_CHOICE, '你是否加入了至少一个学生社团或学生组织？',
          ['是', '否'], true),
        new MarketQuestionModel('3', QuestionType.SINGLE_CHOICE, '（接上题）你参与所加入社团活动的频率是？',
          ['非常频繁，几乎每次活动都参加', '比较频繁，经常参加', '一般，偶尔参加', '很少参加'], true),
        new MarketQuestionModel('4', QuestionType.SINGLE_CHOICE,
          '你认为目前校园文化活动最需要在哪方面进行改进？（例如：活动类型、宣传方式、时间安排等）请提出你的宝贵建议。',
          [], true),
      ]
      , 0, SurveyStatus.DRAFT, 0, 0, false),
    new MarketSurveyModel(2, '食堂服务与校园餐饮需求调查',
      '“民以食为天”，食堂是我们在校生活的重要一环。为了收集同学们对食堂菜品、价格、服务及环境的意见，我们特此展开调查。你的每一个回答都将帮助我们向相关部门反映诉求，共同打造更满意的校园餐饮体验。',
      [
        new MarketQuestionModel('0', QuestionType.SINGLE_CHOICE, '你平均每周在食堂就餐的频率是？',
          ['每天2-3餐', '每天1餐', '每周3-5餐', '每周1-2餐', '几乎不去'], true),
        new MarketQuestionModel('1', QuestionType.SINGLE_CHOICE, '你在选择食堂时，最看重哪些因素？（可多选）',
          ['菜品口味', '价格实惠', '营养健康', '就餐环境', '打饭速度/排队时长', '服务人员态度', '菜品多样性'], true),
        new MarketQuestionModel('2', QuestionType.SINGLE_CHOICE, '你认为当前食堂菜品的价格是合理的。',
          ['是', '否'], true),
        new MarketQuestionModel('3', QuestionType.SINGLE_CHOICE, '你对食堂的整体卫生状况评价如何？',
          ['非常干净', '比较干净', '一般', '不太干净', '非常不干净'], true),
        new MarketQuestionModel('4', QuestionType.SINGLE_CHOICE,
          '请写下你最希望食堂新增或改进的一道菜品/一种食品，并说明原因。',
          [], true),
      ]
      , 0, SurveyStatus.DRAFT, 0, 0, false),
    new MarketSurveyModel(3, '大学生职业规划与就业指导需求调查',
      '亲爱的同学，面对未来的职业生涯，你是否已有清晰的规划？为了给同学们提供更精准、有效的就业指导与服务，我们诚挚地邀请你参与本次调查。你的选择将帮助我们优化工作，助你更好地扬帆起航。',
      [
        new MarketQuestionModel('0', QuestionType.SINGLE_CHOICE, '你目前的职业规划清晰度如何？',
          ['有清晰的长远目标与计划', '有短期的方向，但长远目标模糊', '正在探索和思考中', '感到迷茫，没有明确方向'], true),
        new MarketQuestionModel('1', QuestionType.MULTIPLE_CHOICE, '你希望通过学校就业指导中心获得哪些服务？（可多选）',
          ['职业规划一对一咨询', '简历修改与面试技巧培训', '名企实习/校招信息推送', '行业分享会与校友经验交流',
            '职业技能（如办公软件、编程）培训', '考研/考公/出国留学指导'], true),
        new MarketQuestionModel('2', QuestionType.SINGLE_CHOICE,
          '你是否参加过学校组织的职业规划或就业指导相关讲座/活动？',
          ['是', '否'], true),
        new MarketQuestionModel('3', QuestionType.SINGLE_CHOICE, '你期望的第一份工作的最重要的因素是？',
          ['薪资待遇', '个人兴趣与发展空间', '行业前景', '工作地点与环境', '公司文化与稳定性'], true),
        new MarketQuestionModel('4', QuestionType.TEXT_ANSWER,
          '在求职或规划未来发展的过程中，你目前最大的困惑或挑战是什么？',
          [], true),

      ]
      , 0, SurveyStatus.DRAFT, 0, 0, false)
  ];
}