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

  /// ⭐ 远程线路配置（OSS）
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
    "https://doh.pub/dns-query", // 腾讯 DNSPod（域名）
    "https://dns.alidns.com/dns-query", // 阿里 DNS（域名）
    "https://1.12.12.12/dns-query", // 腾讯 IP
    "https://223.5.5.5/dns-query", // 阿里 IP
    "https://223.6.6.6/dns-query", // 阿里 IP
  ];

  /// 当前生效host
  static String _host = _defaultHost;
  static final Set<void Function(String oldHost, String newHost)>
      _hostChangedListeners = {};

  static void addHostChangedListener(
      void Function(String oldHost, String newHost) listener) {
    _hostChangedListeners.add(listener);
  }

  static void removeHostChangedListener(
      void Function(String oldHost, String newHost) listener) {
    _hostChangedListeners.remove(listener);
  }

  static void setServerHost(String host, {bool persist = true}) {
    _applyHost(host, persist: persist);
  }

  static void _applyHost(String host, {bool persist = false}) {
    final nextHost = host.trim();
    if (nextHost.isEmpty) return;
    final oldHost = _host;
    if (oldHost == nextHost) {
      Logger.print("🔁 host 无变化: $nextHost");
      // 仍然刷新一次 baseUrl，确保 HttpUtil 与当前 host 一致
      HttpUtil.refreshBaseUrl();
      return;
    }
    _host = nextHost;
    Logger.print("🔄 host 切换: $oldHost -> $_host (persist=$persist)");
    if (persist) {
      DataSp.putServerConfig({"serverIP": _host});
    }
    HttpUtil.refreshBaseUrl();

    if (_hostChangedListeners.isNotEmpty) {
      for (final listener in _hostChangedListeners.toList()) {
        try {
          listener(oldHost, _host);
        } catch (e) {
          Logger.print("host变更监听异常: $e");
        }
      }
    }
  }

  static bool get _hasScheme =>
      _host.startsWith('http://') || _host.startsWith('https://');

  static Uri? get _hostUri => _hasScheme ? Uri.tryParse(_host) : null;

  static String _joinPath(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }

  static String _toWsScheme(String scheme) {
    return scheme == 'https' ? 'wss' : 'ws';
  }

  /// ⭐ 统一的 HttpClient 工厂：忽略证书校验，避免 IP+HTTPS / 自签名导致握手失败
  static HttpClient _newClient({int timeoutSec = 5}) {
    return HttpClient()
      ..connectionTimeout = Duration(seconds: timeoutSec)
      ..badCertificateCallback = (cert, host, port) => true;
  }

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
        _applyHost(cache['serverIP']);
        Logger.print("⚡ 初始化阶段读取缓存线路: $_host");
      } else {
        Logger.print("ℹ️ 无缓存线路，当前使用默认: $_host");
      }

      await _initHost();
    } catch (e, st) {
      Logger.print("初始化异常: $e\n$st");
    }

    Logger.print("🚀 启动 App，最终 host=$_host");
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

  // ================== 线路初始化（核心调度）==================
  //
  // 优先级链：
  // 1. 缓存线路（如可用，直接使用）
  // 2. DNS TXT 解析到的所有域名 -> 测速选最快
  // 3. OSS ms.txt 拉到的所有域名 -> 测速选最快
  // 4. 默认域名 _defaultHost
  //
  // 任何一步只要测出至少一个可用域名（HTTP 200），立即应用并结束；
  // 全部失败时回退到默认域名。
  // ===========================================================
  static Future<void> _initHost() async {
    Logger.print("================ _initHost START ================");

    // -------- 第一步：缓存线路优先 --------
    final cached = DataSp.getServerConfig()?['serverIP']?.toString();
    if (cached != null && cached.isNotEmpty) {
      Logger.print("📦 发现缓存线路: $cached，开始校验...");
      final ok = await _quickCheck(cached);
      if (ok) {
        _applyHost(cached);
        Logger.print("✅ 缓存线路可用，直接使用: $_host");
        Logger.print("================ _initHost END ==================");
        return;
      } else {
        Logger.print("⚠️ 缓存线路不可用，清理缓存");
        await DataSp.putServerConfig({});
      }
    } else {
      Logger.print("ℹ️ 无缓存线路");
    }

    // -------- 第二步：DNS TXT 线路 --------
    Logger.print("---------------- 步骤2: DNS TXT ----------------");
    List<String> dnsHosts = [];
    try {
      dnsHosts = await _fetchHostsFromDNS();
    } catch (e) {
      Logger.print("❌ DNS 解析异常: $e");
    }
    Logger.print("📡 DNS 解析结果: ${dnsHosts.length} 条 -> $dnsHosts");

    if (dnsHosts.isNotEmpty) {
      final best = await _findBestHost(dnsHosts, tag: "DNS");
      if (best != null) {
        _applyHost(best, persist: true);
        Logger.print("✅ DNS 线路选中: $_host");
        try {
          IMViews.showToast("✅ 选中DNS线路");
        } catch (_) {}
        Logger.print("================ _initHost END ==================");
        return;
      } else {
        Logger.print("⚠️ DNS 解析的全部域名都不通，进入 OSS 流程");
      }
    } else {
      Logger.print("⚠️ DNS 未解析到任何域名，进入 OSS 流程");
    }

    // -------- 第三步：OSS 配置线路 --------
    Logger.print("---------------- 步骤3: OSS 配置 ----------------");
    List<String> ossHosts = [];
    try {
      ossHosts = await _fetchHostList();
    } catch (e) {
      Logger.print("❌ OSS 配置拉取异常: $e");
    }
    Logger.print("🌐 OSS 配置结果: ${ossHosts.length} 条 -> $ossHosts");

    if (ossHosts.isNotEmpty) {
      final best = await _findBestHost(ossHosts, tag: "OSS");
      if (best != null) {
        _applyHost(best, persist: true);
        Logger.print("✅ OSS 线路选中: $_host");
        try {
          IMViews.showToast("✅ 选中OSS线路");
        } catch (_) {}
        Logger.print("================ _initHost END ==================");
        return;
      } else {
        Logger.print("⚠️ OSS 解析的全部域名都不通，进入默认线路流程");
      }
    } else {
      Logger.print("⚠️ OSS 未拉取到任何域名，进入默认线路流程");
    }

    // -------- 第四步：默认兜底 --------
    Logger.print("---------------- 步骤4: 默认域名 ----------------");
    final defaultOk = await _quickCheck(_defaultHost);
    if (defaultOk) {
      _applyHost(_defaultHost);
      Logger.print("✅ 默认域名可用: $_defaultHost");
    } else {
      _applyHost(_defaultHost);
      Logger.print("❌ 默认域名也不通，但仍然应用: $_defaultHost（避免空 host）");
    }
    Logger.print("================ _initHost END ==================");
  }

  // ================== 快速健康检查 ==================
  static Future<bool> _quickCheck(String host) async {
    final stopwatch = Stopwatch()..start();
    try {
      String clean = host.trim();

      // 🔥 去协议，防止 https://https://
      clean = clean.replaceFirst(RegExp(r'^https?://'), '');

      final url = "https://$clean/admin/scripts/loading.js";

      final client = _newClient(timeoutSec: 3);
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();
      await response.drain();
      client.close(force: true);

      stopwatch.stop();

      final ok = response.statusCode == 200;
      Logger.print(
          "⚡ quickCheck $url -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms) ${ok ? "✅" : "❌"}");
      return ok;
    } catch (e) {
      stopwatch.stop();
      Logger.print(
          "⚡ quickCheck $host -> 异常 (${stopwatch.elapsedMilliseconds}ms): $e");
      return false;
    }
  }

  // ================== 国内 DNS TXT 查询 ==================
  static Future<List<String>> _fetchHostsFromDNS() async {
    final Set<String> allHosts = {};

    for (final domain in _dnsConfigDomains) {
      bool domainResolved = false;

      for (final dohUrl in _dohServers) {
        try {
          final uri = Uri.parse(dohUrl).replace(queryParameters: {
            'name': domain,
            'type': 'TXT',
            'ct': 'application/dns-json', // 阿里/腾讯 IP 端点需要明确 ct
          });

          final client = _newClient(timeoutSec: 7);
          final request = await client.getUrl(uri);
          request.headers.set('accept', 'application/dns-json');

          final response = await request.close();
          if (response.statusCode != 200) {
            Logger.print(
                "❌ DoH $dohUrl 查 $domain 失败 status=${response.statusCode}");
            client.close(force: true);
            continue;
          }

          final body = await response.transform(utf8.decoder).join();
          client.close(force: true);

          Map<String, dynamic> data;
          try {
            data = json.decode(body) as Map<String, dynamic>;
          } catch (e) {
            Logger.print("❌ DoH $dohUrl 返回非 JSON：$e, body=$body");
            continue;
          }

          final answers = data['Answer'] as List? ?? [];
          if (answers.isEmpty) {
            Logger.print("⚠️ DoH $dohUrl $domain 无 Answer");
            continue;
          }

          for (var ans in answers) {
            if (ans['type'] != 16) continue; // 16 = TXT

            String txtData = (ans['data'] as String? ?? '')
                .replaceAll('"', '')
                .replaceAll('\\', '')
                .trim();

            if (txtData.isEmpty) continue;

            List<String> hosts = [];
            try {
              final decoded = utf8.decode(base64.decode(txtData));
              hosts = decoded
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.contains('.'))
                  .toList();
              Logger.print("🔓 $domain Base64 解码成功: $hosts");
            } catch (_) {
              hosts = txtData
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e.contains('.'))
                  .toList();
              Logger.print("📝 $domain 明文解析: $hosts");
            }

            if (hosts.isNotEmpty) {
              allHosts.addAll(hosts);
              domainResolved = true;
              Logger.print(
                  "✅ DoH 成功 $domain via ${Uri.parse(dohUrl).host} -> ${hosts.length} 条");
              break;
            }
          }

          if (domainResolved) break;
        } catch (e) {
          Logger.print("❌ DoH 异常 ${Uri.parse(dohUrl).host} 查 $domain: $e");
        }
      }

      if (!domainResolved) {
        Logger.print("⚠️ DNS 所有 DoH 均无法解析 $domain");
      }
    }

    Logger.print("📡 DNS 累计解析到 ${allHosts.length} 条线路");
    return allHosts.toList();
  }

  // ================== OSS 配置拉取 ==================
  static Future<List<String>> _fetchHostList() async {
    final client = _newClient(timeoutSec: 6);
    try {
      final request = await client.getUrl(Uri.parse(_configUrl));
      final response = await request.close();
      if (response.statusCode != 200) {
        Logger.print("❌ OSS 配置 status=${response.statusCode}");
        return [];
      }

      final content = await response.transform(utf8.decoder).join();
      final hosts = content
          .split(RegExp(r'[\r\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.contains('.'))
          .toList();
      Logger.print("🌐 OSS 配置拉取成功: ${hosts.length} 条 -> $hosts");
      return hosts;
    } finally {
      client.close(force: true);
    }
  }

  // ================== 测速选最快 ==================
  static Future<String?> _findBestHost(List<String> hosts,
      {String tag = ""}) async {
    Logger.print("🏁 [$tag] 开始测速 ${hosts.length} 个候选");
    final futures = <Future<_HostResult>>[];
    for (var host in hosts) {
      for (var url in _buildUrls(host)) {
        futures.add(_testHost(url));
      }
    }
    final results = await Future.wait(futures, eagerError: false);

    // 打印全量结果
    for (final r in results) {
      Logger.print(
          "📊 [$tag] ${r.success ? "✅" : "❌"} ${r.host} (${r.duration}ms)");
    }

    final success = results.where((e) => e.success).toList();
    if (success.isEmpty) {
      Logger.print("❌ [$tag] 全部候选不可用");
      return null;
    }
    success.sort((a, b) => a.duration.compareTo(b.duration));
    Logger.print(
        "🏆 [$tag] 最优线路: ${success.first.host} (${success.first.duration}ms)");
    return success.first.host;
  }

  static List<String> _buildUrls(String host) {
    String clean = host.trim();

    // 🔥 强制去掉协议（核心）
    clean = clean.replaceFirst(RegExp(r'^https?://'), '');

    return [
      "https://$clean",
      "http://$clean",
    ];
  }

  static Future<_HostResult> _testHost(String url) async {
    final stopwatch = Stopwatch()..start();
    HttpClient? client;
    try {
      final baseUrl =
          url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final testUrl = "$baseUrl/admin/scripts/loading.js";

      client = _newClient(timeoutSec: 5);
      final request = await client.headUrl(Uri.parse(testUrl));
      final response = await request.close();
      await response.drain();
      stopwatch.stop();

      final ok = response.statusCode == 200;
      Logger.print(
          "🔍 testHost $testUrl -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)");
      return _HostResult(
        host: url,
        success: ok,
        duration: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      Logger.print(
          "🔍 testHost $url -> 异常 (${stopwatch.elapsedMilliseconds}ms): $e");
      return _HostResult(
        host: url,
        success: false,
        duration: 999999,
      );
    } finally {
      client?.close(force: true);
    }
  }

  // ================== 原有配置 ==================
  static late String cachePath;

  static const _ipRegex =
      '((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)';
  static bool get _isIP {
    final hostValue = _hostUri?.host ?? _host.split(':').first;
    return RegExp(_ipRegex).hasMatch(hostValue);
  }

  static bool get isDynamicHostReady => _host != _defaultHost;

  static String get serverIp => _host;

  static String get appAuthUrl {
    if (_hasScheme) return _joinPath(_host, '/chat');
    return _isIP ? "http://$_host:10008" : "https://$_host/chat";
  }

  static String get imApiUrl {
    if (_hasScheme) return _joinPath(_host, '/api');
    return _isIP ? 'http://$_host:10002' : "https://$_host/api";
  }

  static String get imWsUrl {
    if (_hasScheme) {
      final uri = _hostUri!;
      final wsScheme = _toWsScheme(uri.scheme);
      return _joinPath('$wsScheme://${uri.authority}', '/msg_gateway');
    }
    return _isIP ? "ws://$_host:10001" : "wss://$_host/msg_gateway";
  }

  static String get objectStorage => 'minio';

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
