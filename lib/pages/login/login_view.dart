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
                        // Row(
                        //   children: [
                        //     StrRes.forgetPassword.toText
                        //       ..style = Styles.ts_8E9AB0_12sp
                        //       ..onTap = _showForgetPasswordBottomSheet,
                        //     const Spacer(),
                        //     (logic.isPasswordLogin.value
                        //             ? StrRes.verificationCodeLogin
                        //             : StrRes.passwordLogin)
                        //         .toText
                        //       ..style = Styles.ts_0089FF_12sp
                        //       ..onTap = logic.togglePasswordType,
                        //   ],
                        // ),
                        46.verticalSpace,
                        Button(
                          text: StrRes.login,
                          enabled: logic.enabled.value,
                          onTap: logic.login,
                        ),
                        12.verticalSpace,
                        '切换线路'.toText
                          ..style = Styles.ts_0089FF_14sp
                          ..onTap = logic.switchLine,
                      ],
                    )),
              ),
              100.verticalSpace,
              RichText(
                text: TextSpan(
                  text: StrRes.noAccountYet,
                  style: Styles.ts_8E9AB0_12sp,
                  children: [
                    TextSpan(
                      text: StrRes.registerNow,
                      style: Styles.ts_0089FF_12sp,
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
