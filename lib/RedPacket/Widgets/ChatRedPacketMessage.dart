import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart'; // For Message type if needed?
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
    Key? key,
    required this.item,
    required this.msgID,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isOpenedState = _isStateOpened(item, controller, msgID);
    return GestureDetector(
      onTap: () async {
        controller.redPacketCheck(item, msgID);
      },
      child: Container(
        height: 80.w,
        width: 220.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: Colors.transparent,
          image: DecorationImage(
            image: AssetImage(
              'assets/images/${!isOpenedState ? 214 : 215}.png',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((item['packetType'] == 3 || item['packetType'] == '3') &&
                item['recv_nickname'] != null)
              Container(
                padding: EdgeInsets.only(left: 70.w, top: 15.w, right: 25.w),
                child: DefaultText(
                  text: "给 ${item['recv_nickname']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 16.sp,
                  textColor: Colors.white,
                ),
              ),
            Container(
              padding: EdgeInsets.only(
                  left: 60.w,
                  top: (item['packetType'] == 3 || item['packetType'] == '3') &&
                          item['recv_nickname'] != null
                      ? 2.w
                      : 20.w,
                  bottom: 0.w,
                  right: 10.w),
              child: DefaultText(
                text: (item['packetType'] == 6 || item['packetType'] == '6')
                    ? "${item['data'] ?? item['text']} [扫雷]"
                    : (item['data'] ?? item['text']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                fontSize: 14.sp,
                textColor: !isOpenedState ? Colors.white : Colors.white54,
              ),
            ),
            // Status Overlay
            _buildStatusOverlay(item, controller, msgID),
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

  // Helper for status text
  Widget _buildStatusOverlay(Map item, dynamic logic, String msgID) {
    // If I opened it locally
    if (item['isOpen'] == true || _isOpened(logic, msgID)) {
      return _statusText("已领取");
    }

    // Check if finished (packetStatus=2) or Expired (packetStatus=3)
    // This requires the message to have updated 'custom data' or 'exMap'
    // pushed from backend via WS or updated locally after click.
    // Assuming 'packetStatus' key is injected into exMap or item data.
    // Since backend logic pushes update, we check item data first.
    /*
      Note: Real-time update requires WS handling. 
      For now, we rely on local 'redPacketStatus' update from check.
     */
    // Check local status for finished/expired
    final redPacketStatus = _getRedPacketStatus(logic, msgID);
    if (redPacketStatus == 'finished') {
      return _statusText("已抢完");
    }
    if (redPacketStatus == 'expired') {
      return _statusText("已过期");
    }

    return SizedBox();
  }

  String? _getRedPacketStatus(dynamic logic, String msgID) {
    try {
      if (logic.messageList is! List) return null;
      for (var e in logic.messageList) {
        if (e.clientMsgID == msgID) {
          return e.exMap['redPacketStatus'];
        }
      }
    } catch (e) {}
    return null;
  }

  Widget _statusText(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 70.w, bottom: 10.w),
      child: DefaultText(
        text: text,
        textColor: Colors.white54,
        fontSize: 12.sp,
      ),
    );
  }
}
