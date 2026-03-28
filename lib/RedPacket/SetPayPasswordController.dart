import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'Api/RedPacketApi.dart';

class SetPayPasswordController extends GetxController {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // "1": Set new password, "2": Change password
  // Assuming if we just have one page, we might assume modify?
  // Or user never set password before?
  // For simplicity, we can have "Old Password" field optional if it's first time,
  // but usually we rely on current state.
  // Docs say "old_password: 首次设置时为空".
  // So we let user input it.

  void setPassword() async {
    final oldPwd = oldPasswordController.text;
    final newPwd = newPasswordController.text;
    final confirmPwd = confirmPasswordController.text;

    if (newPwd.isEmpty) {
      EasyLoading.showToast("请输入新密码");
      return;
    }
    if (newPwd.length < 6) {
      EasyLoading.showToast("密码长度至少6位");
      return;
    }

    if (newPwd != confirmPwd) {
      EasyLoading.showToast("两次输入的密码不一致");
      return;
    }

    try {
      EasyLoading.show();
      final userID = OpenIM.iMManager.userID;
      await RedPacketApi.setPayPassword(
        userID: userID,
        oldPassword: oldPwd.isEmpty ? null : oldPwd,
        newPassword: newPwd,
      );
      EasyLoading.showToast("设置成功");
      Get.back();
    } catch (e) {
      String err = e.toString();
      if (err.contains("old password required") || err.contains("ArgsError")) {
        EasyLoading.showToast("请输入旧密码");
      } else if (err.contains("password incorrect") ||
          err.contains("PasswordError")) {
        EasyLoading.showToast("旧密码错误");
      } else {
        EasyLoading.showToast("设置失败: $err");
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
