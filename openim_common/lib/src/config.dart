import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openim_common/openim_common.dart';
import 'package:path_provider/path_provider.dart';

class Config {
  /// ⭐ 默认兜底域名（非常重要）
  static const String _defaultHost = "www.cliao.one";

  /// ⭐ 远程线路配置
  static const String _configUrl =
      "https://cq-1369911702.cos.ap-chongqing.myqcloud.com/im/ms.txt";

  /// ⭐ 当前生效host
  static String _host = _defaultHost;

  /// 初始化
  static Future init(Function() runApp) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final path = (await getApplicationDocumentsDirectory()).path;
      cachePath = '$path/';
      await DataSp.init();
      await Hive.initFlutter(path);
      HttpUtil.init();

      /// ⭐ 优先使用缓存
      final cache = DataSp.getServerConfig();
      if (cache != null && cache['serverIP'] != null) {
        _host = cache['serverIP'];
        Logger.print("⚡ 使用缓存线路: $_host");
      }

      /// ⭐ 后台刷新线路（不阻塞启动）
      unawaited(_initHost());
    } catch (e) {
      Logger.print("初始化异常: $e");
    }

    runApp();

    /// 屏幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    /// 状态栏
    var brightness = Platform.isAndroid ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness,
    ));

    FlutterBugly.init(androidAppId: "", iOSAppId: "");
  }

  /// ⭐ 核心：初始化线路
  static Future<void> _initHost() async {
    try {
      final hosts = await _fetchHostList();

      if (hosts.isEmpty) {
        throw Exception("线路列表为空");
      }

      final best = await _findBestHost(hosts);

      if (best != null) {
        _host = best;

        /// 缓存
        DataSp.putServerConfig({"serverIP": _host});

        Logger.print("✅ 选中最佳线路: $_host");
      } else {
        throw Exception("无可用线路");
      }
    } catch (e) {
      Logger.print("❌ 线路初始化失败: $e");
    }
  }

  /// 获取线路列表
  static Future<List<String>> _fetchHostList() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    final request = await client.getUrl(Uri.parse(_configUrl));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception("配置文件获取失败");
    }

    final content = await response.transform(utf8.decoder).join();

    return content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// ⭐ 并发测速（核心优化）
  static Future<String?> _findBestHost(List<String> hosts) async {
    final futures = <Future<_HostResult>>[];

    for (var host in hosts) {
      for (var url in _buildUrls(host)) {
        futures.add(_testHost(url));
      }
    }

    final results = await Future.wait(futures);

    /// 过滤成功
    final success = results.where((e) => e.success).toList();

    if (success.isEmpty) return null;

    /// 按耗时排序（越快越好）
    success.sort((a, b) => a.duration.compareTo(b.duration));

    return success.first.host;
  }

  /// 构建URL
  static List<String> _buildUrls(String host) {
    if (host.startsWith("http")) return [host];

    return [
      "https://$host",
      "http://$host",
    ];
  }

  /// 测速
  static Future<_HostResult> _testHost(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;

      final response = await request.close();

      stopwatch.stop();

      final ok = response.statusCode == 200;

      Logger.print(
          "检测: $url -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)");

      return _HostResult(
        host: Uri.parse(url).host,
        success: ok,
        duration: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      stopwatch.stop();
      return _HostResult(
        host: Uri.parse(url).host,
        success: false,
        duration: 999999,
      );
    }
  }

  /// ================== 原有配置 ==================

  static late String cachePath;

  static const _ipRegex =
      '((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)';

  static bool get _isIP => RegExp(_ipRegex).hasMatch(_host);

  static String get serverIp => _host;

  static String get appAuthUrl =>
      _isIP ? "http://$_host:10008" : "https://$_host/chat";

  static String get imApiUrl =>
      _isIP ? 'http://$_host:10002' : "https://$_host/api";

  static String get imWsUrl =>
      _isIP ? "ws://$_host:10001" : "wss://$_host/msg_gateway";

  static String get objectStorage => 'minio';

  /// 其他保持不变
  static const uiW = 375.0;
  static const uiH = 812.0;
  static const deptName = "OpenIM";
  static const deptID = '0';
  static const double textScaleFactor = 1.0;
  static const secret = 'tuoyun';
  static const mapKey = 'IBFBZ-BLAKC-USA2Y-AVP4F-IZVNV-2JFFI';

  static OfflinePushInfo offlinePushInfo = OfflinePushInfo(
    title: StrRes.offlineMessage,
    desc: "",
    iOSBadgeCount: true,
    iOSPushSound: '+1',
  );

  static const friendScheme = "io.openim.app/addFriend/";
  static const groupScheme = "io.openim.app/joinGroup/";
}

/// 测速结果
class _HostResult {
  final String host;
  final bool success;
  final int duration;

  _HostResult({
    required this.host,
    required this.success,
    required this.duration,
  });
}
