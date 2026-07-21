import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'login_logic.dart';

class LoginPage extends StatelessWidget {
  final logic = Get.find<LoginLogic>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: TouchCloseSoftKeyboard(
        isGradientBg: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              88.verticalSpace,
              ImageRes.loginLogo.toImage
                ..width = 64.w
                ..height = 64.h
                ..onDoubleTap = logic.configService,
              StrRes.welcome.toText..style = Styles.ts_0089FF_17sp_semibold,
              51.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Obx(() => Column(
                      children: [
                        InputBox.account(
                          label: StrRes.account,
                          hintText: StrRes.plsEnterAccount,
                          code: logic.areaCode.value,
                          onAreaCode: null,
                          controller: logic.phoneCtrl,
                          keyBoardType: TextInputType.text,
                        ),
                        16.verticalSpace,
                        Offstage(
                          offstage: !logic.isPasswordLogin.value,
                          child: InputBox.password(
                            label: StrRes.password,
                            hintText: StrRes.plsEnterPassword,
                            controller: logic.pwdCtrl,
                          ),
                        ),
                        Offstage(
                          offstage: logic.isPasswordLogin.value,
                          child: InputBox.verificationCode(
                            label: StrRes.verificationCode,
                            hintText: StrRes.plsEnterVerificationCode,
                            controller: logic.verificationCodeCtrl,
                            onSendVerificationCode: logic.getVerificationCode,
                          ),
                        ),
                        10.verticalSpace,
                        46.verticalSpace,
                        Button(
                          text: StrRes.login,
                          enabled: logic.enabled.value,
                          onTap: logic.login,
                        ),
                        12.verticalSpace,
                        // 切换线路和在线客服左右分开
                        Row(
                          children: [
                            // 蓝色边框按钮 - 切换线路
                            InkWell(
                              onTap: logic.switchLine,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: const Color(0xFF0089FF),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '切换线路',
                                  style: TextStyle(
                                    color: const Color(0xFF0089FF),
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // 红色边框按钮 - 在线客服
                            InkWell(
                              onTap: logic.openCustomerService,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: const Color(0xFFE57373),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '在线客服',
                                  style: TextStyle(
                                    color: const Color(0xFFB42318),
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        8.verticalSpace,
                      ],
                    )),
              ),
              100.verticalSpace,
              // 美化后的注册按钮
              GestureDetector(
                onTap: logic.registerNow,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0089FF), Color(0xFF4DA6FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0089FF).withOpacity(0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        StrRes.noAccountYet,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        StrRes.registerNow,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
              32.verticalSpace,
              // 版本号改为红色
              Obx(() => logic.versionInfo.value.toText
                ..style = TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                )),
            ],
          ),
        ),
      ),
    );
  }
}
