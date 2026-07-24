import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/controller/app_controller.dart';
import '../../core/controller/im_controller.dart';
import '../../core/controller/push_controller.dart';
import '../../routes/app_navigator.dart';
import '../../routes/app_pages.dart';

class MineLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final appLogic = Get.find<AppController>();
  final appName = ''.obs;
  final version = ''.obs;

  bool get openSignIn => appLogic.openSignIn;
  final pushLogic = Get.find<PushController>();
  late StreamSubscription kickedOfflineSub;

  void viewMyQrcode() => AppNavigator.startMyQrcode();

  void viewMyInfo() => AppNavigator.startMyInfo();

  void copyID() {
    IMUtils.copy(text: imLogic.userInfo.value.userID!);
  }

  void accountSetup() => AppNavigator.startAccountSetup();

  void aboutUs() => AppNavigator.startAboutUs();

  void storageManage() => Get.toNamed(AppRoutes.storageManage);

  void walletBalance() => Get.toNamed(AppRoutes.walletBalance);

  void signIn() => AppNavigator.startSignIn();

  void withdraw() => Get.toNamed(AppRoutes.withdraw);

  void setPayPassword() => Get.toNamed(AppRoutes.setPayPassword);

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

  void logout() async {
    var confirm = await Get.dialog(CustomDialog(title: StrRes.logoutHint));
    if (confirm == true) {
      try {
        await LoadingView.singleton.wrap(asyncFunction: () async {
          await imLogic.logout();
          await DataSp.removeLoginCertificate();
          pushLogic.logout();
        });
        AppNavigator.startLogin();
      } catch (e) {
        IMViews.showToast('e:$e');
      }
    }
  }

  void kickedOffline() async {
    PackageBridge.meetingBridge?.dismiss();
    PackageBridge.rtcBridge?.dismiss();
    Get.snackbar(StrRes.accountWarn, StrRes.accountException);
    await DataSp.removeLoginCertificate();
    pushLogic.logout();
    AppNavigator.startLogin();
  }

  @override
  void onInit() {
    kickedOfflineSub = imLogic.onKickedOfflineSubject.listen((value) {
      kickedOffline();
    });
    super.onInit();
  }

  @override
  void onReady() {
    _loadPackageInfo();
    super.onReady();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    appName.value = info.appName;
    version.value = info.version;
  }

  @override
  void onClose() {
    kickedOfflineSub.cancel();
    super.onClose();
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
