import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import Logger from '../utils/Logger';
import { RdbConstants } from '../constants/RdbConstants';
import { Question, QuestionType, Survey, SurveyStatus } from '../model/Survey';
import { BusinessError } from '@kit.BasicServicesKit';
import { distributedDeviceManager } from "@kit.DistributedServiceKit"

export class DistributedDB {
  private rdbStore: relationalStore.RdbStore | undefined = undefined;
  context: common.UIAbilityContext | null = null;
  localDeviceNetworkId: string = '';

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // 设置分布式同步表
  async setDistributedTables(context: Context) {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, RdbConstants.STORE_CONFIG);

      // 创建所有表
      await this.rdbStore.executeSql(RdbConstants.CREATE_SURVEY_TABLE);
      await this.rdbStore.executeSql(RdbConstants.CREATE_QUESTIONS_TABLE);

      Logger.error('[DistributedDB.setDistributedTables]', '成功')
    } catch (error) {
      Logger.error('[DistributedDB.setDistributedTables]', `Code:${error.code}, message: ${error.message}`);
    }
  }

  // 新增数据
  async saveSurvey(survey: Survey, isSync = true): Promise<number> {

    if (!this.rdbStore) {
      Logger.info('[saveSurvey]', 'saveSurvey() has no callback!');
      return -1;
    }

    try {
      const insertData: relationalStore.ValuesBucket = {
        'title': survey.title,
        'description': survey.description,
        'created_time': survey.createdTime,
        'status': survey.status,
        'published_time': survey.publishedTime!,
        'closed_time': survey.closedTime!,
        'deleted': survey.deleted ? 1 : 0,
        'id_cloud':survey.id_cloud
      };
      const surveyId: number = await this.rdbStore.insert('surveys', insertData);

      // if (isSync) {
      //   await this.syncData();
      // }

      for (let i = 0; i < survey.questions.length; i++) {
        const question = survey.questions[i];
        const questionBucket: relationalStore.ValuesBucket = {
          'survey_id': surveyId,
          'type': question.type,
          'content': question.content,
          'options': JSON.stringify(question.options),
          'required': question.required ? 1 : 0
        };
        await this.rdbStore.insert('questions', questionBucket);
      }

      Logger.error('[DistributedDB.insertData]', '成功')
      return surveyId;

    } catch (error) {
      Logger.error('[DistributedDB.insertData]', '失败')
      return -1;
    }
  }

  // 获取所有问卷数据（不包含问卷中的问题数据）
  async getAllSurveys(): Promise<Survey[]> {
    if (!this.rdbStore) {
      Logger.info('[getAllSurveys]', 'getAllSurveys() has no callback!');
      return [];
    }

    try {
      const predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates('surveys');
      const columns: string[] =
        ['id', 'title', 'description', 'created_time', 'status', 'published_time', 'closed_time', 'deleted',
          'id_cloud'];
      const resultSet: relationalStore.ResultSet =
        await this.rdbStore.query(predicates, columns);

      const surveys: Survey[] = [];
      while (resultSet.goToNextRow()) {
        const survey: Survey = new Survey();
        survey.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        survey.title = resultSet.getString(resultSet.getColumnIndex('title'));
        survey.description = resultSet.getString(resultSet.getColumnIndex('description'));
        survey.createdTime = resultSet.getLong(resultSet.getColumnIndex('created_time'));
        survey.status = resultSet.getString(resultSet.getColumnIndex('status')) as SurveyStatus;
        survey.publishedTime = resultSet.getLong(resultSet.getColumnIndex('published_time'));
        survey.closedTime = resultSet.getLong(resultSet.getColumnIndex('closed_time'));
        survey.deleted = resultSet.getLong(resultSet.getColumnIndex('deleted')) === 1;
        survey.id_cloud = resultSet.getString(resultSet.getColumnIndex('id_cloud'));
        surveys.push(survey);
      }
      resultSet.close();
      return surveys;
    } catch (error) {
      return [];
    }
  }

  // 根据 id 获取当前问卷的所有数据
  async getSurveyById(surveyId: number): Promise<Survey | null> {
    if (!this.rdbStore) {
      Logger.info('[getSurveyById]', 'getSurveyById() has no callback!');
      return null;
    }
    try {
      const surveyPredicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates('surveys');
      surveyPredicates.equalTo('id', surveyId);
      const surveyColumns: string[] =
        ['id', 'title', 'description', 'created_time', 'status', 'published_time', 'closed_time', 'deleted','id_cloud'];
      const surveyResult: relationalStore.ResultSet = await this.rdbStore.query(surveyPredicates, surveyColumns);

      // 不移到第一行会报错：14800012 ResultSet is empty or pointer index is out of bounds.
      // 调用该方法已自动移到第一行
      if (!surveyResult.goToFirstRow()) {
        surveyResult.close();
        return null;
      }

      const survey: Survey = new Survey();
      survey.id = surveyResult.getLong(surveyResult.getColumnIndex('id'));
      survey.title = surveyResult.getString(surveyResult.getColumnIndex('title'));
      survey.description = surveyResult.getString(surveyResult.getColumnIndex('description'));
      survey.createdTime = surveyResult.getLong(surveyResult.getColumnIndex('created_time'));
      survey.status = surveyResult.getString(surveyResult.getColumnIndex('status')) as SurveyStatus;
      survey.publishedTime = surveyResult.getLong(surveyResult.getColumnIndex('published_time'));
      survey.closedTime = surveyResult.getLong(surveyResult.getColumnIndex('closed_time'));
      survey.deleted = surveyResult.getLong(surveyResult.getColumnIndex('deleted')) === 1;
      survey.id_cloud = surveyResult.getString(surveyResult.getColumnIndex('id_cloud')) ;
      surveyResult.close();

      const questionPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
      questionPredicates.equalTo('survey_id', surveyId);
      const questionColumns: string[] = ['id', 'type', 'content', 'options', 'required'];
      const questionResult: relationalStore.ResultSet =
        await this.rdbStore.query(questionPredicates, questionColumns);

      while (questionResult.goToNextRow()) {
        const question: Question = new Question();
        question.id = questionResult.getLong(questionResult.getColumnIndex('id')).toString();
        question.type = questionResult.getString(questionResult.getColumnIndex('type')) as QuestionType;
        question.content = questionResult.getString(questionResult.getColumnIndex('content'));
        question.required = questionResult.getLong(questionResult.getColumnIndex('required')) === 1;

        const optionsJson: string = questionResult.getString(questionResult.getColumnIndex('options'));
        question.options = JSON.parse(optionsJson) as string[];

        survey.questions.push(question);
      }
      questionResult.close();
      return survey;

    } catch (err) {
      let error = err as BusinessError
      Logger.error('[getSurveyById]', JSON.stringify(error.code))
      return null;
    }
  }

  // 根据 id 删除问卷
  async deleteSurvey(surveyId: number, permanent: boolean = false, isSync = true): Promise<boolean> {
    if (!this.rdbStore) {
      Logger.info('[deleteSurvey]', 'deleteSurvey() has no callback!');
      return false;
    }
    try {
      // 永久删除
      if (permanent) {
        const questionPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
        questionPredicates.equalTo('survey_id', surveyId);
        await this.rdbStore.delete(questionPredicates);

        const surveyPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
        surveyPredicates.equalTo('id', surveyId);
        const deletedRows = await this.rdbStore.delete(surveyPredicates);
        // if (isSync) {
        //   await this.syncData();
        // }
        return deletedRows > 0;
      }
      // 软删除 —— 移到废纸篓
      else {
        const valueBucket: relationalStore.ValuesBucket = {
          'deleted': 1
        };
        const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
        predicates.equalTo('id', surveyId);
        const updatedRows: number = await this.rdbStore.update(valueBucket, predicates);
        // if (isSync) {
        //   await this.syncData();
        // }
        return updatedRows > 0;
      }
    } catch (error) {
      Logger.error('Failed to delete survey:', JSON.stringify(error));
      return false;
    }

  }

  // 根据 id 恢复在废纸篓中的问卷
  async restoreSurvey(surveyId: number, isSync = true): Promise<boolean> {
    if (!this.rdbStore) {
      Logger.info('[restoreSurvey]', 'restoreSurvey() has no callback!');
      return false;
    }

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'deleted': 0
      };
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
      predicates.equalTo('id', surveyId);
      const updatedRows: number = await this.rdbStore.update(valueBucket, predicates);
      // if (isSync) {
      //   await this.syncData();
      // }
      return updatedRows > 0;
    } catch (error) {
      Logger.error('Failed to restore survey:', JSON.stringify(error));
      return false;
    }
  }

  // 更新问卷
  async updateSurvey(survey: Survey, isSync = true): Promise<boolean> {
    if (!this.rdbStore) {
      Logger.info('[restoreSurvey]', 'restoreSurvey() has no callback!');
      return false;
    }

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'title': survey.title,
        'description': survey.description,
        'status': survey.status,
        'published_time': survey.publishedTime!,
        'closed_time': survey.closedTime!,
        'id_cloud':survey.id_cloud
      };

      const surveyPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('surveys');
      surveyPredicates.equalTo('id', survey.id);
      await this.rdbStore.update(valueBucket, surveyPredicates);

      const deleteQuestionPredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('questions');
      deleteQuestionPredicates.equalTo('survey_id', survey.id);
      await this.rdbStore.delete(deleteQuestionPredicates);

      for (let i: number = 0; i < survey.questions.length; i++) {
        const question: Question = survey.questions[i];
        const questionBucket: relationalStore.ValuesBucket = {
          'survey_id': survey.id!,
          'type': question.type,
          'content': question.content,
          'options': JSON.stringify(question.options),
          'required': question.required ? 1 : 0
        };
        await this.rdbStore.insert('questions', questionBucket);
      }

      return true;
    } catch (error) {
      Logger.error('Failed to update survey:', JSON.stringify(error));
      return false;
    }
  }


}

// async subscribeDataChange(): Promise<void> {
//   if (!this.rdbStore) {
//     Logger.info('[saveSurvey]', 'saveSurvey() has no callback!');
//     return;
//   }
//   try {
//     this.rdbStore.on('dataChange', relationalStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, async (devices) => {
//       Logger.info('[subscribeDataChange]', 'dataChange devices ' + devices);
//       for (let i = 0; i < devices.length; i++) {
//         let device = devices[i];
//         Logger.info('[subscribeDataChange]', `The data of device:${device} has been changed.`);
//         const result = await this.remoteQuery(device);
//         this.context?.eventHub.emit('dataChange', JSON.stringify(result));
//       }
//     });
//   } catch (err) {
//     Logger.info('[subscribeDataChange]',
//       `Failed to register observer. Code:${err.code},message:${err.message}`);
//   }
// }
//
// getLocalDeviceNetworkId() {
//   try {
//     const deviceManager = distributedDeviceManager.createDeviceManager('com.example.crossDeviceDataSynchronization');
//     if (deviceManager != null) {
//       this.localDeviceNetworkId = deviceManager.getLocalDeviceNetworkId();
//       Logger.info('[getLocalDeviceNetworkId]',
//         'local device networkId: ' + JSON.stringify(this.localDeviceNetworkId));
//     }
//   } catch (err) {
//     Logger.error('[getLocalDeviceNetworkId]',
//       `Failed to insert data. Code:${err.code}, message:${err.message}`);
//   }
// }
//
// getDeviceList(): string[] {
//   let deviceManager: distributedDeviceManager.DeviceManager;
//   let deviceIds: string[] = [];
//   try {
//     // create deviceManager.
//     deviceManager = distributedDeviceManager.createDeviceManager('com.example.crossDeviceDataSynchronization');
//     // DeviceIds is obtained by calling the getAvailableDeviceListSync method by the DeviceManager.
//     if (deviceManager != null) {
//       let devices = deviceManager.getAvailableDeviceListSync();
//       Logger.info('[getDeviceList]', 'devices size ' + devices.length);
//       for (let i = 0; i < devices.length; i++) {
//         deviceIds[i] = devices[i].networkId as string;
//         Logger.info('[getDeviceList]', 'devices size ' + deviceIds[i]);
//       }
//     }
//   } catch (err) {
//     Logger.error('[getDeviceList]',
//       `Failed to insert data. Code:${err.code}, message:${err.message}`);
//   }
//   return deviceIds;
// }

// async syncData(): Promise<void> {
//   if (!this.rdbStore) {
//     Logger.info('[restoreSurvey]', 'restoreSurvey() has no callback!');
//     return;
//   }
//
//   const deviceIds: string[] = this.getDeviceList();
//   if (deviceIds.length === 0) {
//     return;
//   }
//   try {
//     const predicates = new relationalStore.RdbPredicates('surveys');
//     predicates.inDevices(deviceIds);
//     const result = await this.rdbStore.sync(relationalStore.SyncMode.SYNC_MODE_PUSH, predicates);
//     for (let i = 0; i < result.length; i++) {
//       const deviceId = result[i][0];
//       const syncResult = result[i][1];
//       if (syncResult === 0) {
//         Logger.info('[syncData]', `device:${deviceId} sync success`);
//       } else {
//         Logger.error('[syncData]',
//           `device:${deviceId} sync failed, status:${syncResult}`);
//       }
//     }
//   } catch (err) {
//     Logger.error('[syncData]', 'Push data failed, code: ' + err.code + ', message: ' + err.message);
//   }
// }
//
// async remoteQuery(device: string) {
//   if (!this.rdbStore) {
//     Logger.info('[restoreSurvey]', 'restoreSurvey() has no callback!');
//     return false;
//   }
//   try {
//     const predicates: relationalStore.RdbPredicates =
//       new relationalStore.RdbPredicates('surveys');
//     const columns: string[] =
//       ['id', 'title', 'description', 'created_time', 'status', 'published_time', 'closed_time', 'deleted'];
//     const resultSet = await this.rdbStore.remoteQuery(device, 'surveys', predicates,
//       columns);
//
//     const surveys: Survey[] = [];
//     while (resultSet.goToNextRow()) {
//       const survey: Survey = new Survey();
//       survey.id = resultSet.getLong(resultSet.getColumnIndex('id'));
//       survey.title = resultSet.getString(resultSet.getColumnIndex('title'));
//       survey.description = resultSet.getString(resultSet.getColumnIndex('description'));
//       survey.createdTime = resultSet.getLong(resultSet.getColumnIndex('created_time'));
//       survey.status = resultSet.getString(resultSet.getColumnIndex('status')) as SurveyStatus;
//       survey.publishedTime = resultSet.getLong(resultSet.getColumnIndex('published_time'));
//       survey.closedTime = resultSet.getLong(resultSet.getColumnIndex('closed_time'));
//       survey.deleted = resultSet.getLong(resultSet.getColumnIndex('deleted')) === 1;
//       surveys.push(survey);
//     }
//     resultSet.close();
//
//     Logger.info('[remoteQuery]', 'Remote query success, row cout: ' + resultSet.rowCount);
//     Logger.info('[remoteQuery]',
//       `ResultSet column names: ${resultSet.columnNames}, column count: ${resultSet.columnCount}`);
//     return surveys;
//   } catch (err) {
//     Logger.error('[remoteQuery]',
//       'Remote query failed, code: ' + err.code + ', message: ' + err.message);
//     return [];
//   }
// }