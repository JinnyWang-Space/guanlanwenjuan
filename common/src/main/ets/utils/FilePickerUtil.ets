import { photoAccessHelper } from "@kit.MediaLibraryKit";
import { BusinessError } from "@kit.BasicServicesKit";
import picker from "@ohos.file.picker";
import { common } from "@kit.AbilityKit"
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import Logger from '../utils//Logger'

// 拉起图库选择图片/视频，返回图片url值，该值为只读
export function mediaPicker(type: number, pickerNum: number, callback: Function) {
  // 创建图片-音频类型文件选择选项实例
  const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();

  /**
   *   选择媒体文件类型和选择媒体文件的最大数目
   */
  // 过滤选择媒体文件类型
  if (type === 0) {
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
  } else if (type === 1) {
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
  } else if (type === 2) {
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.MOVING_PHOTO_IMAGE_TYPE;
  }
  // 选择媒体文件的最大数目
  photoSelectOptions.maxSelectNumber = pickerNum;

  /**
   * 创建图库选择器实例，调用PhotoViewPicker.select接口拉起界面进行文件选择。文件选择成功后，返回PhotoSelectResult结果集
   */
  let uris: string[] = [];
  const photoViewPicker = new photoAccessHelper.PhotoViewPicker();

  photoViewPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
    uris = photoSelectResult.photoUris;
    console.info(`[MediaKit.photoPicker] photoViewPicker.select to file succeed and uris are: ${uris}`);
    // 权限只读
    callback(uris);
  }).catch((err: BusinessError) => {
    callback([]);
    console.info(`[MediaKit.PhtoPicker] Invoke photoViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
  });
}


export async function savePixelMapToAlbum(srcFileUri: string, phAccessHelper: photoAccessHelper.PhotoAccessHelper) {

  // 使用弹窗授权保存媒体资源
  try {
    // 指定待保存到媒体库的位于应用沙箱的图片uri。
    let srcFileUris: Array<string> = [
      srcFileUri
    ];
    // 指定待保存照片的创建选项，包括文件后缀和照片类型，标题和照片子类型可选。
    let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [
      {
        title: '问卷分享二维码', // 可选。
        fileNameExtension: 'jpg',
        photoType: photoAccessHelper.PhotoType.IMAGE,
        subtype: photoAccessHelper.PhotoSubtype.DEFAULT, // 可选。
      }
    ];
    // 基于弹窗授权的方式获取媒体库的目标uri。
    let desFileUris: Array<string> = await phAccessHelper.showAssetsCreationDialog(srcFileUris, photoCreationConfigs);
    // 将来源于应用沙箱的照片内容写入媒体库的目标uri。
    let desFile: fileIo.File = await fileIo.open(desFileUris[0], fileIo.OpenMode.WRITE_ONLY);
    let srcFile: fileIo.File = await fileIo.open(srcFileUri, fileIo.OpenMode.READ_ONLY);
    await fileIo.copyFile(srcFile.fd, desFile.fd);
    fileIo.closeSync(srcFile);
    fileIo.closeSync(desFile);
    Logger.info('[FilePickerUtils.savePixelToAlbum]', 'create asset by dialog successfully');
  } catch (err) {
    Logger.error('[FilePickerUtils.savePixelToAlbum]',
      `failed to create asset by dialog successfully errCode is: ${err.code}, ${err.message}`);
  }

}