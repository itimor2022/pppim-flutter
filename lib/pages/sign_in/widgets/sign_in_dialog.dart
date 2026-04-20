import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SignInDialog extends StatelessWidget {
  const SignInDialog({
    super.key,
    required this.rewardText,
    required this.signing,
    required this.onSignIn,
  });

  final String rewardText;
  final bool signing;
  final Future<void> Function() onSignIn;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 312.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30.r,
                offset: Offset(0, 16.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 26.h),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28.r)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFC66E), Color(0xFFFF8A5C)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58.w,
                      height: 58.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    14.verticalSpace,
                    Text(
                      '今日签到奖励',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    10.verticalSpace,
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '¥',
                            style: TextStyle(
                              fontSize: 22.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: rewardText,
                            style: TextStyle(
                              fontSize: 34.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 22.h),
                child: Column(
                  children: [
                    Text(
                      '连续打开应用别忘了顺手签到，奖励会直接发到钱包余额。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.6,
                        color: const Color(0xFF7E889B),
                      ),
                    ),
                    20.verticalSpace,
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: signing
                            ? null
                            : () async {
                                await onSignIn();
                              },
                        child: Container(
                          height: 46.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: signing
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD9AF),
                                      Color(0xFFFFD9AF)
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFFA53C),
                                      Color(0xFFFF784E)
                                    ],
                                  ),
                          ),
                          child: Text(
                            signing ? '签到中...' : '立即签到',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    14.verticalSpace,
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        '稍后再说',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF99A2B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
