import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatTransferMessage extends StatelessWidget {
  const ChatTransferMessage({
    super.key,
    required this.item,
    required this.message,
  });

  final Map item;
  final Message message;

  @override
  Widget build(BuildContext context) {
    final amountFen = int.tryParse('${item['amount'] ?? 0}') ?? 0;
    final amountText = (amountFen / 100).toStringAsFixed(2);
    final remark = ((item['remark'] ?? item['text'])?.toString() ?? '').trim();
    final isSendByMe = message.sendID == OpenIM.iMManager.userID;
    final title = isSendByMe ? '转账给对方' : '收到一笔转账';
    final status = isSendByMe ? '已转入对方钱包' : '已存入你的钱包';

    return Container(
      width: 245.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSendByMe
              ? const [Color(0xFFFFB465), Color(0xFFF07A58)]
              : const [Color(0xFFFFD27F), Color(0xFFF39B5B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x241F1206),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 13.w, 14.w, 10.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.currency_exchange_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        '¥$amountText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (remark.isNotEmpty && remark != '转账') ...[
                        SizedBox(height: 3.h),
                        Text(
                          remark,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 14.w),
            color: Colors.white.withOpacity(0.3),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 8.w, 14.w, 9.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '转账',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
