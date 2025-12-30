import { cloudDatabase } from "@kit.CloudFoundationKit";
import { AppGeneralViewModel, FeedbackCloud, FeedbackContentCloud, StartVibrator, WindowUtil } from "common";
import Logger from "common/src/main/ets/utils/Logger";
import { AppStorageV2, PersistenceV2, promptAction, window } from "@kit.ArkUI";
import { ValidatorUtils } from "../utils/ValidatorUtils";
import { util } from "@kit.ArkTS";
import { deviceInfo } from "@kit.BasicServicesKit";

// 创建窗口实例
let windowStage: window.WindowStage;

@ComponentV2
export struct FeedbackView {
  // 在 AppStorageV2 中创建一个 key 为 WindowUtil 的键值对
  @Local windowUtil: WindowUtil =
    AppStorageV2.connect(WindowUtil, () => new WindowUtil(windowStage.getMainWindowSync()))!;
  // 在 PersistenceV2 中创建一个 type 为 AppGeneralViewModel 的键值对
  @Local appGeneralData: AppGeneralViewModel =
    PersistenceV2.globalConnect({ type: AppGeneralViewModel, defaultCreator: () => new AppGeneralViewModel() })!;
  // 创建导航器实例（子）
  @Consumer('toolInfo') toolInfos: NavPathStack = new NavPathStack();
  // 创建滑动手势配置参数对象
  private panOptionRight: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Right });
  // 反馈的问题类型
  @Local selectedType: number = -1;
  // 反馈类型盒子
  @Local typeBox: Resource[] = [$r('app.string.bug_text'), $r('app.string.suggestions_text')];
  @Local typeBox_zh: string[] = ['功能异常', '产品建议'];
  // 反馈内容
  @Local feedbackText: string = '';
  // 反馈内容边框颜色
  @Local feedbackBorderColor: Color = Color.Transparent;
  // 反馈内容边框宽度
  @Local feedbackBorderWidth: number = 0;
  // 是否符合反馈格式
  @Local isFeedbackFormat: boolean = false;
  // 联系方式
  @Local contactText: string = '';
  // 联系方式边框颜色
  @Local contactBorderColor: Color = Color.Transparent;
  // 联系方式边框宽度
  @Local contactBorderWidth: number = 0;
  // 是否符合联系方式格式
  @Local isContactFormat: boolean = false;
  // 发送状态
  @Local isLoading: boolean = false;
  @Local isSuccess: boolean = false;
  @Local isFailed: boolean = false;

  build() {
    Scroll() {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          // 反馈类型
          Column() {
            Text($r('app.string.category_text'))
              .width('100%')
              .padding({ left: 12 })
              .margin({ top: 36, bottom: 12 })
            Row({ space: 6 }) {
              ForEach(this.typeBox, (item: string, index: number) => {
                Button() {
                  Text(item)
                    .fontSize(14)
                }
                .backgroundColor(this.selectedType === index ? $r('app.color.list_on_color') :
                  $r('sys.color.ohos_id_color_button_normal'))
                .padding({
                  top: 4,
                  bottom: 4,
                  left: 12,
                  right: 12
                })
                .onClick(() => {
                  this.selectedType = index;
                })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .margin({ bottom: this.selectedType < 0 ? 0 : 24 })

            if (this.selectedType < 0) {
              Text($r('app.string.category_warning_text'))
                .width('100%')
                .textAlign(TextAlign.Start)
                .fontColor(Color.Red)
                .fontSize(12)
                .margin({ top: 4, bottom: 24 })
            }
          }

          // 反馈内容
          Column() {
            Text($r('app.string.description_suggestions_text'))
              .width('100%')
              .padding({ left: 12 })
              .margin({ top: 24, bottom: 12 })
            TextArea({
              placeholder: $r('app.string.description_suggestions_placeholder_text'),
              text: this.feedbackText!!
            })
              .width('100%')
              .height(150)
              .onChange(() => {
                if (this.feedbackText.trim().length >= 20) {
                  this.getUIContext().animateTo({
                    duration: 200,
                    curve: Curve.Linear
                  }, () => {
                    this.feedbackBorderColor = Color.Transparent;
                    this.feedbackBorderWidth = 0;
                    this.isFeedbackFormat = true;
                  })
                }
              })
              .onBlur(() => {
                if (this.feedbackText.trim().length < 20) {
                  this.getUIContext().animateTo({
                    duration: 200,
                    curve: Curve.Linear
                  }, () => {
                    this.feedbackBorderColor = Color.Red;
                    this.feedbackBorderWidth = 1;
                    this.isFeedbackFormat = false;
                  })
                } else {
                  this.getUIContext().animateTo({
                    duration: 200,
                    curve: Curve.Linear
                  }, () => {
                    this.feedbackBorderColor = Color.Transparent;
                    this.feedbackBorderWidth = 0;
                    this.isFeedbackFormat = true;
                  })
                }
              })
              .borderColor(this.feedbackBorderColor)
              .borderWidth(this.feedbackBorderWidth)
            Row() {
              if (!this.isFeedbackFormat) {
                Text($r('app.string.description_suggestions_warning_text'))
                  .fontSize(12)
                  .fontColor(Color.Red)
              }
              Blank()
              Text(this.feedbackText.trim().length.toString())
                .fontSize(12)
            }
            .width('100%')
            .margin({ top: 4, bottom: 24 })
          }

          // 联系方式
          Column() {
            Text($r('app.string.contact_information_text'))
              .width('100%')
              .padding({ left: 12 })
              .margin({ top: 24, bottom: 12 })
            TextArea({ placeholder: $r('app.string.contact_information_placeholder_text'), text: this.contactText!! })
              .borderColor(this.contactBorderColor)
              .borderWidth(this.contactBorderWidth)
              .onChange(() => {
                let isFormat =
                  ValidatorUtils.isPhoneNumber(this.contactText) || ValidatorUtils.isEmail(this.contactText);
                if (isFormat) {
                  this.getUIContext().animateTo({
                    duration: 200,
                    curve: Curve.Linear
                  }, () => {
                    this.contactBorderColor = Color.Transparent;
                    this.contactBorderWidth = 0;
                    this.isContactFormat = true;
                  })
                }
              })
              .onBlur(() => {
                let isFormat =
                  ValidatorUtils.isPhoneNumber(this.contactText) || ValidatorUtils.isEmail(this.contactText);
                // 符合格式
                if (isFormat) {
                  this.getUIContext().animateTo({
                    duration: 200,
                    curve: Curve.Linear
                  }, () => {
                    this.contactBorderColor = Color.Transparent;
                    this.contactBorderWidth = 0;
                    this.isContactFormat = true;
                  })
                }
                // 不符合格式
                else {
                  this.getUIContext().animateTo({
                    duration: 200,
                    curve: Curve.Linear
                  }, () => {
                    this.contactBorderColor = Color.Red;
                    this.contactBorderWidth = 1;
                    this.isContactFormat = false;
                  })
                }
              })
            Row() {
              if (!this.isContactFormat) {
                Text($r('app.string.contact_content_warning_text'))
                  .fontSize(12)
                  .fontColor(Color.Red)
              }
              Blank()
              Text(this.contactText.trim().length.toString())
                .fontSize(12)
            }
            .width('100%')
            .margin({ top: 4, bottom: 24 })
          }

          Blank()
            .layoutWeight(1)

          // 提交按钮
          Button() {
            Text($r('app.string.submit_text'))
          }
          .width('100%')
          .height(40)
          .backgroundColor($r('app.color.list_on_color'))
          .margin({ bottom: 48 })
          .enabled((this.selectedType > -1 && this.isFeedbackFormat && this.isContactFormat) ? true : false)
          .onClick(async () => {
            this.isLoading = true;
            // 初始化存储区
            try {
              let databaseZone = cloudDatabase.zone('guanlanwenjuan');
              let feedback = new FeedbackCloud();
              let id = Date.now().toLocaleString();
              feedback.id = id;
              feedback.type = this.typeBox_zh[this.selectedType];
              feedback.contact_type = ValidatorUtils.isPhoneNumber(this.contactText) ? '手机号' : '邮箱';
              feedback.contact_content = this.contactText;
              feedback.device_type = deviceInfo.deviceType;
              feedback.device_content = deviceInfo.marketName;
              feedback.device_sdk = JSON.stringify(deviceInfo.sdkApiVersion);
              let success = await databaseZone.upsert([feedback]);

              if (success) {
                // 进行描述/建议的分片处理
                let feedback_len: number = this.feedbackText.length;
                let byteLength: number = 0;
                let feedback_arr: string[] = [];
                let feedback_part: string = '';
                for (let i = 0; i < feedback_len; i++) {
                  let part = this.feedbackText[i];
                  let charBytes = new util.TextEncoder().encodeInto(part).length;
                  if (byteLength + charBytes <= 200) {
                    byteLength += charBytes;
                    feedback_part += part;
                  } else {
                    feedback_arr.push(feedback_part);
                    byteLength = charBytes;
                    feedback_part = part;
                  }
                }

                if (feedback_part) {
                  feedback_arr.push(feedback_part);
                }
                feedback_arr.map(async (part: string) => {
                  try {
                    let feedbackContent = new FeedbackContentCloud();
                    feedbackContent.id =
                      'feedbackContent_' + Date.now().toLocaleString() + '_' +
                      Math.floor(Math.random() * 10000).toString();
                    feedbackContent.feedback_id = id;
                    feedbackContent.content = part;
                    let record = await databaseZone.upsert([feedbackContent]);

                    if (record) {
                      this.isLoading = false;
                      this.isSuccess = true;
                      setTimeout(() => {
                        this.isSuccess = false;
                        this.toolInfos.pop();
                      }, 500)
                    } else {
                      this.isLoading = false;
                      this.isFailed = true;
                      setTimeout(() => {
                        this.isFailed = false;
                      }, 500)
                    }

                    Logger.info('[testTag]',
                      `Succeeded in upserting a description, result: ${JSON.stringify(record)}`);
                  } catch (err) {
                    this.isLoading = false;
                    this.isFailed = true;
                    setTimeout(() => {
                      this.isFailed = false;
                    }, 500)
                    Logger.error('[testTag]',
                      `Failed to upsert a description, code: ${err.code}, message: ${err.message}`);
                  }
                })
              }
              else {
                this.isLoading = false;
                this.isFailed = true;
                setTimeout(() => {
                  this.isFailed = false;
                }, 500)
              }
              Logger.info('[FeedbackView]', `Succeeded in upserting feedbackData, result: ${success}`);
            } catch (err) {
              this.isLoading = false;
              this.isFailed = true;
              setTimeout(() => {
                this.isFailed = false;
              }, 500)
              Logger.error('[FeedbackView]', `Failed to upsert data, code: ${err.code}, message: ${err.message}`);
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .gesture(
          PanGesture(this.panOptionRight)
            .onActionEnd((event: GestureEvent) => {
              // 开启滑动触感反馈
              if (this.appGeneralData.isHapticSwipe) {
                StartVibrator()
              }
              this.toolInfos.pop();
              Logger.info('[ContentView.PanGesture]', 'Pan end');
            })
        )

        if (this.isLoading || this.isSuccess || this.isFailed) {
          Column({ space: 6 }) {
            if (this.isLoading) {
              LoadingProgress()
                .color($r('app.color.list_on_color'))
                .size({ width: 48, height: 48 })
              Text($r('app.string.submit_status_sending_text'))
            } else if (this.isSuccess) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(48)
                .fontColor([$r('app.color.list_on_color')])
              Text($r('app.string.submit_status_sent_text'))
            } else {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(48)
                .fontColor([$r('app.color.list_on_color')])
              Text($r('app.string.submit_status_failed_text'))
            }
          }
          .width(150)
          .height(150)
          .justifyContent(FlexAlign.Center)
          .borderRadius(20)
          .backgroundColor($r('app.color.list_card_bg_color'))
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}