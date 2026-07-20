import 'dart:convert';

/// 提现方式类型
enum WithdrawMethodType {
  alipay, // 支付宝
  bankCard, // 银行卡
}

extension WithdrawMethodTypeExt on WithdrawMethodType {
  String get label {
    switch (this) {
      case WithdrawMethodType.alipay:
        return "支付宝";
      case WithdrawMethodType.bankCard:
        return "银行卡";
    }
  }

  String get code {
    switch (this) {
      case WithdrawMethodType.alipay:
        return "alipay";
      case WithdrawMethodType.bankCard:
        return "bankCard";
    }
  }

  static WithdrawMethodType fromCode(String? code) {
    switch (code) {
      case "bankCard":
        return WithdrawMethodType.bankCard;
      case "alipay":
      default:
        return WithdrawMethodType.alipay;
    }
  }
}

/// 单条提现方式数据模型
class WithdrawMethod {
  final String id;
  final WithdrawMethodType type;
  final String account;
  final String name;
  final String? bankName;

  WithdrawMethod({
    required this.id,
    required this.type,
    required this.account,
    required this.name,
    this.bankName,
  });

  factory WithdrawMethod.fromJson(Map<String, dynamic> json) {
    return WithdrawMethod(
      id: json["id"]?.toString() ?? "",
      type: WithdrawMethodTypeExt.fromCode(json["type"]?.toString()),
      account: json["account"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      bankName: json["bankName"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type.code,
      "account": account,
      "name": name,
      if ((bankName ?? "").isNotEmpty) "bankName": bankName,
    };
  }

  /// 账号脱敏，仅保留末4位，用于 App 内自我查看列表时展示
  String get maskedAccount {
    if (account.length <= 4) return account;
    return "${'*' * (account.length - 4)}${account.substring(account.length - 4)}";
  }

  /// App 内展示用的简要描述（脱敏）
  String get displayText => "${type.label} · $maskedAccount · $name";

  /// 生成提交给后端 remark 字段的字符串，供后台审核处理时使用
  /// 采用固定分隔符格式，账号为完整明文，方便管理员线下转账
  /// 格式：WM|类型代码|完整账号|姓名|银行名称
  String toSubmitPayload() {
    return "WM|${type.code}|$account|$name|${bankName ?? ''}";
  }

  WithdrawMethod copyWith({
    WithdrawMethodType? type,
    String? account,
    String? name,
    String? bankName,
  }) {
    return WithdrawMethod(
      id: id,
      type: type ?? this.type,
      account: account ?? this.account,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
    );
  }
}

/// 从用户 ex 字段中管理提现方式列表的工具类
class WithdrawMethodUtil {
  static const String _key = "withdrawMethods";

  static Map<String, dynamic> _decodeEx(String? ex) {
    if (ex == null || ex.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(ex);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  static List<WithdrawMethod> list(String? ex) {
    final map = _decodeEx(ex);
    final raw = map[_key];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => WithdrawMethod.fromJson(e))
        .toList();
  }

  static String upsert(String? ex, WithdrawMethod method) {
    final map = _decodeEx(ex);
    final methods = list(ex);
    final index = methods.indexWhere((m) => m.id == method.id);
    if (index >= 0) {
      methods[index] = method;
    } else {
      methods.add(method);
    }
    map[_key] = methods.map((m) => m.toJson()).toList();
    return jsonEncode(map);
  }

  static String remove(String? ex, String id) {
    final map = _decodeEx(ex);
    final methods = list(ex)..removeWhere((m) => m.id == id);
    map[_key] = methods.map((m) => m.toJson()).toList();
    return jsonEncode(map);
  }

  static String generateId() {
    return "wm_${DateTime.now().microsecondsSinceEpoch}";
  }
}
