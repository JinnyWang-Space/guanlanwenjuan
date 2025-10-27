// import { relationalStore } from '@kit.ArkData'
// import { Survey } from '../model/Survey';
//
//
// export class Rdb {
//   private static instance: Rdb = new Rdb();
//   private rdbStore: relationalStore.RdbStore | undefined = undefined;
//   // 数据库配置
//   private readonly STORE_CONFIG: relationalStore.StoreConfig = {
//     name: 'SurveyDB.db',
//     securityLevel: relationalStore.SecurityLevel.S1
//   }
//   // SQL 语句
//   private readonly CREATE_SURVEY_TABLE = `
//     CREATE TABLE IF NOT EXISTS surveys (
//       id INTEGER PRIMARY KEY AUTOINCREMENT,
//       title TEXT NOT NULL,
//       description TEXT,
//       created_time INTEGER NOT NULL
//     )`;
//   private readonly CREATE_QUESTIONS_TABLE = `
//     CREATE TABLE IF NOT EXISTS questions (
//       id INTEGER PRIMARY KEY AUTOINCREMENT,
//       survey_id INTEGER NOT NULL,
//       type TEXT NOT NULL,
//       content TEXT NOT NULL,
//       options TEXT NOT NULL,
//       required INTEGER NOT NULL DEFAULT 0,
//       FOREIGN KEY (survey_id) REFERENCES surveys (id) ON DELETE CASCADE
//     )`;
//
//   public static getInstance(): Rdb {
//     return Rdb.instance;
//   }
//
//   // 初始化数据库
//   async initDatabase(context:Context): Promise<void> {
//     try {
//       this.rdbStore = await relationalStore.getRdbStore(context, this.STORE_CONFIG);
//       await this.rdbStore.executeSql(this.CREATE_SURVEY_TABLE);
//       await this.rdbStore.executeSql(this.CREATE_QUESTIONS_TABLE);
//       console.info('Database initialized successfully');
//     } catch (error) {
//       console.error('Failed to initialize database:', JSON.stringify(error));
//     }
//   }
//
//   // 保存问卷
//   async saveSurvey(survey: Survey): Promise<number> {
//     if (!this.rdbStore) {
//       return;
//     }
//
//     try {
//       await this.rdbStore.beginTransaction();
//
//       const valueBucket: relationalStore.ValuesBucket = {
//         'title': survey.title,
//         'description': survey.description,
//         'created_time': survey.createdTime
//       };
//
//       const surveyId: number = await this.rdbStore.insert('surveys', valueBucket);
//
//       for (let i: number = 0; i < survey.questions.length; i++) {
//         const question: Question = survey.questions[i];
//         const questionBucket: relationalStore.ValuesBucket = {
//           'survey_id': surveyId,
//           'type': question.type,
//           'content': question.content,
//           'options': JSON.stringify(question.options),
//           'required': question.required ? 1 : 0
//         };
//         await this.rdbStore.insert('questions', questionBucket);
//       }
//
//       await this.rdbStore.commit();
//       return surveyId;
//
//     } catch (error) {
//       await this.rdbStore.rollback();
//       console.error('Failed to save survey:', JSON.stringify(error));
//       throw error;
//     }
//   }
//
//   async getAllSurveys(): Promise<Array<Survey>> {
//     if (!this.rdbStore) {
//       await this.initDatabase();
//     }
//
//     try {
//       const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
//       const columns: Array<string> = ['id', 'title', 'description', 'created_time'];
//       const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, columns);
//
//       const surveys: Array<Survey> = [];
//       let isGoToNextRow: boolean = resultSet.goToNextRow();
//       while (isGoToNextRow) {
//         const survey: Survey = new Survey();
//         survey.id = resultSet.getLong(resultSet.getColumnIndex('id'));
//         survey.title = resultSet.getString(resultSet.getColumnIndex('title'));
//         survey.description = resultSet.getString(resultSet.getColumnIndex('description'));
//         survey.createdTime = resultSet.getLong(resultSet.getColumnIndex('created_time'));
//         surveys.push(survey);
//         isGoToNextRow = resultSet.goToNextRow();
//       }
//
//       resultSet.close();
//       return surveys;
//     } catch (error) {
//       console.error('Failed to get surveys:', JSON.stringify(error));
//       return [];
//     }
//   }
//
//   async getSurveyById(surveyId: number): Promise<Survey | null> {
//     if (!this.rdbStore) {
//       await this.initDatabase();
//     }
//
//     try {
//       const surveyPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
//       surveyPredicates.equalTo('id', surveyId);
//       const surveyColumns: Array<string> = ['id', 'title', 'description', 'created_time'];
//       const surveyResult: relationalStore.ResultSet = await this.rdbStore.query(surveyPredicates, surveyColumns);
//
//       if (!surveyResult.goToFirstRow()) {
//         surveyResult.close();
//         return null;
//       }
//
//       const survey: Survey = new Survey();
//       survey.id = surveyResult.getLong(surveyResult.getColumnIndex('id'));
//       survey.title = surveyResult.getString(surveyResult.getColumnIndex('title'));
//       survey.description = surveyResult.getString(surveyResult.getColumnIndex('description'));
//       survey.createdTime = surveyResult.getLong(surveyResult.getColumnIndex('created_time'));
//       surveyResult.close();
//
//       const questionPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
//       questionPredicates.equalTo('survey_id', surveyId);
//       const questionColumns: Array<string> = ['id', 'type', 'content', 'options', 'required'];
//       const questionResult: relationalStore.ResultSet = await this.rdbStore.query(questionPredicates, questionColumns);
//
//       let isGoToNextRow: boolean = questionResult.goToNextRow();
//       while (isGoToNextRow) {
//         const question: Question = new Question();
//         question.id = questionResult.getLong(questionResult.getColumnIndex('id')).toString();
//         question.type = questionResult.getString(questionResult.getColumnIndex('type')) as QuestionType;
//         question.content = questionResult.getString(questionResult.getColumnIndex('content'));
//         question.required = questionResult.getLong(questionResult.getColumnIndex('required')) === 1;
//
//         const optionsJson: string = questionResult.getString(questionResult.getColumnIndex('options'));
//         question.options = JSON.parse(optionsJson) as Array<string>;
//
//         survey.questions.push(question);
//         isGoToNextRow = questionResult.goToNextRow();
//       }
//
//       questionResult.close();
//       return survey;
//
//     } catch (error) {
//       console.error('Failed to get survey by id:', JSON.stringify(error));
//       return null;
//     }
//   }
//
//   async deleteSurvey(surveyId: number): Promise<boolean> {
//     if (!this.rdbStore) {
//       await this.initDatabase();
//     }
//
//     try {
//       await this.rdbStore.beginTransaction();
//
//       const questionPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
//       questionPredicates.equalTo('survey_id', surveyId);
//       await this.rdbStore.delete(questionPredicates);
//
//       const surveyPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
//       surveyPredicates.equalTo('id', surveyId);
//       const deletedRows: number = await this.rdbStore.delete(surveyPredicates);
//
//       await this.rdbStore.commit();
//       return deletedRows > 0;
//
//     } catch (error) {
//       await this.rdbStore.rollback();
//       console.error('Failed to delete survey:', JSON.stringify(error));
//       return false;
//     }
//   }
//
//   async updateSurvey(survey: Survey): Promise<boolean> {
//     if (!this.rdbStore || survey.id === undefined) {
//       return false;
//     }
//
//     try {
//       await this.rdbStore.beginTransaction();
//
//       const valueBucket: relationalStore.ValuesBucket = {
//         'title': survey.title,
//         'description': survey.description
//       };
//
//       const surveyPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
//       surveyPredicates.equalTo('id', survey.id);
//       await this.rdbStore.update(valueBucket, surveyPredicates);
//
//       const deleteQuestionPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
//       deleteQuestionPredicates.equalTo('survey_id', survey.id);
//       await this.rdbStore.delete(deleteQuestionPredicates);
//
//       for (let i: number = 0; i < survey.questions.length; i++) {
//         const question: Question = survey.questions[i];
//         const questionBucket: relationalStore.ValuesBucket = {
//           'survey_id': survey.id,
//           'type': question.type,
//           'content': question.content,
//           'options': JSON.stringify(question.options),
//           'required': question.required ? 1 : 0
//         };
//         await this.rdbStore.insert('questions', questionBucket);
//       }
//
//       await this.rdbStore.commit();
//       return true;
//
//     } catch (error) {
//       await this.rdbStore.rollback();
//       console.error('Failed to update survey:', JSON.stringify(error));
//       return false;
//     }
//   }
//
// }