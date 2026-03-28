import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'CompatibilityWidgets.dart';

class OpenRedPacketDialog extends StatelessWidget {
  final String content;
  final String nickname;
  final String headimg;
  final String id;
  final String msgId;
  final int status;
  final Function(String, String) onReceive;
  final Function()? onViewDetails;
  final bool isSender;

  const OpenRedPacketDialog({
    Key? key,
    required this.content,
    required this.nickname,
    required this.headimg,
    required this.id,
    required this.msgId,
    required this.onReceive,
    this.onViewDetails,
    this.status = 0,
    this.isSender = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: 100.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Center(
                  child: DefaultContainer(
                    color: Colors.transparent,
                    assetSrc: 'assets/images/218.png',
                    height: 472.w,
                    width: 285.w,
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AvatarView(
                        url: headimg,
                        text: nickname,
                        width: 24.w,
                        height: 24.w,
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        textStyle: Styles.ts_FFFFFF_14sp,
                      ),
                      SizedBox(
                        width: 5.w,
                      ),
                      DefaultText(
                        text: nickname,
                        textColor: const Color(0xffFFE9C7),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20.w, // Moved up from 0 to avoid bottom edge issues
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (status == 0)
                        DefaultContainer(
                          onTap: () => onReceive(id, msgId),
                          color: Colors.transparent,
                          assetSrc: 'assets/images/219.png',
                          height: 84.w,
                          width: 84.w,
                        ),
                      SizedBox(height: 12.w),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: DefaultText(
                          text: content,
                          textColor: const Color(0xffFFE9C7),
                          fontSize: 18.sp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 30.w), // Increased spacing
                      if (isSender)
                        GestureDetector(
                          onTap: onViewDetails,
                          child: Text(
                            "查看大家的手气 >",
                            style: TextStyle(
                              color: const Color(0xffFFE9C7),
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      SizedBox(height: 10.w)
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 38.w),
            IconButton(
              onPressed: () => Get.back(),
              icon: Image.asset(
                'assets/images/213.png',
                width: 35.w,
                height: 35.w,
              ),
            )
          ],
        ),
      ),
    );
  }
}
