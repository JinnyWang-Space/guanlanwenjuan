import { cloudDatabase } from '@kit.CloudFoundationKit';

export class AccountCloud extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "Account";
  }

  // 自增 id
  id: number=0;
  // OPEN_ID
  open_id: string = '';
}