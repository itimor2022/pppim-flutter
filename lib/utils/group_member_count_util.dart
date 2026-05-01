import 'dart:convert';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

class GroupMemberCountUtil {
  GroupMemberCountUtil._();

  static int getDisplayMemberCount(GroupInfo info) {
    final realMemberCount = info.memberCount ?? 0;
    if (info.ex?.isNotEmpty == true) {
      try {
        final extra = jsonDecode(info.ex!);
        if (extra is! Map) return realMemberCount;
        final displayMemberCount = _parseInt(extra['displayMemberCount']);
        if (displayMemberCount != null && displayMemberCount > 0) {
          final displayMemberCountBase =
              _parseInt(extra['displayMemberCountBase']);
          if (displayMemberCountBase != null && displayMemberCountBase >= 0) {
            final count =
                displayMemberCount + realMemberCount - displayMemberCountBase;
            return count > 0 ? count : 0;
          }
          return displayMemberCount;
        }
      } catch (_) {}
    }
    return realMemberCount;
  }

  static String getDisplayMemberCountText(GroupInfo info) {
    return '${getDisplayMemberCount(info)}人';
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
