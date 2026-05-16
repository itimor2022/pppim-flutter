import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart' as im;
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';

import '../../utils/upgrade_manager.dart';
import 'im_controller.dart';
import 'push_controller.dart';

class AppController extends SuperController with UpgradeManger {
  var isRunningBackground = false;
  var isAppBadgeSupported = false;
  var _backgroundExecutionReady = false;
  var _foregroundServiceStarted = false;
  var _iosKeepAlivePlaying = false;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    onDidReceiveLocalNotification: (
      int id,
      String? title,
      String? body,
      String? payload,
    ) async {},
  );

  MeetingBridge? meetingBridge = PackageBridge.meetingBridge;

  RTCBridge? rtcBridge = PackageBridge.rtcBridge;

  bool get shouldMuted =>
      meetingBridge?.hasConnection == true || rtcBridge?.hasConnection == true;

  final _ring = 'assets/audio/message_ring.wav';
  final _audioPlayer = AudioPlayer(
      // Handle audio_session events ourselves for the purpose of this demo.
      // handleInterruptions: false,
      // androidApplyAudioAttributes: false,
      // handleAudioSessionActivation: false,
      );
  final _keepAlivePlayer = AudioPlayer();

  late BaseDeviceInfo deviceInfo;

  /// discoverPageURL
  /// ordinaryUserAddFriend,
  /// bossUserID,
  /// adminURL ,
  /// allowSendMsgNotFriend
  /// needInvitationCodeRegister
  /// robots
  final clientConfigMap = <String, dynamic>{}.obs;
  bool get openSignIn {
    final value =
        clientConfigMap['openSignIn'] ?? clientConfigMap['open_sign_in'];
    if (value is num) return value == 1;
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  bool get showGroupAllMembers {
    final value = clientConfigMap['allowViewGroupMembers'] ??
        clientConfigMap['allow_view_group_members'];
    if (value is num) return value == 1;
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  int get revokeMessageDurationMinutes {
    final value = clientConfigMap['revokeMessageDurationMinutes'] ??
        clientConfigMap['revoke_message_duration_minutes'];
    if (value is num) return value.toInt() > 0 ? value.toInt() : 5;
    if (value is String) {
      final minutes = int.tryParse(value.trim());
      return minutes != null && minutes > 0 ? minutes : 5;
    }
    return 5;
  }

  Future<void> runningBackground(bool run) async {
    Logger.print('-----App running background : $run-------------');

    if (isRunningBackground && !run) {}
    isRunningBackground = run;
    Get.find<IMController>().backgroundSubject.sink.add(run);
    await _syncKeepAliveState();
    if (!run) {
      _cancelAllNotifications();
    }
  }

  @override
  void onInit() async {
    _requestPermissions();
    _initPlayer();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) {},
    );
    await _initBackgroundExecution();
    await _configureKeepAliveAudioSession();
    await _initKeepAlivePlayer();
    await _syncKeepAliveState(force: true);
    isAppBadgeSupported = await FlutterAppBadger.isAppBadgeSupported();
    super.onInit();
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNotification(im.Message message,
      {bool showNotification = true}) async {
    if (_isGlobalNotDisturb() ||
            message.attachedInfoElem?.notSenderNotificationPush == true ||
            message.contentType == im.MessageType.typing ||
            message.sendID ==
                OpenIM.iMManager
                    .userID /* ||
        message.contentType! >= 1000*/
        ) return;

    // 开启免打扰的不提示
    var sourceID = message.sessionType == ConversationType.single
        ? message.sendID
        : message.groupID;
    if (sourceID != null && message.sessionType != null) {
      var i = await OpenIM.iMManager.conversationManager.getOneConversation(
        sourceID: sourceID,
        sessionType: message.sessionType!,
      );
      if (i.recvMsgOpt != 0) return;
    }

    if (showNotification) {
      promptSoundOrNotification(message.seq!);
    }
  }

  Future<void> promptSoundOrNotification(int seq) async {
    if (!isRunningBackground) {
      _playMessageSound();
    } else {
      if (Platform.isAndroid) {
        final id = seq;

        const androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'chat', 'OpenIM聊天消息',
            channelDescription: '来自OpenIM的信息',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
            id, '您收到了一条新消息', '消息内容：.....', platformChannelSpecifics,
            payload: '');
      }
    }
  }

  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _initBackgroundExecution() async {
    if (!Platform.isAndroid) return;
    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'OpenIM 后台运行中',
        notificationText: '保持连接活跃，确保消息及时送达',
        notificationImportance: AndroidNotificationImportance.High,
        notificationIcon:
            AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        enableWifiLock: true,
        shouldRequestBatteryOptimizationsOff: true,
      );
      _backgroundExecutionReady =
          await FlutterBackground.initialize(androidConfig: androidConfig);
      Logger.print(
          'android background execution ready: $_backgroundExecutionReady');
    } catch (e) {
      _backgroundExecutionReady = false;
      Logger.print('init android background execution error: $e');
    }
  }

  Future<void> _startForegroundService() async {
    if (!Platform.isAndroid || _foregroundServiceStarted) return;
    await getAppInfo();
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'pro', 'OpenIM后台进程',
        channelDescription: '保证app能收到信息',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.startForegroundService(1, packageInfo!.appName, '正在运行...',
            notificationDetails: androidPlatformChannelSpecifics, payload: '');
    _foregroundServiceStarted = true;
  }

  Future<void> _stopForegroundService() async {
    if (!Platform.isAndroid || !_foregroundServiceStarted) return;
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.stopForegroundService();
    _foregroundServiceStarted = false;
  }

  Future<void> _initKeepAlivePlayer() async {
    await _keepAlivePlayer.setAsset(_ring, package: 'openim_common');
    await _keepAlivePlayer.setLoopMode(LoopMode.one);
    await _keepAlivePlayer.setVolume(0.01);
  }

  Future<void> _configureKeepAliveAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (e) {
      Logger.print('configure ios keep alive audio session error: $e');
    }
  }

  Future<void> _syncKeepAliveState({bool force = false}) async {
    if (Platform.isAndroid) {
      if (_backgroundExecutionReady && (isRunningBackground || force)) {
        try {
          await FlutterBackground.enableBackgroundExecution();
        } catch (e) {
          Logger.print('enable android background execution error: $e');
        }
      } else if (_backgroundExecutionReady &&
          FlutterBackground.isBackgroundExecutionEnabled) {
        try {
          await FlutterBackground.disableBackgroundExecution();
        } catch (e) {
          Logger.print('disable android background execution error: $e');
        }
      }
      if (isRunningBackground || force) {
        await _startForegroundService();
      } else {
        await _stopForegroundService();
      }
      return;
    }
    if (!Platform.isIOS) return;

    if (isRunningBackground) {
      if (!_iosKeepAlivePlaying || force) {
        try {
          await _keepAlivePlayer.seek(Duration.zero);
          await _keepAlivePlayer.play();
          _iosKeepAlivePlaying = true;
        } catch (e) {
          Logger.print('start ios keep alive audio error: $e');
        }
      }
    } else if (_iosKeepAlivePlaying || force) {
      try {
        await _keepAlivePlayer.stop();
      } catch (e) {
        Logger.print('stop ios keep alive audio error: $e');
      }
      _iosKeepAlivePlaying = false;
    }
  }

  void showBadge(count) {
    if (isAppBadgeSupported) {
      OpenIM.iMManager.messageManager.setAppBadge(count);

      if (count == 0) {
        removeBadge();
        PushController.resetBadge();
      } else {
        FlutterAppBadger.updateBadgeCount(count);
        PushController.setBadge(count);
      }
    }
  }

  void removeBadge() {
    FlutterAppBadger.removeBadge();
  }

  @override
  void onClose() {
    // backgroundSubject.close();
    _stopForegroundService();
    closeSubject();
    _audioPlayer.dispose();
    _keepAlivePlayer.dispose();
    super.onClose();
  }

  Locale? getLocale() {
    var local = Get.locale;
    var index = DataSp.getLanguage() ?? 0;
    switch (index) {
      case 1:
        local = const Locale('zh', 'CN');
        break;
      case 2:
        local = const Locale('en', 'US');
        break;
    }
    return local;
  }

  @override
  void onReady() {
    _syncKeepAliveState(force: true);
    queryClientConfig();
    _getDeviceInfo();
    _cancelAllNotifications();
    autoCheckVersionUpgrade();
    super.onReady();
  }

  /// 全局免打扰
  bool _isGlobalNotDisturb() {
    bool isRegistered = Get.isRegistered<IMController>();
    if (isRegistered) {
      var logic = Get.find<IMController>();
      return logic.userInfo.value.globalRecvMsgOpt == 2;
    }
    return false;
  }

  void _initPlayer() {
    _audioPlayer.setAsset(_ring, package: 'openim_common');
    // _audioPlayer.setLoopMode(LoopMode.off);
    // _audioPlayer.setVolume(1.0);
    _audioPlayer.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
        case ProcessingState.loading:
        case ProcessingState.buffering:
        case ProcessingState.ready:
          break;
        case ProcessingState.completed:
          _stopMessageSound();
          // _audioPlayer.seek(null);
          break;
      }
    });
  }

  /// 播放提示音
  void _playMessageSound() async {
    if (shouldMuted) {
      return;
    }
    bool isRegistered = Get.isRegistered<IMController>();
    bool isAllowVibration = true;
    bool isAllowBeep = true;
    if (isRegistered) {
      var logic = Get.find<IMController>();
      isAllowVibration = logic.userInfo.value.allowVibration == 1;
      isAllowBeep = logic.userInfo.value.allowBeep == 1;
    }
    // 获取系统静音、震动状态
    RingerModeStatus ringerStatus = await SoundMode.ringerModeStatus;

    if (!_audioPlayer.playerState.playing &&
        isAllowBeep &&
        (ringerStatus == RingerModeStatus.normal ||
            ringerStatus == RingerModeStatus.unknown)) {
      _audioPlayer.setAsset(_ring, package: 'openim_common');
      _audioPlayer.setLoopMode(LoopMode.off);
      _audioPlayer.setVolume(1.0);
      _audioPlayer.play();
    }

    if (isAllowVibration &&
        (ringerStatus == RingerModeStatus.normal ||
            ringerStatus == RingerModeStatus.vibrate ||
            ringerStatus == RingerModeStatus.unknown)) {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate();
      }
    }
  }

  /// 关闭提示音
  void _stopMessageSound() async {
    if (_audioPlayer.playerState.playing) {
      _audioPlayer.stop();
    }
  }

  void _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    deviceInfo = await deviceInfoPlugin.deviceInfo;
  }

  Future queryClientConfig() async {
    final map = await Apis.getClientConfig();
    clientConfigMap.assignAll(map);

    return clientConfigMap;
  }

  @override
  void onDetached() {
    // TODO: implement onDetached
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    runningBackground(true);
  }

  @override
  void onResumed() {
    runningBackground(false);
    autoCheckVersionUpgrade();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
