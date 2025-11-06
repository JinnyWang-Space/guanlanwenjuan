import { common } from '@kit.AbilityKit';
import { fileIo as fs, ReadOptions, WriteOptions, ListFileOptions } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';
import { buffer } from '@kit.ArkTS';

export function createFile(context: common.UIAbilityContext, fileName: string, fileContent: string,
  callback: Function = () => {
  }): void {
  let filesDir = context.filesDir;
  // 文件不存在时创建并打开文件，文件存在时打开文件
  let file = fs.openSync(filesDir + fileName, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  // 写入一段内容至文件
  let writeLen = fs.writeSync(file.fd, fileContent);
  console.info("The length of str is: " + writeLen);
  // 创建一个大小为1024字节的ArrayBuffer对象，用于存储从文件中读取的数据
  let arrayBuffer = new ArrayBuffer(1024);
  // 设置读取的偏移量和长度
  let readOptions: ReadOptions = {
    offset: 0,
    length: arrayBuffer.byteLength
  };
  // 读取文件内容到ArrayBuffer对象中，并返回实际读取的字节数
  let readLen = fs.readSync(file.fd, arrayBuffer, readOptions);
  // 将ArrayBuffer对象转换为Buffer对象，并转换为字符串输出
  let buf = buffer.from(arrayBuffer, 0, readLen);
  console.info("the content of file: " + buf.toString());
  // 关闭文件
  fs.closeSync(file);
  let destPath = filesDir + fileName
  callback(destPath)
}

/***
 * 功能：读取文件内容并写入到另一个文件
 * 参数 1：获取上下文
 * 参数 2：创建目标文件的名称
 * 参数 3：源文件 uri
 * 参数 4：回调函数根据目标文件 uri进行后续操作
 */
export async function readWriteFile(context: common.UIAbilityContext,
  fileName: string, sourceUri: string, callback: Function = () => {
  }): Promise<void> {
  try {
    let filesDir = context.filesDir;
    let destPath = `${filesDir}/${fileName}`;

    // 打开源文件
    let sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY | fs.OpenMode.CREATE);
    // 创建目标文件
    let destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

    // 读取源文件内容并写入目标文件
    let bufferSize = 4096;
    let readSize = 0;
    let buf = new ArrayBuffer(bufferSize);
    let readOptions: ReadOptions = {
      offset: readSize,
      length: bufferSize
    };
    let readLen = fs.readSync(sourceFile.fd, buf, readOptions);
    while (readLen > 0) {
      readSize += readLen;
      let writeOptions: WriteOptions = {
        length: readLen
      };
      fs.writeSync(destFile.fd, buf, writeOptions);
      readOptions.offset = readSize;
      readLen = fs.readSync(sourceFile.fd, buf, readOptions);
    }
    // 关闭文件
    fs.closeSync(sourceFile);
    fs.closeSync(destFile);

    Logger.info('[FileUtils.readWriteFile]', `读取创建成功，路径: ${destPath}`);
    callback(destPath);
  } catch (error) {
    Logger.error('[FileUtils.readWriteFile]', `读取创建失败，error: ${JSON.stringify(error)}`);
  }
}

/***
 * 功能：获取该目录下的文件
 * 参数 1：文件所在目录
 */
export function getListFile(path: string, callback = () => {
}) {
  try {
    let filenames = fs.listFileSync(path);
    Logger.info('[FileUtils.getListFile]', 'listFile succeed.');
    for (let i = 0; i < filenames.length; i++) {
      Logger.info('[FileUtils.getListFile]', filenames[i]);
    }
  } catch (error) {
    // TODO: Implement error handling.
    Logger.error('[FileUtils.getListFile]', `获取目录下文件失败，error: ${error}`);
  }

}

/***
 * 功能：检查文件或者目录是否存在
 * 参数 1：文件或者目录路径
 * 参数 2：回调函数用于根据文件或目录是否存在进行后续操作
 */
export function access(path: string, callback: Function = () => {
}) {
  fs.access(path).then((isExist: boolean) => {
    if (isExist) {
      Logger.info('[FileUtils.access]', `file exists, file: ${path}.`);
    } else {
      Logger.info('[FileUtils.access]', `file not exists, file: ${path}.`);
    }
    callback(isExist);
  }).catch((err: BusinessError) => {
    Logger.error('[FileUtils.access]', `access failed with error message: ${err.message}, error code: ${err.code}.`);
  })
}

/***
 * 功能：创建目录
 * 参数 1：创建目录的上层目录路径
 * 参数 2：创建目录的名称
 */
export function mkdir(path: string, dirName: string) {
  let dirPath = `${path}/${dirName}`;
  fs.mkdir(dirPath).then(() => {
    Logger.info('[FileUtils.mkdir]', `mkdir succeed, dirPath: ${dirPath}.`);
  }).catch((err: BusinessError) => {
    Logger.error('[FileUtils.mkdir]', `mkdir failed with error message: ${err.message}, error code: ${err.code}.`);
  })
}

/***
 * 功能：删除目录
 * 参数 1：要删除的目录的路径
 */
export function rmdir(path: string) {
  fs.rmdir(path).then(() => {
    Logger.info('[FileUtils.rmdir]', `rmdir succeed, rmdir: ${path}.`);
  }).catch((err: BusinessError) => {
    Logger.error('[FileUtils.rmdir]', `rmdir failed with error message: ${err.message}, error code: ${err.code}`);
  });
}

/***
 * 功能：删除文件
 * 参数 1：要删除的文件的路径
 */
export function unlink(path: string) {
  fs.unlink(path).then(() => {
    Logger.info('[FileUtils.unlink]', `remove file succeed, filePath: ${path}`);
  }).catch((err: BusinessError) => {
    Logger.error('[FileUtils.unlink]',
      `remove file failed with error message: ${err.message}, error code: ${err.code}`);
  });
}

export function copyFile(srcPath: string, dstPath: string) {
  fs.copyFile(srcPath, dstPath, 0).then(() => {
    console.info("copy file succeed");
  }).catch((err: BusinessError) => {
    console.error("copy file failed with error message: " + err.message + ", error code: " + err.code);
  });
}

export function readFile(filePath: string,callback:Function=()=>{}) {
  let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE);
  let arrayBuffer = new ArrayBuffer(4096);
  fs.read(file.fd, arrayBuffer).then((readLen: number) => {
    console.info("read file data succeed");
    let buf = buffer.from(arrayBuffer, 0, readLen);
    callback(buf.toString())
    console.info(`The content of file: ${buf.toString()}`);
  }).catch((err: BusinessError) => {
    console.error("read file data failed with error message: " + err.message + ", error code: " + err.code);
  }).finally(() => {
    fs.closeSync(file);
  });
}