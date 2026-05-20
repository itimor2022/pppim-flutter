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
  /// ⭐ 默认兜底域名
  static const String _defaultHost = "https://46.149.198.106:5427";

  /// ⭐ 远程线路配置
  static const String _configUrl =
      "https://cq-1369911702.cos.ap-chongqing.myqcloud.com/im/ms.txt";

  /// ⭐ 国内 DNS TXT 配置域名列表
  static const List<String> _dnsConfigDomains = [
    "cfg.xy447.cc",
    "cfg.xy450.cc",
    "cfg.xy441.cc",
    "cfg.xy445.cc",
    "cfg.xy440.cc",
    "cfg.xy454.cc",
    "cfg.xy453.cc",
  ];

  /// 国内 DoH 服务（优先级从高到低）
  static const List<String> _dohServers = [
    "https://doh.pub/dns-query", // 腾讯 DNSPod
    "https://1.12.12.12/dns-query",
    "https://dns.alidns.com/dns-query", // 阿里 DNS
    "https://223.5.5.5/dns-query",
    "https://223.6.6.6/dns-query",
  ];

  /// 当前生效host
  static String _host = _defaultHost;

  // ================== 初始化 ==================
  static Future init(Function() runApp) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final path = (await getApplicationDocumentsDirectory()).path;
      cachePath = '$path/';

      await DataSp.init();
      await Hive.initFlutter(path);
      HttpUtil.init();

      final cache = DataSp.getServerConfig();
      if (cache != null && cache['serverIP'] != null) {
        _host = cache['serverIP'];
        Logger.print("⚡ 使用缓存线路: $_host");
      }

      unawaited(_initHost());
    } catch (e) {
      Logger.print("初始化异常: $e");
    }

    runApp();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    var brightness = Platform.isAndroid ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness,
    ));

    FlutterBugly.init(androidAppId: "", iOSAppId: "");
  }

  // ================== 线路初始化 ==================
  static Future<void> _initHost() async {
    try {
      // ================== ① 本地缓存 ==================
      final cached = DataSp.getServerConfig()?['serverIP'];

      if (cached != null && cached.toString().isNotEmpty) {
        final ok = await _quickCheck(cached);
        if (ok) {
          _host = cached;
          Logger.print("⚡ 使用缓存线路: $_host");
          return;
        }
        Logger.print("⚠️ 缓存失效");
      }

      // ================== ② DNS ==================
      List<String> hosts = await _fetchHostsFromDNS();
      if (hosts.isNotEmpty) {
        Logger.print("📡 DNS线路: ${hosts.length}");
      } else {
        // ================== ③ COS ==================
        hosts = await _fetchHostList();
        Logger.print("🌐 COS线路: ${hosts.length}");
      }

      if (hosts.isEmpty) throw Exception("无线路");

      // ================== ④ 选最快 ==================
      final best = await _findBestHost(hosts);

      if (best != null) {
        _host = best;
        DataSp.putServerConfig({"serverIP": _host});
        Logger.print("✅ 最优线路: $_host");
      } else {
        throw Exception("测速失败");
      }
    } catch (e) {
      Logger.print("❌ 初始化失败: $e");
      _host = _defaultHost;
    }
  }

  static Future<bool> _quickCheck(String host) async {
    try {
      final url = host.endsWith('/')
          ? "${host}admin/scripts/loading.js"
          : "$host/admin/scripts/loading.js";

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 2);

      final request = await client.openUrl('HEAD', Uri.parse(url));
      final response = await request.close();
      await response.drain();

      Logger.print("⚡ HEAD检测: $host -> ${response.statusCode}");

      final code = response.statusCode;

      return code == 200 || code == 204 || code == 301 || code == 302;
    } catch (_) {
      return false;
    }
  }

  // ================== 国内 DNS TXT 查询（核心修改）==================
  static Future<List<String>> _fetchHostsFromDNS() async {
    final Set<String> allHosts = {};

    for (final domain in _dnsConfigDomains) {
      for (final dohUrl in _dohServers) {
        try {
          final uri = Uri.parse(dohUrl).replace(
            queryParameters: {
              'name': domain,
              'type': 'TXT',
            },
          );

          final client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 7);
          final request = await client.getUrl(uri);
          request.headers.set('accept', 'application/dns-json');

          final response = await request.close();
          if (response.statusCode != 200) continue;

          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body);

          final answers = data['Answer'] as List? ?? [];
          for (var ans in answers) {
            if (ans['type'] != 16) continue; // 16 = TXT

            String txtData = (ans['data'] as String? ?? '')
                .replaceAll('"', '')
                .replaceAll('\\', '')
                .trim();

            if (txtData.isEmpty) continue;

            List<String> hosts = [];
            try {
              // Base64 解码
              final decoded = utf8.decode(base64.decode(txtData));
              hosts = decoded
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.contains('.'))
                  .toList();
            } catch (_) {
              // 明文
              hosts = txtData
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.contains('.'))
                  .toList();
            }

            if (hosts.isNotEmpty) {
              allHosts.addAll(hosts);
              Logger.print("✅ 国内DNS成功: $domain (${Uri.parse(dohUrl).host})");
              break; // 成功一个就跳出当前域名
            }
          }
          if (allHosts.isNotEmpty) break; // 已获取到线路，跳出
        } catch (e) {
          // Logger.print("❌ $dohUrl 查询失败: $e"); // 可注释掉减少日志
        }
      }
    }
    return allHosts.toList();
  }

  // ================== 其他原有方法保持不变 ==================
  static Future<List<String>> _fetchHostList() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    final request = await client.getUrl(Uri.parse(_configUrl));
    final response = await request.close();
    if (response.statusCode != 200) throw Exception("配置文件获取失败");

    final content = await response.transform(utf8.decoder).join();
    return content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('.'))
        .toList();
  }

  static Future<String?> _findBestHost(List<String> hosts) async {
    final futures = <Future<_HostResult>>[];
    for (var host in hosts) {
      for (var url in _buildUrls(host)) {
        futures.add(_testHost(url));
      }
    }
    final results = await Future.wait(futures, eagerError: false);
    final success = results.where((e) => e.success).toList();
    if (success.isEmpty) return null;
    success.sort((a, b) => a.duration.compareTo(b.duration));
    return success.first.host;
  }

  static List<String> _buildUrls(String host) {
    // ⭐ 已经是完整URL，直接返回
    return [host];
  }

  static Future<_HostResult> _testHost(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      final testUrl = url.endsWith('/')
          ? "${url}admin/scripts/loading.js"
          : "$url/admin/scripts/loading.js";

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);

      final request = await client.openUrl('HEAD', Uri.parse(testUrl));
      final response = await request.close();
      await response.drain();

      stopwatch.stop();

      final code = response.statusCode;
      final ok = code == 200 || code == 204 || code == 301 || code == 302;

      Logger.print(
          "HEAD测速: $testUrl -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)");

      return _HostResult(
        host: url, // ⭐ 这里直接保存完整URL（重要）
        success: ok,
        duration: stopwatch.elapsedMilliseconds,
      );
    } catch (_) {
      stopwatch.stop();
      return _HostResult(
        host: url,
        success: false,
        duration: 999999,
      );
    }
  }

  // ================== 原有配置 ==================
  static late String cachePath;

  static const _ipRegex =
      '((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)';
  static bool get _isIP {
    try {
      final uri = Uri.parse(_host);
      return RegExp(_ipRegex).hasMatch(uri.host);
    } catch (_) {
      return false;
    }
  }

  static bool get isDynamicHostReady => _host != _defaultHost;

  static String get serverIp => _host;
  static String get imApiUrl => "$_host/api";
  static String get appAuthUrl => "$_host/chat";
  static String get imWsUrl {
    final uri = Uri.parse(_host);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return "$scheme://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}/msg_gateway";
  }

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

class _HostResult {
  final String host;
  final bool success;
  final int duration;
  _HostResult(
      {required this.host, required this.success, required this.duration});
}
