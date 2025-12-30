import { motion } from "@kit.MultimodalAwarenessKit";
import Logger from "common/ets/utils/Logger";

// 打开智感握持
export function OnGripDetection(callback: Function = () => {
}) {
  // 2. 定义回调函数接收握持手结果
  let handCallback: Callback<motion.HoldingHandStatus> = (data: motion.HoldingHandStatus) => {
    console.info('callback succeeded' + data);
    callback(data);
  };
  // 3. 订阅握持手感知
  try {
    motion.on('holdingHandChanged', handCallback);
    Logger.info('[SmartDetectionUtils.OnGripDetection]', "on succeeded");
  } catch (err) {
    let error = err as BusinessError;
    Logger.error('[SmartDetectionUtils.OnGripDetection]', "Failed on and err code is " + error.code);
  }
}

// 关闭智感握持
export function OffGripDetection(callback: Function = () => {
}) {
  // 3. 订阅握持手感知
  try {
    motion.off('holdingHandChanged');
    Logger.info('[SmartDetectionUtils.OffGripDetection]', "off succeeded");
    callback(true);
  } catch (err) {
    let error = err as BusinessError;
    Logger.error('[SmartDetectionUtils.OffGripDetection]', "Failed on and err code is " + error.code);
  }
}