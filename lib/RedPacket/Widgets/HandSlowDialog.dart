import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class HandSlowDialog extends StatelessWidget {
  final Future<void> Function()? onViewDetails;
  final String? senderNickname;
  final String? senderFaceUrl;

  const HandSlowDialog({
    Key? key,
    this.onViewDetails,
    this.senderNickname,
    this.senderFaceUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 400.w,
        width: 285.w,
        decoration: BoxDecoration(
          color: const Color(0xFFD64835), // Red packet red
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                AvatarView(
                  url: senderFaceUrl,
                  text: senderNickname,
                  width: 48.h,
                  height: 48.h,
                  isCircle: true,
                ),
                SizedBox(height: 10.h),
                Text(
                  "${senderNickname ?? ''}的红包",
                  style: TextStyle(
                    color: const Color(0xFFFFEAC9),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 100.w),
                Text(
                  "手慢了，红包派完了",
                  style: TextStyle(
                    color: const Color(0xFFFFEAC9),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 100.w),
                Divider(
                  color: const Color(0xFFFFEAC9),
                  thickness: 0.1.w,
                ),
                SizedBox(height: 20.w),
                GestureDetector(
                  onTap: () {
                    if (onViewDetails != null) onViewDetails!();
                  },
                  child: Container(
                    child: Text(
                      "查看大家的手气 >",
                      style: TextStyle(
                        color: const Color(0xFFFFEAC9),
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10.h,
              right: 10.h,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.close,
                  color: const Color(0xFFFFEAC9),
                  size: 30.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
