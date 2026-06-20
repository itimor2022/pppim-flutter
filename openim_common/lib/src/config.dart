import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openim_common/openim_common.dart';
import 'package:path_provider/path_provider.dart';

class Config {
  /// ⭐ 默认兜底域名
  static const String _defaultHost = "https://www.sbtn1.shop";

  /// ⭐ 远程线路配置（OSS）
  static const String _configUrl =
      "https://d2pvzx7xdvbqsq.cloudfront.net/im/aoa.txt";

  /// ⭐ 国内 DNS TXT 配置域名列表
  static const List<String> _dnsConfigDomains = [
    "cfg.nhs1.top",
    "cfg.tya2.cyou",
    "cfg.nms1.icu",
    "cfg.xhk1.shop",
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

    // -------- 手动模式：不在启动阶段自动切线 --------
    Logger.print("---------------- 手动模式：跳过DNS/OSS自动切线 ----------------");
    Logger.print("ℹ️ 可在登录页点击“切换线路”手动选择线路");

    // -------- 默认兜底 --------
    Logger.print("---------------- 步骤2: 默认域名 ----------------");
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

  static Future<List<_HostResult>> _runLimited(
    List<String> items,
    int concurrency,
    Future<_HostResult> Function(String url) fn,
  ) async {
    final queue = Queue<String>()..addAll(items);
    final results = <_HostResult>[];

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final item = queue.removeFirst();
        results.add(await fn(item));
      }
    }

    final workers = List.generate(
      concurrency,
      (_) => worker(),
    );

    await Future.wait(workers);
    return results;
  }

  // ================== 快速健康检查 ==================
  static Future<bool> _quickCheck(String host) async {
    final stopwatch = Stopwatch()..start();
    try {
      final baseUrl = host.startsWith("http") ? host : "https://$host";
      final url = baseUrl.endsWith('/')
          ? "${baseUrl}admin/scripts/loading.js"
          : "$baseUrl/admin/scripts/loading.js";

      final client = _newClient(timeoutSec: 3);
      final request = await client.getUrl(Uri.parse(url));
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

  static String _normalizeHttpsHost(String host) {
    var value = host.trim();
    if (value.isEmpty) return '';
    if (!value.startsWith('https://')) return '';
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return '';
    }
    return uri.replace(host: uri.host.toLowerCase()).toString();
  }

  static List<String> _dedupeHosts(Iterable<String> hosts) {
    final normalizedSet = <String>{};
    final result = <String>[];
    for (final host in hosts) {
      final normalized = _normalizeHttpsHost(host);
      if (normalized.isEmpty) continue;
      if (normalizedSet.add(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  // ================== 国内 DNS TXT 查询 ==================
  static Future<List<String>> _fetchHostsFromDNS() async {
    final Set<String> allHosts = {};
    bool globalResolved = false;

    for (final domain in _dnsConfigDomains) {
      if (globalResolved) break;

      bool domainResolved = false;

      for (final dohUrl in _dohServers) {
        try {
          final uri = Uri.parse(dohUrl).replace(queryParameters: {
            'name': domain,
            'type': 'TXT',
            'ct': 'application/dns-json',
          });

          final client = _newClient(timeoutSec: 7);
          final request = await client.getUrl(uri);
          request.headers.set('accept', 'application/dns-json');

          final response = await request.close();
          if (response.statusCode != 200) continue;

          final body = await response.transform(utf8.decoder).join();
          client.close(force: true);

          final data = json.decode(body) as Map<String, dynamic>;
          final answers = data['Answer'] as List? ?? [];

          for (final ans in answers) {
            if (ans['type'] != 16) continue;

            String txt = (ans['data'] ?? '')
                .toString()
                .replaceAll('"', '')
                .replaceAll('\\', '')
                .trim();

            if (txt.isEmpty) continue;

            List<String> hosts;

            try {
              final decoded = utf8.decode(base64.decode(txt));
              hosts = decoded.split(',');
            } catch (_) {
              hosts = txt.split(',');
            }

            hosts = hosts
                .map((e) => e.trim())
                .where((e) => e.startsWith('https://'))
                .toList();

            hosts = _dedupeHosts(hosts);

            if (hosts.isNotEmpty) {
              allHosts.addAll(hosts);
              domainResolved = true;
              globalResolved = true; // ⭐ 核心：全局跳出

              Logger.print("✅ DNS成功: $domain -> $hosts");
              break;
            }
          }

          if (domainResolved) break;
        } catch (_) {}
      }
    }

    final deduped = _dedupeHosts(allHosts);
    Logger.print("📡 DNS最终线路: ${deduped.length}");
    return deduped;
  }

  /// 手动切换线路时使用：优先 DNS，DNS 无结果时才回退 OSS。
  static Future<List<ConfigLineOption>> fetchManualLineOptions() async {
    List<String> candidates = [];

    try {
      candidates = await _fetchHostsFromDNS();
      if (candidates.isNotEmpty) {
        Logger.print('手动线路来源: DNS (${candidates.length})');
      }
    } catch (e) {
      Logger.print("手动线路 DNS 拉取异常: $e");
    }

    if (candidates.isEmpty) {
      try {
        candidates = await _fetchHostList();
        if (candidates.isNotEmpty) {
          Logger.print('手动线路来源: OSS (${candidates.length})');
        }
      } catch (e) {
        Logger.print("手动线路 OSS 拉取异常: $e");
      }
    }

    candidates = _dedupeHosts(candidates);

    if (candidates.isEmpty) {
      return [];
    }

    return candidates
        .map(
          (host) => ConfigLineOption(
            host: host,
            success: true,
            duration: -1,
          ),
        )
        .toList();
  }

  /// 后台测速：仅用于弹窗内更新延迟展示，不阻塞弹窗打开。
  static Future<List<ConfigLineOption>> fetchManualLineLatencies(
    List<String> hosts,
  ) async {
    final candidates = _dedupeHosts(hosts);

    final results = await _runLimited(candidates, 8, _testHost);
    results.sort((a, b) {
      if (a.success != b.success) {
        return a.success ? -1 : 1;
      }
      return a.duration.compareTo(b.duration);
    });

    return results
        .map(
          (e) => ConfigLineOption(
            host: e.host,
            success: e.success,
            duration: e.success ? e.duration : -1,
          ),
        )
        .toList();
  }

  // ================== OSS 配置拉取 ==================
  static Future<List<String>> _fetchHostList() async {
    final client = _newClient(timeoutSec: 6);

    try {
      final request = await client.getUrl(Uri.parse(_configUrl));
      final response = await request.close();

      if (response.statusCode != 200) return [];

      final content = await response.transform(utf8.decoder).join();

      final hosts = content
          .split(RegExp(r'[\r\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.startsWith("https://")) // ⭐ 强制 https
          .toList();

      final deduped = _dedupeHosts(hosts);
      Logger.print("🌐 OSS线路: ${deduped.length}");
      return deduped;
    } finally {
      client.close(force: true);
    }
  }

  // ================== 测速选最快 ==================
  static Future<String?> _findBestHost(List<String> hosts,
      {String tag = ""}) async {
    final expanded = <String>[];

    for (final h in hosts) {
      expanded.add(h); // ⭐ 已经是 https:// 不再拼接
    }

    Logger.print("🏁 [$tag] 候选: ${expanded.length}");

    final results = await _runLimited(
      expanded,
      8, // ⭐ 并发限制核心（建议 5~8）
      _testHost,
    );

    final success = results.where((e) => e.success).toList();

    if (success.isEmpty) {
      Logger.print("❌ [$tag] 无可用线路");
      return null;
    }

    success.sort((a, b) => a.duration.compareTo(b.duration));

    Logger.print("🏆 [$tag] 最优: ${success.first.host}");
    return success.first.host;
  }

  static List<String> _buildUrls(String host) {
    if (host.startsWith("http")) return [host];
    return ["https://$host", "http://$host"];
  }

  static Future<_HostResult> _testHost(String url) async {
    final stopwatch = Stopwatch()..start();
    HttpClient? client;

    try {
      final testUrl = url.endsWith('/')
          ? "${url}admin/scripts/loading.js"
          : "$url/admin/scripts/loading.js";

      client = _newClient(timeoutSec: 5);

      // ================= HEAD =================
      var request = await client.openUrl('HEAD', Uri.parse(testUrl));
      var response = await request.close();

      // ================= fallback GET =================
      if (response.statusCode >= 400) {
        final getReq = await client.getUrl(Uri.parse(testUrl));
        response = await getReq.close();
      }

      await response.drain();
      stopwatch.stop();

      final code = response.statusCode;
      final ok = code == 200 || code == 204 || code == 301 || code == 302;

      return _HostResult(
        host: url,
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

  static String get imApiUrl => "$_host/api";
  static String get appAuthUrl => "$_host/chat";
  static String get imWsUrl {
    final uri = Uri.parse(_host);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';

    return "$scheme://${uri.host}$port/msg_gateway";
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

class ConfigLineOption {
  final String host;
  final bool success;
  final int duration;

  const ConfigLineOption({
    required this.host,
    required this.success,
    required this.duration,
  });
}
