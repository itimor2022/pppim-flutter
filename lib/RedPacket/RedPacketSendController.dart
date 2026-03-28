import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:openim_common/openim_common.dart';
import '../routes/app_pages.dart';
import 'Api/RedPacketApi.dart';
import 'Widgets/CompatibilityWidgets.dart';

class RedPacketSendController extends GetxController {
  /// 商品描述
  final TextEditingController productDescription = TextEditingController();

  /// 单个金额
  final TextEditingController singlePrice = TextEditingController();

  /// 红包数量
  final TextEditingController packetQuantity = TextEditingController();

  /// 金额计算
  final priceObs = '0.000'.obs;

  /// 单聊群聊判断
  bool isSingle = false;

  /// id
  String? id;

  /// 会话ID
  String? conversationID;

  /// 下标定义
  final index = 3.obs;

  /// 选中的群员
  // Use UserInfo from OpenIM SDK instead of GroupMemberModel
  final userList = UserInfo(userID: '').obs;

  /// 群员信息
  final TextEditingController groupInfo = TextEditingController();

  /// 红包数量限制
  int redPacketQuantityLimit = 1;

  /// --- 扫雷新增定义 ---
  var mineConfigs = <Map<String, dynamic>>[].obs;
  var selectedPacketCount = 0.obs;
  var selectedMineNums = <int>[].obs;
  final TextEditingController mineNum = TextEditingController();
  final odds = '1.5'.obs; // 默认赔率，将动态覆盖

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      // 兼容两种调用方式
      id = Get.arguments['id'];
      isSingle = Get.arguments['isSingle'] ?? false;
      conversationID = Get.arguments['conversationID'];
      redPacketQuantityLimit = Get.arguments['count'] ?? 100;

      // 如果 chat_logic 传的是 conversationInfo 对象，则从中提取
      if (id == null && Get.arguments['conversationInfo'] != null) {
        final convInfo = Get.arguments['conversationInfo'];
        final bool isGroup = Get.arguments['isGroupChat'] ?? false;
        isSingle = !isGroup;
        conversationID = convInfo.conversationID;
        if (isGroup) {
          id = convInfo.groupID;
        } else {
          id = convInfo.userID;
        }
      }
    }
    _loadMineConfigs();
  }

  void _loadMineConfigs() async {
    if (isSingle || id == null) return;
    try {
      final res = await Apis.getGroupMineConfigs(groupID: id!);
      if (res != null && res is List) {
        mineConfigs.assignAll(List<Map<String, dynamic>>.from(res)
            .where((e) =>
                e['is_open'] == 1 ||
                e['is_open'] == true ||
                e['is_open'] == null)
            .toList());
        if (mineConfigs.isNotEmpty) {
          selectedPacketCount.value = mineConfigs.first['packet_count'] ?? 4;
          packetQuantity.text = selectedPacketCount.value.toString();
          updateOdds();
        }
      }
    } catch (e) {
      Logger.print('load mine configs error: $e');
    }
  }

  void updateOdds() {
    if (mineConfigs.isEmpty) return;
    final config = mineConfigs.firstWhere(
        (e) => e['packet_count'] == selectedPacketCount.value,
        orElse: () => <String, dynamic>{});
    if (config.isEmpty) return;

    if (selectedMineNums.length > 1) {
      odds.value = config['multi_odds'] ?? '1.5';
    } else {
      odds.value = config['single_odds'] ?? '1.5';
    }
    updateSweepMineRemark();
  }

  void updateSweepMineRemark() {
    if (index.value == 3 && !isSingle) {
      String count = packetQuantity.text.isEmpty ? "0" : packetQuantity.text;
      String mine = mineNum.text.isEmpty ? "0" : mineNum.text;
      String amount = priceObs.value.isEmpty ||
              priceObs.value == "0.000" ||
              priceObs.value == "0.00"
          ? "0"
          : priceObs.value;
      productDescription.text = "【$count】-【$mine】-【$amount】";
    } else {
      productDescription.text = "";
    }
  }

  void onNo() {
    priceObs.value = "0.000";
    if (index.value == 3 && mineConfigs.isNotEmpty) {
      packetQuantity.text = selectedPacketCount.value.toString();
    } else {
      packetQuantity.text = "";
    }
    singlePrice.text = "";
    updateSweepMineRemark();
  }

  /// 发送红包消息流程：
  /// 1. 弹出支付密码框
  /// 2. 输入密码后调用 API
  /// 3. API 成功后发送 IM 消息
  void sendRedPacketMessage({
    required String redPacketRemarks,
    required String packetType,
    required String exclusiveRemarks,
    required double totalAmount,
    required int totalPacket,
    double? singleAmount,
    required String? sendUserId,
    required String? userImIdOrGroupId,
    String? recvNickname,
    String? mineNums,
    String? odds,
    bool? isMulti,
    int? mineCount,
  }) async {
    // 弹出支付密码输入框
    systemInputPopup(
      SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 24.w),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/221.png',
                    width: 28.w,
                    color: Colors.transparent,
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 12.w,
                          width: 159.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x00F8F8F8),
                                Color(0xffFFA89E),
                                Color(0x00ffffff),
                              ],
                            ),
                          ),
                        ),
                        DefaultText(
                          text: "请支付",
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xff161616),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                      onTap: () => Get.back(),
                      child: Image.asset('assets/images/221.png', width: 28.w)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultText(
                  text: "${NumberFormat("#0.000").format(totalAmount)}",
                  textColor: const Color(0xff161616),
                  fontWeight: FontWeight.bold,
                  fontSize: 38.sp,
                ),
                Container(
                  margin: EdgeInsets.only(left: 4.w, top: 14.w),
                  child: DefaultText(
                    text: "元",
                    textColor: const Color(0xff161616),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            DefaultContainer(
              color: const Color(0xffF3F3F3),
              borderRadius: 10,
              margin: EdgeInsets.only(top: 16.w, bottom: 35.w),
              padding: EdgeInsets.all(15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: "付款方式",
                    textColor: const Color(0xff676767),
                    fontSize: 14.sp,
                  ),
                  Divider(
                    color: const Color(0xffcbcbcb),
                    height: 20.w,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/209.webp',
                            width: 24.w,
                          ),
                          SizedBox(width: 5.w),
                          DefaultText(
                            text: "元",
                            textColor: const Color(0xff676767),
                            fontSize: 14.sp,
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/222.png',
                        width: 16.w,
                      ),
                    ],
                  )
                ],
              ),
            ),
            Pinput(
              onCompleted: (pin) async {
                // [MOD] 调用 RedPacketApi
                final currentUserID = OpenIM.iMManager.userID;
                // 金额转换：元 -> 分 (x100)
                final amountInLi = (totalAmount * 100).toStringAsFixed(0);

                try {
                  var result = await RedPacketApi.sendRedPacket(
                    clientMsgID: const Uuid().v4(),
                    userID: currentUserID,
                    type: int.parse(packetType),
                    amount: amountInLi,
                    count: totalPacket,
                    recvID: sendUserId, // 专属红包接收者ID
                    conversationID: conversationID, // 传入真实的 conversationID
                    password: pin,
                    mineNums: mineNums,
                    odds: odds,
                    isMulti: isMulti,
                    mineCount: mineCount,
                    remark: redPacketRemarks == "" ? '恭喜发财' : redPacketRemarks,
                  );

                  // 根据 API 返回结果处理 (假设 result 包含 packet_id)
                  // 如果 API 封装了错误处理在 catch 里，这里就是成功

                  final packetID = result['packet_id'];
                  final message = await _sendCustomIMMessage(
                    packetID: packetID,
                    text:
                        redPacketRemarks == "" ? '恭喜发财，大吉大利' : redPacketRemarks,
                    amount: amountInLi,
                    count: totalPacket,
                    type: packetType, // 1/2/3/6
                    recvID: sendUserId,
                    recvNickname: recvNickname,
                    mineNums: mineNums,
                  );

                  Get.back(); // 关闭支付弹窗
                  Get.back(result: message); // 关闭发红包页面并返回消息
                } catch (e) {
                  Get.back(); // 关闭支付弹窗
                  final errorStr = e.toString();
                  if (errorStr.contains('20015') ||
                      errorStr.contains('密码未设置')) {
                    // 20015: ErrPayPasswordNotSet
                    Get.defaultDialog(
                      title: "提示",
                      middleText: "支付密码未设置，是否前往设置？",
                      textConfirm: "去设置",
                      textCancel: "取消",
                      onConfirm: () {
                        Get.back(); // close dialog
                        Get.toNamed(AppRoutes.setPayPassword);
                      },
                    );
                    return;
                  } else if (errorStr.contains('20016') ||
                      errorStr.contains('密码错误')) {
                    // 20016: ErrPayPasswordIncorrect
                    IMViews.showToast("支付密码错误");
                    return;
                  } else if (errorStr.contains('20017') ||
                      errorStr.contains('余额不足')) {
                    // 20017: ErrBalanceNotEnough
                    IMViews.showToast("余额不足");
                    return;
                  }
                  IMViews.showToast(errorStr);
                }
              },
              autofocus: true,
              length: 6,
              obscureText: true,
              defaultPinTheme: PinTheme(
                width: 43.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: const Color(0xffE7E7E7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: TextStyle(
                  color: const Color(0xff3D3D3D),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Message> _sendCustomIMMessage({
    required String packetID,
    required String text,
    required String amount,
    required int count,
    required String type,
    String? recvID,
    String? recvNickname,
    String? mineNums,
  }) async {
    // 构造 IM 消息体
    // 根据 RED_PACKET_API.md
    /*
      {
        "contentType": 2001,
        "content": {
          "data": {
            "type": "RedPacket",
            "packet_id": "...",
            "text": "...",
            "sender_name": "...", // 可选，由 API 或 SDK 补全
            "amount": "...",
            "count": 5
          }
        }
      }
    */

    // OpenIM SDK 自定义消息 data 字段通常是一个 JSON 字符串
    final customDataMap = {
      "type": "RedPacket",
      "packet_id": packetID,
      "text": text,
      "amount": amount,
      "count": count,
      "packetType": int.parse(type),
      "recv_id": recvID,
      "recv_nickname": recvNickname,
      "mine_nums": mineNums,
    };

    final message = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: json.encode(customDataMap),
      extension: '',
      description: '[红包]',
    );

    return OpenIM.iMManager.messageManager.sendMessage(
      message: message,
      userID: isSingle ? id : null,
      groupID: isSingle ? null : id,
      offlinePushInfo: OfflinePushInfo(
        title: "收到红包",
        desc: text,
        iOSBadgeCount: true,
        iOSPushSound: '',
      ),
    );
  }

  void systemInputPopup(Widget content,
      {dynamic Function()? cancel,
      dynamic Function()? confirm,
      barrierDismissible = true,
      Future<bool> Function()? onWillPop,
      String cancelText = "取消",
      String confirmText = "确定"}) {
    Get.defaultDialog(
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0),
      contentPadding:
          EdgeInsets.only(left: 15.w, right: 15.w, bottom: 25.w, top: 25.w),
      radius: 10,
      barrierDismissible: barrierDismissible,
      onWillPop: onWillPop,
      backgroundColor: Colors.white,
      cancel: Offstage(
        offstage: cancel == null ? true : false,
        child: DefaultContainer(
            margin: EdgeInsets.only(top: 15.w),
            width: 107.w,
            child: Defaultbutton(
              function: cancel ?? () {},
              text: cancelText,
              color: const Color(0xff939393),
            )),
      ),
      confirm: Offstage(
        offstage: confirm == null ? true : false,
        child: DefaultContainer(
            margin: EdgeInsets.only(top: 15.w),
            width: 107.w,
            child: Defaultbutton(
              function: confirm ?? () {},
              text: confirmText,
              color: Colors.black,
            )),
      ),
      content: DefaultContainer(
        color: Colors.transparent,
        alignment: Alignment.center,
        width: 291.w,
        child: content,
      ),
    );
  }
}
