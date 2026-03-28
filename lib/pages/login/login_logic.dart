import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/pages/mine/server_config/server_config_binding.dart';
import 'package:openim/pages/mine/server_config/server_config_view.dart';
import 'package:openim_common/openim_common.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';

enum LoginType {
  phone,
  email,
  username,
}

extension LoginTypeExt on LoginType {
  int get rawValue {
    switch (this) {
      case LoginType.phone:
        return 0;
      case LoginType.email:
        return 1;
      case LoginType.username:
        return 2;
    }
  }

  String get name {
    switch (this) {
      case LoginType.phone:
        return StrRes.phoneNumber;
      case LoginType.email:
        return StrRes.email;
      case LoginType.username:
        return StrRes.account;
    }
  }

  String get hintText {
    switch (this) {
      case LoginType.phone:
        return StrRes.plsEnterPhoneNumber;
      case LoginType.email:
        return StrRes.plsEnterEmail;
      case LoginType.username:
        return StrRes.plsEnterAccount;
    }
  }

  String get exclusiveName {
    switch (this) {
      case LoginType.phone:
        return StrRes.email;
      case LoginType.email:
        return StrRes.phoneNumber;
      case LoginType.username:
        return StrRes.account;
    }
  }
}

class LoginLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();
  final phoneCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();
  final verificationCodeCtrl = TextEditingController();
  final obscureText = true.obs;
  final enabled = false.obs;
  final areaCode = "+86".obs;
  final isPasswordLogin = true.obs;
  final versionInfo = ''.obs;
  final loginType = LoginType.username.obs;
  String? get email =>
      loginType.value == LoginType.email ? phoneCtrl.text.trim() : null;
  String? get phone =>
      loginType.value == LoginType.phone ? phoneCtrl.text.trim() : null;
  String? get account =>
      loginType.value == LoginType.username ? phoneCtrl.text.trim() : null;
  LoginType operateType = LoginType.username;

  _initData() async {
    var map = DataSp.getLoginAccount();
    if (map is Map) {
      String? phoneNumber = map["phoneNumber"];
      String? areaCode = map["areaCode"];
      String? account = map["account"];
      if (account != null && account.isNotEmpty) {
        phoneCtrl.text = account;
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        phoneCtrl.text = phoneNumber;
      }
      if (areaCode != null && areaCode.isNotEmpty) {
        this.areaCode.value = areaCode;
      }
    }

    int type = await DataSp.getLoginType();
    if (type == 0) {
      loginType.value = LoginType.phone;
    } else if (type == 1) {
      loginType.value = LoginType.email;
    } else {
      loginType.value = LoginType.username;
    }
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    pwdCtrl.dispose();
    verificationCodeCtrl.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    _initData();
    phoneCtrl.addListener(_onChanged);
    pwdCtrl.addListener(_onChanged);
    verificationCodeCtrl.addListener(_onChanged);
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    getPackageInfo();
  }

  _onChanged() {
    enabled.value = isPasswordLogin.value &&
            phoneCtrl.text.trim().isNotEmpty &&
            pwdCtrl.text.trim().isNotEmpty ||
        !isPasswordLogin.value &&
            phoneCtrl.text.trim().isNotEmpty &&
            verificationCodeCtrl.text.trim().isNotEmpty;
  }

  login() {
    DataSp.putLoginType(loginType.value.rawValue);
    LoadingView.singleton.wrap(asyncFunction: () async {
      var suc = await _login();
      if (suc) {
        Get.find<CacheController>().resetCache();
        AppNavigator.startMain();
      }
    });
  }

  Future<bool> _login() async {
    try {
      if (phone?.isNotEmpty == true &&
          !IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
        IMViews.showToast(StrRes.plsEnterRightPhone);
        return false;
      }

      if (email?.isNotEmpty == true && !phoneCtrl.text.isEmail) {
        IMViews.showToast(StrRes.plsEnterRightEmail);
        return false;
      }
      final password = IMUtils.emptyStrToNull(pwdCtrl.text);
      final code = IMUtils.emptyStrToNull(verificationCodeCtrl.text);
      final data = await Apis.login(
        areaCode: areaCode.value,
        phoneNumber: phone,
        email: email,
        account: account,
        password: isPasswordLogin.value ? password : null,
        verificationCode: isPasswordLogin.value ? null : code,
      );
      final loginAccount = {
        "areaCode": areaCode.value,
        "phoneNumber": phone,
        "email": email,
        "account": phoneCtrl.text
      };
      await DataSp.putLoginCertificate(data);
      await DataSp.putLoginAccount(loginAccount);
      Logger.print('login : ${data.userID}, token: ${data.imToken}');
      await imLogic.login(data.userID, data.imToken);
      Logger.print('im login success');
      pushLogic.login(data.userID);
      Logger.print('push login success');
      return true;
    } catch (e, s) {
      Logger.print('login e: $e $s');
    }
    return false;
  }

  void togglePasswordType() {
    isPasswordLogin.value = !isPasswordLogin.value;
  }

  void toggleLoginType() {
    if (loginType.value == LoginType.phone) {
      loginType.value = LoginType.email;
    } else if (loginType.value == LoginType.email) {
      loginType.value = LoginType.username;
    } else {
      loginType.value = LoginType.phone;
    }

    phoneCtrl.text = '';
  }

  Future<bool> getVerificationCode() async {
    if (phone?.isNotEmpty == true &&
        !IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
      IMViews.showToast(StrRes.plsEnterRightPhone);
      return false;
    }

    if (email?.isNotEmpty == true && !phoneCtrl.text.isEmail) {
      IMViews.showToast(StrRes.plsEnterRightEmail);
      return false;
    }

    return sendVerificationCode();
  }

  /// [usedFor] 1：注册，2：重置密码 3：登录
  Future<bool> sendVerificationCode() => LoadingView.singleton.wrap(
      asyncFunction: () => Apis.requestVerificationCode(
            areaCode: areaCode.value,
            phoneNumber: phone,
            email: email,
            usedFor: 3,
          ));

  void openCountryCodePicker() async {
    String? code = await IMViews.showCountryCodePicker();
    if (null != code) areaCode.value = code;
  }

  void configService() => Get.to(
        () => ServerConfigPage(),
        binding: ServerConfigBinding(),
      );

  void registerNow() => AppNavigator.startRegister();

  void forgetPassword() => AppNavigator.startForgetPassword();

  void getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final appName = packageInfo.appName;

    versionInfo.value = '$appName $version';
  }
}
