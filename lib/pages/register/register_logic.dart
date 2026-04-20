import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';

import 'register_mode.dart';

class RegisterLogic extends GetxController {
  final phoneCtrl = TextEditingController();
  final invitationCodeCtrl = TextEditingController();
  final areaCode = "+86".obs;
  final enabled = false.obs;
  String? get phone => phoneCtrl.text.trim();
  String? get account => phoneCtrl.text.trim();

  @override
  void onClose() {
    phoneCtrl.dispose();
    invitationCodeCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    phoneCtrl.addListener(_onChanged);
    invitationCodeCtrl.addListener(_onChanged);
    super.onInit();
  }

  _onChanged() {
    enabled.value = phoneCtrl.text.trim().isNotEmpty &&
        invitationCodeCtrl.text.trim().isNotEmpty;
  }

  String? get invitationCode => IMUtils.emptyStrToNull(invitationCodeCtrl.text);

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) areaCode.value = code;
  }

  void next() async {
    if (invitationCode == null) {
      IMViews.showToast('请输入上级ID');
      return;
    }

    if (!kRegisterByAccount &&
        !IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
      IMViews.showToast(StrRes.plsEnterRightPhone);
      return;
    }

    AppNavigator.startSetPassword(
      areaCode: areaCode.value,
      phoneNumber: kRegisterByAccount ? null : phone,
      account: kRegisterByAccount ? account : null,
      verificationCode: '666666',
      usedFor: 1,
      invitationCode: invitationCode,
    );
  }
}
