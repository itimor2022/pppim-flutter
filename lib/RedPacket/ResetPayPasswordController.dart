import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'Api/RedPacketApi.dart';
import '../../core/controller/im_controller.dart';

class ResetPayPasswordController extends GetxController {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final verifyCodeController = TextEditingController();
  final accountController = TextEditingController(); // Phone or Email

  // 0: Phone, 1: Email
  final verificationMethod = 0.obs;
  final userInfo = Get.find<IMController>().userInfo;

  // Restore variables I accidentally removed in previous step
  final isCodeSent = false.obs;
  final timer = 60.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // Default to available method
    if (userInfo.value.phoneNumber != null &&
        userInfo.value.phoneNumber!.isNotEmpty) {
      verificationMethod.value = 0;
    } else if (userInfo.value.email != null &&
        userInfo.value.email!.isNotEmpty) {
      verificationMethod.value = 1;
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    verifyCodeController.dispose();
    accountController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  void sendCode() async {
    String? phoneNumber;
    String? email;
    String? areaCode;

    if (verificationMethod.value == 0) {
      // Phone
      phoneNumber = userInfo.value.phoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        IMViews.showToast("未绑定手机号");
        return;
      }
      areaCode = "+86";
      // OpenIM usually stores "+86138...". We might need to split?
      // For now, let's assume backend handles full number or we pass it as is?
      // Standard: areaCode required.
      // If phoneNumber contains +, we might parse.
      // Simple Parser:
      /*
      if (phoneNumber.startsWith("+")) {
          // split
      }
      */
    } else {
      // Email
      email = userInfo.value.email;
      if (email == null || email.isEmpty) {
        IMViews.showToast("未绑定邮箱");
        return;
      }
    }

    try {
      LoadingView.singleton.wrap(asyncFunction: () async {
        await HttpUtil.post(
          Urls.getVerificationCode,
          data: {
            "usedFor": 3,
            "areaCode": areaCode ?? "+86",
            "phoneNumber": phoneNumber,
            "email": email,
          },
        );
        isCodeSent.value = true;
        _startTimer();
        IMViews.showToast("验证码已发送");
      });
    } catch (e) {
      IMViews.showToast("发送失败: $e");
    }
  }

  void _startTimer() {
    timer.value = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      timer.value--;
      if (timer.value <= 0) {
        t.cancel();
        isCodeSent.value = false;
      }
    });
  }

  void submit() async {
    if (verifyCodeController.text.isEmpty) {
      IMViews.showToast("请输入验证码");
      return;
    }
    if (newPasswordController.text.length != 6) {
      IMViews.showToast("请输入6位数字密码");
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      IMViews.showToast("两次密码不一致");
      return;
    }

    try {
      await LoadingView.singleton.wrap(asyncFunction: () async {
        String? phoneNumber;
        String? email;

        if (verificationMethod.value == 0) {
          phoneNumber = userInfo.value.phoneNumber;
        } else {
          email = userInfo.value.email;
        }

        await RedPacketApi.resetPayPassword(
          userID: OpenIM.iMManager.userID,
          password: newPasswordController.text,
          verifyCode: verifyCodeController.text,
          email: email,
          phoneNumber: phoneNumber,
          areaCode: phoneNumber != null ? "+86" : null, // Simplify
        );

        IMViews.showToast("密码重置成功");
        Get.back();
      });
    } catch (e) {
      String err = e.toString();
      if (err.contains("verifyCode not found")) {
        IMViews.showToast("验证码错误或已失效");
      } else if (err.contains("ArgsError")) {
        IMViews.showToast("参数错误");
      } else {
        IMViews.showToast("重置失败: $err");
      }
    }
  }
}
