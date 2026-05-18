import 'dart:convert';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

class GroupInvitePermissionUtil {
  GroupInvitePermissionUtil._();

  static const allowOrdinaryMemberInviteKey = 'allowOrdinaryMemberInvite';

  static bool allowOrdinaryMemberInvite(GroupInfo info) {
    final extra = _parseGroupEx(info.ex);
    final value = extra[allowOrdinaryMemberInviteKey];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized != 'false' && normalized != '0';
    }
    return true;
  }

  static String buildGroupEx(GroupInfo info, bool allowOrdinaryMemberInvite) {
    final extra = _parseGroupEx(info.ex);
    if (allowOrdinaryMemberInvite) {
      extra.remove(allowOrdinaryMemberInviteKey);
    } else {
      extra[allowOrdinaryMemberInviteKey] = false;
    }
    return extra.isEmpty ? '' : jsonEncode(extra);
  }

  static Map<String, dynamic> _parseGroupEx(String? ex) {
    if (ex == null || ex.trim().isEmpty) return {};
    try {
      final extra = jsonDecode(ex);
      if (extra is Map) return Map<String, dynamic>.from(extra);
    } catch (_) {}
    return {};
  }
}
