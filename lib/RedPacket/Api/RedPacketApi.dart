import 'package:openim_common/openim_common.dart';
import 'package:dio/dio.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

class RedPacketApi {
  static Options get chatTokenOptions =>
      Options(headers: {'token': DataSp.chatToken});

  /// 1. 发送红包
  static Future<Map<String, dynamic>> sendRedPacket({
    required String clientMsgID,
    required String userID,
    required int type, // 1:普通, 2:拼手气, 3:专属
    required String amount, // 单位：分
    required int count,
    String? recvID,
    String? conversationID,
    required String password,
    String? mineNums,
    String? odds,
    bool? isMulti,
    int? mineCount,
    String? remark,
  }) async {
    return await HttpUtil.post(
      Urls.sendRedPacket,
      data: {
        "client_msg_id": clientMsgID,
        "user_id": userID,
        "type": type,
        "amount": amount,
        "count": count,
        "recv_id": recvID,
        "conversation_id": conversationID,
        "password": password,
        "mine_nums": mineNums,
        "odds": odds,
        "is_multi": isMulti,
        "mine_count": mineCount,
        "remark": remark,
      },
      options: chatTokenOptions,
    );
  }

  /// 2. 抢红包
  static Future<Map<String, dynamic>> grabRedPacket({
    required String packetID,
    required String userID,
  }) async {
    return await HttpUtil.post(
      Urls.grabRedPacket,
      data: {
        "packet_id": packetID,
        "user_id": userID,
      },
      options: chatTokenOptions,
      showErrorToast: false, // Suppress default toasts to handle 20018 smoothly
    );
  }

  /// 3. 查询红包详情
  static Future<Map<String, dynamic>> getRedPacketDetail({
    required String packetID,
    required String userID,
  }) async {
    return await HttpUtil.post(
      Urls.getRedPacketDetail,
      data: {
        "packet_id": packetID,
        "user_id": userID,
      },
      options: chatTokenOptions,
    );
  }

  /// 4. 查询钱包余额
  static Future<Map<String, dynamic>> getWalletBalance({
    required String userID,
  }) async {
    return await HttpUtil.post(
      Urls.getWalletBalance,
      data: {
        "user_id": userID,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> transfer({
    required String userID,
    required String recvUserID,
    required String amount,
    required String password,
    String? remark,
  }) async {
    return await HttpUtil.post(
      Urls.transfer,
      data: {
        "user_id": userID,
        "recv_user_id": recvUserID,
        "amount": amount,
        "password": password,
        "remark": remark,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> applyWithdraw({
    required String amount,
    required String password,
    String? remark,
  }) async {
    return await HttpUtil.post(
      Urls.applyWithdraw,
      data: {
        "amount": amount,
        "password": password,
        "remark": remark,
      },
      options: chatTokenOptions,
    );
  }

  /// 5. 设置支付密码
  static Future<dynamic> setPayPassword({
    required String userID,
    required String? oldPassword,
    required String newPassword,
  }) async {
    return await HttpUtil.post(
      Urls.setPayPassword,
      data: {
        "user_id": userID,
        "old_password": oldPassword ?? "",
        "new_password": newPassword,
      },
      options: chatTokenOptions,
      showErrorToast: false,
    );
  }

  /// 6. 验证支付密码
  static Future<Map<String, dynamic>> verifyPayPassword({
    required String userID,
    required String password,
  }) async {
    return await HttpUtil.post(
      Urls.verifyPayPassword,
      data: {
        "user_id": userID,
        "password": password,
      },
      options: chatTokenOptions,
    );
  }

  /// 7. 重置支付密码
  static Future<dynamic> resetPayPassword({
    required String userID,
    required String password,
    required String verifyCode,
    String? areaCode,
    String? phoneNumber,
    String? email,
  }) async {
    return await HttpUtil.post(
      Urls.resetPayPassword,
      data: {
        "user_id": userID,
        "password": password,
        "verify_code": verifyCode,
        "area_code": areaCode,
        "phone_number": phoneNumber,
        "email": email,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> getSendRedPacketList({
    required int page,
    required int limit,
    int? year,
  }) async {
    return await HttpUtil.post(
      Urls.getSendRedPacketList,
      data: {
        "user_id": OpenIM.iMManager.userID,
        "page": page,
        "limit": limit,
        "year": year,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> getRecvRedPacketList({
    required int page,
    required int limit,
    int? year,
  }) async {
    return await HttpUtil.post(
      Urls.getRecvRedPacketList,
      data: {
        "user_id": OpenIM.iMManager.userID,
        "page": page,
        "limit": limit,
        "year": year,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> getWalletRecords({
    required int page,
    required int limit,
    required int type, // 1: Income, 2: Expense
    int? year,
  }) async {
    return await HttpUtil.post(
      Urls.getWalletRecords,
      data: {
        "user_id": OpenIM.iMManager.userID,
        "page": page,
        "limit": limit,
        "year": year,
        "type": type,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> getSignInStatus() async {
    return await HttpUtil.post(
      Urls.getSignInStatus,
      data: {},
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> signIn() async {
    return await HttpUtil.post(
      Urls.signIn,
      data: {},
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> getSignInCalendar({
    int? year,
    int? month,
  }) async {
    return await HttpUtil.post(
      Urls.getSignInCalendar,
      data: {
        "year": year,
        "month": month,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> getGroupPinnedMessage({
    required String groupID,
  }) async {
    return await HttpUtil.post(
      Urls.getGroupPinnedMessage,
      data: {
        "group_id": groupID,
      },
      options: chatTokenOptions,
      showErrorToast: false,
    );
  }

  static Future<Map<String, dynamic>> setGroupPinnedMessage({
    required String groupID,
    required String conversationID,
    required String clientMsgID,
    required String sendID,
    required String senderNickname,
    required int contentType,
    required String preview,
    required int sendTime,
  }) async {
    return await HttpUtil.post(
      Urls.setGroupPinnedMessage,
      data: {
        "group_id": groupID,
        "conversation_id": conversationID,
        "client_msg_id": clientMsgID,
        "send_id": sendID,
        "sender_nickname": senderNickname,
        "content_type": contentType,
        "preview": preview,
        "send_time": sendTime,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> clearGroupPinnedMessage({
    required String groupID,
  }) async {
    return await HttpUtil.post(
      Urls.clearGroupPinnedMessage,
      data: {
        "group_id": groupID,
      },
      options: chatTokenOptions,
    );
  }

  static Future<Map<String, dynamic>> doubleDeleteMessage({
    required String conversationID,
    required String clientMsgID,
    required int seq,
  }) async {
    return await HttpUtil.post(
      Urls.doubleDeleteMessage,
      data: {
        "conversation_id": conversationID,
        "client_msg_id": clientMsgID,
        "seq": seq,
      },
      options: chatTokenOptions,
    );
  }
}
