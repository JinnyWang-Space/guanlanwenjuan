import { photoAccessHelper } from "@kit.MediaLibraryKit";
import { BusinessError } from "@kit.BasicServicesKit";
import picker from "@ohos.file.picker";
import { common } from "@kit.AbilityKit"
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import resourceManager from "@ohos.resourceManager";

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


export async function savePixelMapToAlbum(context: common.UIAbilityContext,pixelMap: image.PixelMap) {

  const resourceMgr: resourceManager.ResourceManager = context.resourceManager;
  // "beer.jpeg" is the name of the image file under the rawfile directory, which can be modified and used according to your own needs
  const fileData: Uint8Array = await resourceMgr.getRawFileContent('beer.jpeg');
  let buffer = new Uint8Array(fileData).buffer as object as ArrayBuffer;
  let imageResource = image.createImageSource(buffer);
  let opts: image.DecodingOptions = { editable: true };
  pixelMap = await imageResource.createPixelMap(opts);

  // Obtain the save path of the album
  let helper = photoAccessHelper.getPhotoAccessHelper(context);
  let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpeg');
  let file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
  let imagePackerApi = image.createImagePacker();
  let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 };

  imagePackerApi.packToFile(pixelMap, file.fd, packOpts, (err: BusinessError) => {
    if (err) {
      console.error(`Failed to pack the image to file.code ${err.code},message is ${err.message}`);
    } else {
      console.info('Succeeded in packing the image to file.');
      imagePackerApi.release((err: BusinessError) => {
        if (err) {
          console.error(`Failed to release the image source instance.code ${err.code},message is ${err.message}`);
        } else {
          console.info('Succeeded in releasing the image source instance.');
          fileIo.close(file.fd);
        }
      })
    }
  })
}