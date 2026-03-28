class RedPacketDetail {
  String? packetID;
  String? senderID;
  int? type;
  String? totalAmount;
  int? totalCount;
  String? remainAmount;
  int? remainCount;
  int? status; // 1=进行中, 2=已抢完, 3=已过期
  String? createTime;
  List<GrabRecord>? records;

  RedPacketDetail({
    this.packetID,
    this.senderID,
    this.type,
    this.totalAmount,
    this.totalCount,
    this.remainAmount,
    this.remainCount,
    this.status,
    this.createTime,
    this.records,
  });

  RedPacketDetail.fromJson(Map<String, dynamic> json) {
    packetID = json['packet_id'];
    senderID = json['sender_id'];
    type = json['type'];
    totalAmount = json['total_amount'];
    totalCount = json['total_count'];
    remainAmount = json['remain_amount'];
    remainCount = json['remain_count'];
    status = json['status'];
    createTime = json['create_time'];
    if (json['records'] != null) {
      records = <GrabRecord>[];
      json['records'].forEach((v) {
        records!.add(GrabRecord.fromJson(v));
      });
    }
  }
}

class GrabRecord {
  String? userID;
  String? amount;
  String? createTime;

  GrabRecord({this.userID, this.amount, this.createTime});

  GrabRecord.fromJson(Map<String, dynamic> json) {
    userID = json['user_id'];
    amount = json['amount'];
    createTime = json['create_time'];
  }
}
