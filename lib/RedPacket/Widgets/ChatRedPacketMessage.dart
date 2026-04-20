// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'CompatibilityWidgets.dart';

// Note: MessageController logic is NOT fully migrated so this widget might need specific controller adjustments when integrating.
// For now, removing `syqf` dependencies.
// Since `MessageController` is not in this directory, we assume it's passed or imported from elsewhere.
// But user instruction is to move UI.
// I will keep `dynamic controller` to avoid import errors for now, or assume usage in the right context.
// Or if I want to be strict, I should import the `MessageController` from openim-demo if it exists, but it doesn't have `redPacketCheck`.
// So I will make controller `dynamic` to allow compilation, as strict type requires importing the class.

class ChatRedPacketMessage extends StatelessWidget {
  final Map item;
  final String msgID;
  final dynamic controller; // Changed to dynamic to avoid import issues

  const ChatRedPacketMessage({
    required this.item,
    required this.msgID,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isOpenedState = _isStateOpened(item, controller, msgID);
    final primaryText = _getPrimaryText(item);
    final statusText = _getStatusText(item, controller, msgID);
    final footerLabel = _getFooterLabel(item);
    final timeText = _getMessageTime(controller, msgID);

    return GestureDetector(
      onTap: () async {
        controller.redPacketCheck(item, msgID);
      },
      child: Container(
        width: 245.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOpenedState
                ? const [Color(0xFFE9B2A9), Color(0xFFD9988D)]
                : const [Color(0xFFE97B68), Color(0xFFD85A47)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10.r,
              offset: Offset(0, 4.w),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.w, 14.w, 12.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.w),
                    child: ColorFiltered(
                      colorFilter: isOpenedState
                          ? const ColorFilter.matrix([
                              0.6, 0.2, 0.2, 0, 8,
                              0.2, 0.6, 0.2, 0, 8,
                              0.2, 0.2, 0.6, 0, 8,
                              0, 0, 0, 1, 0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.srcOver,
                            ),
                      child: Opacity(
                        opacity: isOpenedState ? 0.78 : 1,
                        child: Image.asset(
                          'assets/images/h.png',
                          width: 46.w,
                          height: 46.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultText(
                          text: primaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                        SizedBox(height: 6.w),
                        DefaultText(
                          text: statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 12.sp,
                          textColor: Colors.white.withOpacity(
                            isOpenedState ? 0.72 : 0.88,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: 14.w),
              color: Colors.white.withOpacity(0.35),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 9.w, 14.w, 10.w),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultText(
                      text: footerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 13.sp,
                      textColor: Colors.white.withOpacity(0.92),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  DefaultText(
                    text: timeText,
                    fontSize: 13.sp,
                    textColor: Colors.white.withOpacity(0.92),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isStateOpened(Map item, dynamic logic, String msgID) {
    if (item['isOpen'] == true) return true;
    if (_isOpened(logic, msgID)) return true;
    final status = _getRedPacketStatus(logic, msgID);
    return status == 'finished' || status == 'expired' || status == 'opened';
  }

  bool _isOpened(dynamic logic, String msgID) {
    try {
      if (logic.messageList is! List) return false;
      for (var e in logic.messageList) {
        if (e.clientMsgID == msgID) {
          return e.exMap['redPacketStatus'] == 'opened';
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _getStatusText(Map item, dynamic logic, String msgID) {
    if (item['isOpen'] == true || _isOpened(logic, msgID)) {
      return "红包已被领取";
    }

    final redPacketStatus = _getRedPacketStatus(logic, msgID);
    if (redPacketStatus == 'finished') {
      return "红包已被抢完";
    }
    if (redPacketStatus == 'expired') {
      return "红包已过期";
    }

    return "领取红包";
  }

  String? _getRedPacketStatus(dynamic logic, String msgID) {
    try {
      if (logic.messageList is! List) return null;
      for (var e in logic.messageList) {
        if (e.clientMsgID == msgID) {
          return e.exMap['redPacketStatus'];
        }
      }
    } catch (e) {
      debugPrint('getRedPacketStatus error: $e');
    }
    return null;
  }

  String _getPrimaryText(Map item) {
    final packetType = '${item['packetType'] ?? ''}';
    final recvNickname = item['recv_nickname']?.toString().trim();
    final rawText = ((item['data'] ?? item['text'])?.toString() ?? '').trim();

    if (packetType == '3' && recvNickname != null && recvNickname.isNotEmpty) {
      return '给$recvNickname';
    }
    if (packetType == '6' && rawText.isNotEmpty) {
      return '$rawText [扫雷]';
    }
    return rawText.isEmpty ? '红包消息' : rawText;
  }

  String _getFooterLabel(Map item) {
    switch ('${item['packetType'] ?? ''}') {
      case '2':
        return '拼手气红包';
      case '3':
        return '专属红包';
      case '6':
        return '扫雷红包';
      case '1':
      default:
        return '红包';
    }
  }

  String _getMessageTime(dynamic logic, String msgID) {
    try {
      if (logic.messageList is! List) return '';
      for (var e in logic.messageList) {
        if (e.clientMsgID == msgID && e.sendTime != null) {
          return _formatHourMinute(e.sendTime);
        }
      }
    } catch (e) {
      debugPrint('getMessageTime error: $e');
    }
    return '';
  }

  String _formatHourMinute(int milliseconds) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
