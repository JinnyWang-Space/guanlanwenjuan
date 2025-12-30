import { vibrator } from "@kit.SensorServiceKit";
import { deviceInfo } from "@kit.BasicServicesKit";

// 开启震动
export function StartVibrator() {
  if (deviceInfo.deviceType === 'phone') {
    // 使用try catch对可能出现的异常进行捕获
    try {
      // HapticFeedback 12+
      // 'haptic.effect.soft',较松散的振动效果，频率偏低。
      // 'haptic.effect.hard'	较沉重的振动效果，频率居中。
      // 'haptic.effect.sharp'	较尖锐的振动效果，频率偏高。
      // 体验下来 hard 震动过强，soft 震动过弱，sharp 介于两者之间，因此采用 sharp
      // 查询是否支持'haptic.notice.sharp'
      vibrator.isSupportEffect('haptic.effect.sharp', (err: BusinessError, state: boolean) => {
        if (err) {
          console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
          return;
        }
        console.info('Succeed in querying effect');
        if (state) {
          try {
            vibrator.startVibration({
              type: 'preset',
              effectId: 'haptic.effect.sharp',
              count: 1,
            }, {
              usage: 'notification' // 根据实际选择类型归属不同的开关管控
            }, (error: BusinessError) => {
              if (error) {
                console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
                return;
              }
              console.info('Succeed in starting vibration');

            });
          } catch (err) {
            let e: BusinessError = err as BusinessError;
            console.error(`An unexpected error occurred. Code: ${e.code}, message: ${e.message}`);
          }
        }
      })
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`An unexpected error occurred. Code: ${e.code}, message: ${e.message}`);
    }
  }
}