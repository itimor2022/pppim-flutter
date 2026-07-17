import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatNicknameView extends StatelessWidget {
  const ChatNicknameView({
    Key? key,
    this.topWidget,
    this.nickname,
    this.timeStr,
    this.alignEnd = false,
  }) : super(key: key);
  final Widget? topWidget;
  final String? nickname;
  final String? timeStr;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topWidget != null)
          Container(
            margin: EdgeInsets.only(bottom: 4.h),
            child: topWidget,
          ),
        RichText(
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          text: TextSpan(
            text: '',
            style: Styles.ts_8E9AB0_12sp,
            children: [
              if (null != nickname)
                WidgetSpan(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 100.w),
                    margin: EdgeInsets.only(right: 6.w),
                    child: nickname!.toText
                      ..style = Styles.ts_8E9AB0_12sp
                      ..maxLines = 1
                      ..overflow = TextOverflow.ellipsis,
                  ),
                ),
              TextSpan(text: timeStr),
            ],
          ),
        ),
      ],
    );
  }
}
