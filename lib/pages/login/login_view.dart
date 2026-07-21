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
              RichText(
                text: TextSpan(
                  text: StrRes.noAccountYet,
                  style: Styles.ts_8E9AB0_14sp,
                  children: [
                    TextSpan(
                      text: StrRes.registerNow,
                      style: Styles.ts_0089FF_14sp,
                      recognizer: TapGestureRecognizer()
                        ..onTap = logic.registerNow,
                    )
                  ],
                ),
              ),
              32.verticalSpace,
              Obx(() => logic.versionInfo.value.toText
                ..style = Styles.ts_0C1C33_14sp),
            ],
          ),
        ),
      ),
    );
  }
}
