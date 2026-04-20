import 'dart:convert';

class UserExUtil {
  UserExUtil._();

  static const String _vipKey = 'vip';
  static const String _prettyKey = 'pretty';
  static const String _allowDoubleDeleteMessageKey = 'allowDoubleDeleteMessage';

  static Map<String, dynamic> parse(String? ex) {
    if (ex == null || ex.trim().isEmpty) return const <String, dynamic>{};
    try {
      final data = jsonDecode(ex);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  static bool isVip(String? ex) {
    final vip = parse(ex)[_vipKey];
    if (vip is bool) return vip;
    if (vip is num) return vip != 0;
    if (vip is String) {
      final value = vip.toLowerCase();
      return value == 'true' || value == '1' || value == 'yes';
    }
    return false;
  }

  static bool isPretty(String? ex) {
    final pretty = parse(ex)[_prettyKey];
    if (pretty is bool) return pretty;
    if (pretty is num) return pretty != 0;
    if (pretty is String) {
      final value = pretty.toLowerCase();
      return value == 'true' || value == '1' || value == 'yes';
    }
    return false;
  }

  static bool allowDoubleDeleteMessage(String? ex) {
    final value = parse(ex)[_allowDoubleDeleteMessageKey];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lowered = value.toLowerCase();
      return lowered == 'true' || lowered == '1' || lowered == 'yes';
    }
    return false;
  }

  static String mergeFlag(String? ex, String key, bool enabled) {
    final data = Map<String, dynamic>.from(parse(ex));
    data[key] = enabled;
    return jsonEncode(data);
  }

  static String mergeAllowDoubleDeleteMessage(String? ex, bool enabled) {
    return mergeFlag(ex, _allowDoubleDeleteMessageKey, enabled);
  }

  static bool boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lowered = value.toLowerCase();
      return lowered == 'true' || lowered == '1' || lowered == 'yes';
    }
    return false;
  }
}
