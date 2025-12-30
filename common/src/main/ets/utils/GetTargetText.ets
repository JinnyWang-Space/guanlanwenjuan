export function getTargetTitle(titleContent: string,languageId:number) {
  let title = JSON.parse(titleContent) as string[];
  return title[languageId];
}