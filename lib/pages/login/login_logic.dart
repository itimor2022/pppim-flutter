import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim/pages/mine/server_config/server_config_binding.dart';
import 'package:openim/pages/mine/server_config/server_config_view.dart';
import 'package:openim_common/openim_common.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/controller/app_controller.dart';
import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';

enum LoginType {
  phone,
  username,
}

extension LoginTypeExt on LoginType {
  int get rawValue {
    switch (this) {
      case LoginType.phone:
        return 0;
      case LoginType.username:
        return 1;
    }
  }

  String get name {
    switch (this) {
      case LoginType.phone:
        return StrRes.phoneNumber;
      case LoginType.username:
        return StrRes.account;
    }
  }

  String get hintText {
    switch (this) {
      case LoginType.phone:
        return StrRes.plsEnterPhoneNumber;
      case LoginType.username:
        return StrRes.plsEnterAccount;
    }
  }

  String get exclusiveName {
    switch (this) {
      case LoginType.phone:
        return StrRes.account;
      case LoginType.username:
        return StrRes.account;
    }
  }
}

class LoginLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final pushLogic = Get.find<PushController>();
  final appLogic = Get.find<AppController>();
  final phoneCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();
  final verificationCodeCtrl = TextEditingController();
  final obscureText = true.obs;
  final enabled = false.obs;
  final areaCode = "+86".obs;
  final isPasswordLogin = true.obs;
  final versionInfo = ''.obs;
  final loginType = LoginType.username.obs;

  // 默认客服链接
  static const String defaultCustomerServiceUrl =
      'https://gpo.axe03fm.cfd/chat/index?channelId=d71a0a579fea46f8b48944fbb8da369e';

  String? get phone =>
      loginType.value == LoginType.phone ? phoneCtrl.text.trim() : null;
  String? get account =>
      loginType.value == LoginType.username ? phoneCtrl.text.trim() : null;
  LoginType operateType = LoginType.phone;

  _initData() async {
    loginType.value = LoginType.phone;
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
    // if (!Config.isDynamicHostReady) {
    //   IMViews.showToast("线路初始化中，请稍后");
    //   return;
    // }

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

      final password = IMUtils.emptyStrToNull(pwdCtrl.text);
      final code = IMUtils.emptyStrToNull(verificationCodeCtrl.text);
      final data = await Apis.login(
        areaCode: areaCode.value,
        phoneNumber: phone,
        email: null,
        account: account,
        password: isPasswordLogin.value ? password : null,
        verificationCode: isPasswordLogin.value ? null : code,
      );
      final loginAccount = {
        "areaCode": areaCode.value,
        "phoneNumber": phone,
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

  void toggleLoginType() {}

  Future<bool> getVerificationCode() async {
    if (phone?.isNotEmpty == true &&
        !IMUtils.isMobile(areaCode.value, phoneCtrl.text)) {
      IMViews.showToast(StrRes.plsEnterRightPhone);
      return false;
    }

    return sendVerificationCode();
  }

  /// [usedFor] 1：注册，2：重置密码 3：登录
  Future<bool> sendVerificationCode() => LoadingView.singleton.wrap(
      asyncFunction: () => Apis.requestVerificationCode(
            areaCode: areaCode.value,
            phoneNumber: phone,
            email: null,
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

  String? _getCustomerServiceUrl(Map<String, dynamic> map) {
    // 支持的字段名列表
    final candidates = [
      'customer_service_url',
      'chat_url',
      'discoverPageURL',
      'discover_page_url',
      'discoverPageUrl',
      '客服链接',
      '客服地址',
      '在线客服',
    ];

    for (final key in candidates) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> openCustomerService() async {
    String serviceUrl;

    // 1. 先从缓存的配置中获取
    final cachedUrl = _getCustomerServiceUrl(appLogic.clientConfigMap);

    // 2. 如果缓存有值，使用缓存；否则尝试从后台查询
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      serviceUrl = cachedUrl;
    } else {
      try {
        final map = await appLogic.queryClientConfig();
        final remoteUrl = _getCustomerServiceUrl(map);
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          serviceUrl = remoteUrl;
        } else {
          // 3. 后台也没有，使用默认链接
          serviceUrl = defaultCustomerServiceUrl;
        }
      } catch (e) {
        Logger.print('query client config error: $e');
        // 查询失败，使用默认链接
        serviceUrl = defaultCustomerServiceUrl;
      }
    }

    final uri = Uri.tryParse(serviceUrl);
    final targetUri =
        uri?.hasScheme == true ? uri : Uri.tryParse('https://$serviceUrl');

    if (targetUri == null) {
      IMViews.showToast('客服地址格式不正确，使用默认链接');
      // 使用默认链接重试
      final defaultUri = Uri.tryParse(defaultCustomerServiceUrl);
      if (defaultUri != null) {
        if (!await launchUrl(defaultUri,
            mode: LaunchMode.externalApplication)) {
          IMViews.showToast('无法打开客服页面');
        }
      }
      return;
    }

    if (!await launchUrl(targetUri, mode: LaunchMode.externalApplication)) {
      IMViews.showToast('无法打开客服页面');
    }
  }

  Future<void> switchLine() async {
    try {
      final options = await LoadingView.singleton.wrap(
        asyncFunction: () => Config.fetchManualLineOptions(),
      );

      if (options.isEmpty) {
        IMViews.showToast('未获取到可切换线路');
        return;
      }

      final selected = await Get.bottomSheet<String>(
        _LineSwitchSheet(
          options: options,
          currentHost: Config.serverIp,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

      if (selected == null || selected.trim().isEmpty) {
        return;
      }

      if (selected == Config.serverIp) {
        IMViews.showToast('已是当前线路');
        return;
      }

      final oldHost = Config.serverIp;
      Config.setServerHost(selected, persist: true);

      final reconnected = await LoadingView.singleton.wrap(
        asyncFunction: () => imLogic.reconnectAndVerifyForHostSwitch(),
      );

      if (!reconnected) {
        Config.setServerHost(oldHost, persist: true);
        IMViews.showToast('线路重连校验失败，已回退');
        return;
      }

      IMViews.showToast('已切换线路并完成重连');
    } catch (e) {
      IMViews.showToast('切换线路失败: $e');
    }
  }

  void registerNow() {
    operateType = LoginType.phone;
    AppNavigator.startRegister();
  }

  void forgetPassword() {
    operateType = LoginType.phone;
    AppNavigator.startForgetPassword();
  }

  void getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final appName = packageInfo.appName;

    versionInfo.value = '$appName $version';
  }
}

class _LineSwitchSheet extends StatefulWidget {
  final List<ConfigLineOption> options;
  final String currentHost;

  const _LineSwitchSheet({
    required this.options,
    required this.currentHost,
  });

  @override
  State<_LineSwitchSheet> createState() => _LineSwitchSheetState();
}

class _LineSwitchSheetState extends State<_LineSwitchSheet> {
  late List<ConfigLineOption> _displayOptions;
  final Map<String, ConfigLineOption> _latencyMap = {};
  bool _latencyLoading = true;

  @override
  void initState() {
    super.initState();
    _displayOptions = _orderedOptions(widget.options);
    _loadLatency();
  }

  String _delayText(ConfigLineOption item) {
    if (!item.success) {
      return '超时';
    }
    if (item.duration < 0) {
      return _latencyLoading ? '检测中' : '超时';
    }
    return '${item.duration}ms';
  }

  List<ConfigLineOption> _orderedOptions(List<ConfigLineOption> options) {
    final copied = [...options];
    copied.sort((a, b) {
      final aCurrent = a.host == widget.currentHost;
      final bCurrent = b.host == widget.currentHost;
      if (aCurrent != bCurrent) {
        return aCurrent ? -1 : 1;
      }
      if (a.success != b.success) {
        return a.success ? -1 : 1;
      }
      return a.duration.compareTo(b.duration);
    });
    return copied;
  }

  void _updateLatencyResult(ConfigLineOption result) {
    if (!mounted) return;
    _latencyMap[result.host] = result;
    final merged = widget.options
        .map((option) => _latencyMap[option.host] ?? option)
        .toList();
    setState(() {
      _displayOptions = _orderedOptions(merged);
    });
  }

  Future<void> _loadLatency() async {
    await Config.fetchManualLineLatencies(
      widget.options.map((e) => e.host).toList(),
      onResult: _updateLatencyResult,
    );
    if (!mounted) return;
    setState(() {
      _latencyLoading = false;
      _displayOptions = _orderedOptions(
        widget.options
            .map((option) => _latencyMap[option.host] ?? option)
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: '切换线路'.toText..style = Styles.ts_0C1C33_17sp_medium,
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _displayOptions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _displayOptions[index];
                  final isCurrent = item.host == widget.currentHost;
                  final lineName = '线路${index + 1}';

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Styles.c_0089FF.withOpacity(.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? Styles.c_0089FF
                            : Styles.c_E8EAEF.withOpacity(.7),
                        width: isCurrent ? 1.2 : .8,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        lineName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color:
                              item.success ? Styles.c_0C1C33 : Styles.c_8E9AB0,
                        ),
                      ),
                      subtitle: Text(
                        '延迟: ${_delayText(item)}',
                        style: TextStyle(
                          color:
                              item.success ? Styles.c_0089FF : Styles.c_8E9AB0,
                        ),
                      ),
                      trailing: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Styles.c_0089FF,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: '当前'.toText..style = Styles.ts_FFFFFF_12sp,
                            )
                          : null,
                      onTap: () => Get.back(result: item.host),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: Get.back,
                child: '取消'.toText..style = Styles.ts_8E9AB0_15sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
