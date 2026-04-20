import 'package:get/get.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'Api/RedPacketApi.dart';

class RedPacketRecordsController extends GetxController {
  final radBagList = RadBagItem(
          redLists: [],
          down: false,
          expired: false,
          packetType: 0,
          nickname: "",
          avatar: "",
          redPacketRemarks: "",
          money: '0.00',
          totalAmount: '0.00',
          totalPacket: 0,
          downAmount: '0.00',
          remainingPacket: 0,
          mopTime: "0")
      .obs;

  String packetID = "";

  @override
  void onInit() {
    super.onInit();
    // Assuming arguments is packetID
    if (Get.arguments is String) {
      packetID = Get.arguments;
    } else if (Get.arguments is Map) {
      packetID = Get.arguments['packet_id'] ?? "";
    }
    redPacketReceiveDetail();
  }

  /// 查询红包详情
  void redPacketReceiveDetail() async {
    try {
      final currentUserID = OpenIM.iMManager.userID;
      // 1. 获取红包详情
      final detailMap = await RedPacketApi.getRedPacketDetail(
          packetID: packetID, userID: currentUserID);

      // 2. 构造 RadBagItem
      final detail = RadBagItem.fromApi(detailMap, currentUserID);

      // 3. 补充发送者信息 (昵称/头像)
      if (detail.senderID != null) {
        final userInfos = await OpenIM.iMManager.userManager
            .getUsersInfo(userIDList: [detail.senderID!]);
        if (userInfos.isNotEmpty) {
          detail.nickname = userInfos.first.nickname;
          detail.avatar = userInfos.first.faceURL;
        }
      }

      // 4. 补充领取列表的用户信息
      if (detail.redLists != null && detail.redLists!.isNotEmpty) {
        final userIDs = detail.redLists!
            .where((e) => e.userId != null)
            .map((e) => e.userId!)
            .toList();
        final users = await OpenIM.iMManager.userManager
            .getUsersInfo(userIDList: userIDs);
        final userMap = {for (var u in users) u.userID: u};

        for (var record in detail.redLists!) {
          final u = userMap[record.userId];
          if (u != null) {
            record.nickname = u.nickname;
            record.avatar = u.faceURL;
          }
        }
      }

      // Calculate Best Luck (Hand of God) for Lucky Red Packet (Type 2)
      // Logic: Always show the *current* best luck among retrieved records.
      // Check if backend already determined best luck (field is_best_luck)
      bool hasBestLuck =
          detail.redLists!.any((element) => element.bestLuck == 1);

      if (!hasBestLuck &&
          detail.packetType == 2 &&
          detail.redLists!.isNotEmpty &&
          (detail.remainingPacket == 0 || detail.expired == true)) {
        double maxMoney = 0;
        for (var r in detail.redLists!) {
          double v = double.tryParse(r.money ?? "0") ?? 0;
          if (v > maxMoney) maxMoney = v;
        }
        if (maxMoney > 0) {
          for (var r in detail.redLists!) {
            double v = double.tryParse(r.money ?? "0") ?? 0;
            if ((v - maxMoney).abs() < 0.001) {
              // Float comparison
              r.bestLuck = 1;
            }
          }
        }
      }

      radBagList.value = detail;
    } catch (e) {
      // EasyLoading.showError("获取详情失败");
      print("RedPacketDetail Error: $e");
    }
  }
}

class RadBagItem {
  int? packetType;
  String? nickname;
  String? avatar;
  String? redPacketRemarks;
  String? money; // 当前用户领取的金额
  int? totalPacket;
  int? remainingPacket;
  String? downAmount; // 已领取的总金额
  String? totalAmount; // 红包总金额
  List<RedLists>? redLists;
  bool? down; // 当前用户是否已领取
  bool? expired;
  String? mopTime; // 抢完时间
  String? senderID; // 辅助字段
  bool? isSender;
  String? mineNums; // 扫雷雷号

  RadBagItem({
    this.packetType,
    this.nickname,
    this.avatar,
    this.redPacketRemarks,
    this.money,
    this.totalPacket,
    this.remainingPacket,
    this.downAmount,
    this.totalAmount,
    this.redLists,
    this.down,
    this.mopTime,
    this.expired,
    this.senderID,
    this.isSender,
    this.mineNums,
  });

  // Mapper from API response
  static RadBagItem fromApi(Map<String, dynamic> json, String currentUserID) {
    // API fields: packet_id, sender_id, type, total_amount, total_count, remain_amount, remain_count, status, records

    // API字段: packet_id, sender_id, type, total_amount, total_count, remain_amount, remain_count, status, records

    // 计算值
    final totalAmountFen =
        int.tryParse(json['total_amount']?.toString() ?? "0") ?? 0;
    final remainAmountFen =
        int.tryParse(json['remain_amount']?.toString() ?? "0") ?? 0;

    final totalAmountYuan = _formatFen(json['total_amount']);

    List<RedLists> records = [];
    bool isReceived = false;
    String myMoney = "0.00";

    if (json['records'] != null && json['records'] is List) {
      records =
          (json['records'] as List).map((e) => RedLists.fromApi(e)).toList();
      // 检查当前用户是否已领取
      final myRecord = records
          .firstWhereOrNull((element) => element.userId == currentUserID);
      if (myRecord != null) {
        isReceived = true;
        myMoney = myRecord.money ?? "0.00";
      }
    }

    // 剑盾：如果含有脱敏记录，逐条累加会失败，因此统一采用 [总额 - 剩余额] 来计算已领取的展示金额
    String downAmountYuan = _formatFen(totalAmountFen - remainAmountFen);

    int remainCount = json['remain_count'] ?? json['remainCount'] ?? 0;
    bool isFinished = json['status'] == 2 || remainCount == 0; // 修复: 剩余为0表示已抢完
    bool isExpired =
        json['status'] == 3 && remainCount > 0; // 修复: 只有在有剩余红包时才算过期

    return RadBagItem(
      packetType: json['type'],
      senderID: json['sender_id'],
      nickname: "加载中...", // 待补充
      avatar: "", // 待补充
      redPacketRemarks: json['remark'] ?? "恭喜发财",
      money: myMoney,
      totalPacket: json['total_count'] ?? 0,
      remainingPacket: json['remain_count'] ?? 0,
      downAmount: downAmountYuan,
      totalAmount: totalAmountYuan,
      redLists: records,
      down: isReceived,
      expired: isExpired,
      mopTime: isFinished ? "0" : "0",
      isSender: json['sender_id'] == currentUserID,
      mineNums: json['mine_nums']?.toString(),
    );
  }

  // [剣盾: 核心对齐] 全线禁止四舍五入，必须由“分”整除截断
  static String _formatFen(dynamic fen) {
    if (fen == null) return "0.00";
    String s = fen.toString();
    // 剑盾：如果是已脱敏的字符串（包含*或其他非数字），直接展示不做解析
    if (s.contains("*")) return s;

    int? f = int.tryParse(s);
    if (f == null) return s; // 包含"元"或其他非数字字符，直接原样返回

    return "${f ~/ 100}.${(f % 100).toString().padLeft(2, '0')}";
  }
}

class RedLists {
  String? nickname;
  String? avatar;
  String? userId;
  String? money;
  String? receiveDate;
  int? bestLuck;
  bool? isHit; // 是否中雷

  RedLists(
      {this.nickname,
      this.avatar,
      this.userId,
      this.money,
      this.receiveDate,
      this.bestLuck,
      this.isHit});

  static RedLists fromApi(Map<String, dynamic> json) {
    // 检查 snake_case (通常自定义) 和 camelCase (proto默认)
    bool isBest = json['is_best_luck'] == true || json['isBestLuck'] == true;
    String uid = json['user_id'] ?? json['userId'];

    return RedLists(
      userId: uid,
      money: RadBagItem._formatFen(json['amount']),
      receiveDate: _formatDate(json['create_time']),
      nickname: "加载中...",
      avatar: "",
      bestLuck: isBest ? 1 : 0,
      isHit: json['is_hit'] == true || json['isHit'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["nickname"] = nickname;
    _data["avatar"] = avatar;
    _data["userId"] = userId;
    _data["money"] = money;
    _data["receiveDate"] = receiveDate;
    _data["bestLuck"] = bestLuck;
    return _data;
  }

  static String _formatDate(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "";
    // Regex to match yyyy-MM-dd HH:mm:ss
    final reg = RegExp(r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}");
    final match = reg.firstMatch(timeStr);
    if (match != null) {
      return match.group(0)!;
    }
    // Fallback: split by '.' to remove milliseconds if Go default format
    if (timeStr.contains('.')) {
      return timeStr.split('.').first;
    }
    return timeStr;
  }
}
