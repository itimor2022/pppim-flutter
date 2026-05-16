import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'utils/data_sp.dart';

class Config {
  static const double uiW = 375;
  static const double uiH = 812;
  static const double textScaleFactor = 1.0;

  static const String friendScheme = 'openim://friend/';
  static const String groupScheme = 'openim://group/';

  static const String mapKey = '';

  static OfflinePushInfo get offlinePushInfo =>
      OfflinePushInfo(iOSPushSound: '+1', iOSBadgeCount: true);

  /// ⭐ 默认域名（兜底）
  static const String _defaultHost = "www.cliao.one";

  /// ⭐ HTTP线路（兜底）
  static const String _configUrl =
      "https://cq-1369911702.cos.ap-chongqing.myqcloud.com/im/ms.txt";

  /// ⭐ DNS TXT 域名
  static const List<String> _dnsDomains = [
    "cfg.xy447.cc",
    "cfg.xy450.cc",
    "cfg.xy441.cc",
    "cfg.xy445.cc",
    "cfg.xy440.cc",
    "cfg.xy454.cc",
    "cfg.xy453.cc",
  ];

  /// ⭐ 国内 DoH
  static const List<String> _dohServers = [
    "https://dns.alidns.com/resolve",
    "https://doh.pub/dns-query",
  ];

  static String _host = _defaultHost;

  static Future init(Function() runApp) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final path = (await getApplicationDocumentsDirectory()).path;
      cachePath = '$path/';
      await Hive.initFlutter(path);

      /// ⭐ 缓存优先
      final cache = DataSp.getServerConfig();
      if (cache != null && cache['serverIP'] != null) {
        _host = cache['serverIP'];
        print("⚡ 使用缓存线路: $_host");
      }

      /// ⭐ 后台刷新
      unawaited(_initHost());
    } catch (e) {
      print("初始化异常: $e");
    }

    runApp();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    FlutterBugly.init(androidAppId: "", iOSAppId: "");
  }

  /// ================= 核心初始化 =================

  static Future<void> _initHost() async {
    try {
      List<String> hosts = [];

      /// ⭐ 1. DNS优先
      final dnsHosts = await _fetchHostsFromDNS();

      if (dnsHosts.isNotEmpty) {
        print("✅ DNS线路: $dnsHosts");
        hosts.addAll(dnsHosts);
      }

      /// ⭐ 2. HTTP兜底
      if (hosts.isEmpty) {
        final httpHosts = await _fetchHostList();
        print("⚠️ HTTP线路: $httpHosts");
        hosts.addAll(httpHosts);
      }

      if (hosts.isEmpty) {
        throw Exception("无可用线路");
      }

      /// ⭐ 3. 测速
      final best = await _findBestHost(hosts);

      if (best != null) {
        _host = best;
        DataSp.putServerConfig({"serverIP": _host});
        print("🚀 最优线路: $_host");
      }
    } catch (e) {
      print("❌ 初始化失败: $e");
    }
  }

  /// ================= DNS TXT =================

  static Future<List<String>> _fetchHostsFromDNS() async {
    final List<String> result = [];

    /// 并发所有域名
    final futures = _dnsDomains.map((d) => _queryTxt(d));

    final all = await Future.wait(futures);

    for (var list in all) {
      result.addAll(list);
    }

    return result.toSet().toList();
  }

  static Future<List<String>> _queryTxt(String domain) async {
    final List<String> result = [];

    /// ⭐ 多DNS并发
    final futures = _dohServers.map((server) async {
      try {
        final url = "$server?name=$domain&type=TXT";

        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 4);

        final request = await client.getUrl(Uri.parse(url));
        request.headers.set("accept", "application/dns-json");

        final response = await request.close();

        if (response.statusCode != 200) return;

        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);

        if (json['Answer'] == null) return;

        /// ⭐ TXT可能分片，需要拼接
        String combined = "";

        for (var item in json['Answer']) {
          String data = item['data'];
          data = data.replaceAll('"', '');
          combined += data;
        }

        if (combined.isEmpty) return;

        try {
          final decoded = utf8.decode(base64Decode(combined));

          print("🌐 [$server][$domain] => $decoded");

          result.addAll(decoded
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty));
        } catch (_) {}
      } catch (_) {}
    });

    await Future.wait(futures);

    return result;
  }

  /// ================= HTTP兜底 =================

  static Future<List<String>> _fetchHostList() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    final request = await client.getUrl(Uri.parse(_configUrl));
    final response = await request.close();

    if (response.statusCode != 200) return [];

    final content = await response.transform(utf8.decoder).join();

    return content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// ================= 测速 =================

  static Future<String?> _findBestHost(List<String> hosts) async {
    final futures = <Future<_HostResult>>[];

    for (var host in hosts) {
      for (var url in _buildUrls(host)) {
        futures.add(_testHost(url));
      }
    }

    final results = await Future.wait(futures);

    final success = results.where((e) => e.success).toList();

    if (success.isEmpty) return null;

    success.sort((a, b) => a.duration.compareTo(b.duration));

    return success.first.host;
  }

  static List<String> _buildUrls(String host) {
    if (host.startsWith("http")) return [host];

    return [
      "https://$host",
      "http://$host",
    ];
  }

  static Future<_HostResult> _testHost(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      stopwatch.stop();

      return _HostResult(
        host: Uri.parse(url).host,
        success: response.statusCode == 200,
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

  /// ================= 原配置 =================

  static late String cachePath;

  static String get serverIp => _host;

  static String get appAuthUrl => "https://$_host/chat";
  static String get imApiUrl => "https://$_host/api";
  static String get imWsUrl => "wss://$_host/msg_gateway";
}

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
