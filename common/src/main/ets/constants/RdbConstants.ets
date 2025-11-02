import { relationalStore } from '@kit.ArkData'

export class RdbConstants {
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'SurveyDB.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  // SQL 语句
  static readonly CREATE_SURVEY_TABLE = `
    CREATE TABLE IF NOT EXISTS surveys (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      created_time INTEGER NOT NULL,
      status TEXT NOT NULL,
      published_time INTEGER,
      closed_time INTEGER,
      deleted INTEGER NOT NULL DEFAULT 0
    )
    `;
  static readonly CREATE_QUESTIONS_TABLE = `
    CREATE TABLE IF NOT EXISTS questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      survey_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      content TEXT NOT NULL,
      options TEXT NOT NULL,
      required INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (survey_id) REFERENCES surveys (id) ON DELETE CASCADE
    )
    `;
}