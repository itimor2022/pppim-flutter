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

// ================== 异步锁实现（移到顶层） ==================
class _AsyncLock {
  Completer<void>? _completer;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    // 等待之前的操作完成
    while (_completer != null && !_completer!.isCompleted) {
      await _completer!.future;
    }

    _completer = Completer<void>();
    try {
      return await action();
    } finally {
      _completer?.complete();
      _completer = null;
    }
  }
}

class Config {
  /// ⭐ 默认兜底域名
  static const String _defaultHost = "https://172.252.172.80:443";

  /// ⭐ 远程线路配置（OSS）
  static const String _configUrl =
      "https://d2pvzx7xdvbqsq.cloudfront.net/im/qaq.txt";

  /// ⭐ 国内 DNS TXT 配置域名列表
  static const List<String> _dnsConfigDomains = [
    "cfg.aopwx.top",
    "cfg.168773a.cfd",
  ];

  /// 国内 DoH 服务（优先级从高到低）
  static const List<String> _dohServers = [
    "https://doh.pub/dns-query", // 腾讯 DNSPod（域名）
    "https://dns.alidns.com/dns-query", // 阿里 DNS（域名）
    "https://1.12.12.12/dns-query", // 腾讯 IP
    "https://223.5.5.5/dns-query", // 阿里 IP
    "https://223.6.6.6/dns-query", // 阿里 IP
  ];

  /// 并发控制配置
  static const int _maxConcurrentRequests = 5; // 最大并发请求数
  static const int _batchSize = 5; // 分批测速大小
  static const int _defaultTimeoutSec = 8; // 默认超时时间
  static const int _quickCheckTimeoutSec = 3; // 快速检测超时

  /// 当前生效host
  static String _host = _defaultHost;
  static final Set<void Function(String oldHost, String newHost)>
      _hostChangedListeners = {};

  // ================== 锁机制 ==================
  static final _hostLock = _AsyncLock();
  static final _initLock = _AsyncLock();

  static void addHostChangedListener(
      void Function(String oldHost, String newHost) listener) {
    _hostChangedListeners.add(listener);
  }

  static void removeHostChangedListener(
      void Function(String oldHost, String newHost) listener) {
    _hostChangedListeners.remove(listener);
  }

  /// ⭐ 修复：公开的线路切换方法
  static Future<void> setServerHost(String host, {bool persist = true}) async {
    // 使用锁防止并发切换
    await _hostLock.synchronized(() async {
      if (host.trim().isEmpty) return;

      // 确保是 https 协议
      var newHost = host.trim();
      if (!newHost.startsWith('http://') && !newHost.startsWith('https://')) {
        newHost = 'https://$newHost';
      }

      // 移除末尾斜杠
      if (newHost.endsWith('/')) {
        newHost = newHost.substring(0, newHost.length - 1);
      }

      // ⭐ 先校验新线路是否可用
      final ok = await _quickCheck(newHost);
      if (!ok) {
        Logger.print("❌ 新线路不可用: $newHost");
        throw Exception('线路不可用，请检查网络后重试');
      }

      // ⭐ 执行切换
      _applyHost(newHost, persist: persist);

      Logger.print("✅ 线路切换成功: $_host");
    });
  }

  static void _applyHost(String host, {bool persist = false}) {
    final nextHost = host.trim();
    if (nextHost.isEmpty) return;

    // 确保协议
    var finalHost = nextHost;
    if (!finalHost.startsWith('http://') && !finalHost.startsWith('https://')) {
      finalHost = 'https://$finalHost';
    }
    if (finalHost.endsWith('/')) {
      finalHost = finalHost.substring(0, finalHost.length - 1);
    }

    final oldHost = _host;
    if (oldHost == finalHost) {
      Logger.print("🔁 host 无变化: $finalHost");
      HttpUtil.refreshBaseUrl();
      return;
    }

    _host = finalHost;
    Logger.print("🔄 host 切换: $oldHost -> $_host (persist=$persist)");

    if (persist) {
      try {
        DataSp.putServerConfig({"serverIP": _host});
        Logger.print("💾 已持久化线路: $_host");
      } catch (e) {
        Logger.print("⚠️ 持久化失败: $e");
      }
    }

    HttpUtil.refreshBaseUrl();

    if (_hostChangedListeners.isNotEmpty) {
      final listeners = _hostChangedListeners.toList();
      for (final listener in listeners) {
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
  static HttpClient _newClient({int timeoutSec = _defaultTimeoutSec}) {
    return HttpClient()
      ..connectionTimeout = Duration(seconds: timeoutSec)
      ..badCertificateCallback = (cert, host, port) => true;
  }

  // ================== 初始化 ==================
  // 使用别名隐藏 Flutter 的 runApp，避免与回调参数名冲突
  // ignore: non_constant_identifier_names
  static Future<void> init(Function() onLaunch) async {
    WidgetsFlutterBinding.ensureInitialized();

    // ⭐ 使用 runZonedGuarded 捕获所有未处理异常
    await runZonedGuarded(() async {
      try {
        final path = (await getApplicationDocumentsDirectory()).path;
        cachePath = '$path/';

        await DataSp.init();
        await Hive.initFlutter(path);
        HttpUtil.init();

        // ⭐ 初始化线路（带超时保护）
        await _initHostWithTimeout();
      } catch (e, st) {
        Logger.print("初始化异常: $e\n$st");
        // ⭐ 降级：使用默认域名
        _applyHost(_defaultHost);
      }

      Logger.print("🚀 启动 App，最终 host=$_host");

      // ⭐ 确保 UI 启动
      try {
        onLaunch();
      } catch (e) {
        Logger.print("❌ runApp 异常: $e");
        // 如果 onLaunch 失败，使用 WidgetsApp 兜底
        runApp(_buildFallbackApp());
      }

      // 系统UI配置
      _setupSystemUI();

      // Bugly 初始化（不阻塞）
      try {
        FlutterBugly.init(androidAppId: "", iOSAppId: "");
      } catch (e) {
        Logger.print("Bugly 初始化失败: $e");
      }
    }, (error, stack) {
      Logger.print("❌ 未捕获异常: $error\n$stack");
      // ⭐ 兜底：确保应用不会完全崩溃
      try {
        runApp(_buildFallbackApp());
      } catch (_) {}
    });
  }

  /// 带超时保护的初始化
  static Future<void> _initHostWithTimeout() async {
    try {
      await _initLock.synchronized(() async {
        // 超时保护
        await Future.any([
          _initHost(),
          Future.delayed(Duration(seconds: 15), () {
            throw TimeoutException('线路初始化超时');
          }),
        ]);
      });
    } on TimeoutException catch (e) {
      Logger.print("⚠️ 线路初始化超时: $e");
      // 超时后使用缓存或默认
      final cached = DataSp.getServerConfig()?['serverIP']?.toString();
      if (cached != null && cached.isNotEmpty) {
        _applyHost(cached);
      } else {
        _applyHost(_defaultHost);
      }
    } catch (e) {
      Logger.print("❌ 线路初始化失败: $e");
      _applyHost(_defaultHost);
    }
  }

  static Widget _buildFallbackApp() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('应用启动中...'),
            ],
          ),
        ),
      ),
    );
  }

  static void _setupSystemUI() {
    try {
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
    } catch (e) {
      Logger.print("系统UI配置失败: $e");
    }
  }

  // ================== 线路初始化（核心调度）==================
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
        try {
          await DataSp.putServerConfig({});
        } catch (_) {}
      }
    } else {
      Logger.print("ℹ️ 无缓存线路");
    }

    // -------- 第二步：DNS 查询（优先）--------
    Logger.print("---------------- 步骤1: DNS 查询 ----------------");
    try {
      final dnsHosts = await _fetchHostsFromDNS();
      if (dnsHosts.isNotEmpty) {
        Logger.print("✅ DNS 查询成功，获取到 ${dnsHosts.length} 条线路");
        final bestHost = await _findBestHost(dnsHosts, tag: "DNS");
        if (bestHost != null) {
          _applyHost(bestHost);
          Logger.print("✅ DNS 最优线路: $bestHost");
          Logger.print("================ _initHost END ==================");
          return;
        }
        Logger.print("⚠️ DNS 返回的线路均不可用");
      } else {
        Logger.print("❌ DNS 查询无结果");
      }
    } catch (e) {
      Logger.print("❌ DNS 查询异常: $e");
    }

    // -------- 第三步：OSS TXT 文件（备用）--------
    Logger.print("---------------- 步骤2: OSS TXT 文件 ----------------");
    try {
      final ossHosts = await _fetchHostList();
      if (ossHosts.isNotEmpty) {
        Logger.print("✅ OSS 获取成功，获取到 ${ossHosts.length} 条线路");
        final bestHost = await _findBestHost(ossHosts, tag: "OSS");
        if (bestHost != null) {
          _applyHost(bestHost);
          Logger.print("✅ OSS 最优线路: $bestHost");
          Logger.print("================ _initHost END ==================");
          return;
        }
        Logger.print("⚠️ OSS 返回的线路均不可用");
      } else {
        Logger.print("❌ OSS 获取无结果");
      }
    } catch (e) {
      Logger.print("❌ OSS 获取异常: $e");
    }

    // -------- 第四步：默认兜底 --------
    Logger.print("---------------- 步骤3: 默认兜底 ----------------");
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

  // ================== 健康检查（带重试） ==================
  static Future<bool> _quickCheck(String host, {int retries = 1}) async {
    int attempt = 0;
    while (attempt <= retries) {
      final stopwatch = Stopwatch()..start();
      HttpClient? client;
      try {
        var baseUrl = host;
        if (!baseUrl.startsWith("http")) {
          baseUrl = "https://$baseUrl";
        }
        if (baseUrl.endsWith('/')) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        }

        final url = "$baseUrl/admin/scripts/loading.js";

        client = _newClient(timeoutSec: _quickCheckTimeoutSec);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        await response.drain();
        stopwatch.stop();

        final ok = response.statusCode == 200;
        if (ok) {
          Logger.print(
              "⚡ quickCheck $url -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms) ✅");
          return true;
        }
        Logger.print(
            "⚡ quickCheck $url -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms) ❌");
      } catch (e) {
        stopwatch.stop();
        Logger.print(
            "⚡ quickCheck $host -> 异常 (${stopwatch.elapsedMilliseconds}ms): $e");
        attempt++;
        if (attempt > retries) break;
        // 短暂延迟后重试
        await Future.delayed(Duration(milliseconds: 200 * attempt));
        continue;
      } finally {
        client?.close(force: true);
      }
      attempt++;
    }
    return false;
  }

  static String _normalizeHttpsHost(String host) {
    try {
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
    } catch (_) {
      return '';
    }
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

  // ================== 国内 DNS TXT 查询（优化） ==================
  static Future<List<String>> _fetchHostsFromDNS() async {
    // 遍历所有 DNS 配置域名
    for (final domain in _dnsConfigDomains) {
      Logger.print("📡 尝试 DNS 查询: $domain");

      // ⭐ 并行查询所有 DoH 服务器
      final futures = _dohServers.map((dohUrl) async {
        try {
          return await _queryDoH(domain, dohUrl);
        } catch (e) {
          Logger.print("⚠️ DoH 查询失败: $dohUrl, error: $e");
          return <String>[];
        }
      }).toList();

      final results = await Future.wait(futures);

      // 取第一个非空结果
      for (final hosts in results) {
        if (hosts.isNotEmpty) {
          Logger.print("✅ DNS 查询成功: $domain -> ${hosts.length} 条线路");
          return hosts;
        }
      }
    }

    Logger.print("❌ 所有 DNS 查询均失败");
    return [];
  }

  static Future<List<String>> _queryDoH(String domain, String dohUrl) async {
    HttpClient? client;
    try {
      final uri = Uri.parse(dohUrl).replace(queryParameters: {
        'name': domain,
        'type': 'TXT',
        'ct': 'application/dns-json',
      });

      client = _newClient(timeoutSec: 7);
      final request = await client.getUrl(uri);
      request.headers.set('accept', 'application/dns-json');

      final response = await request.close();
      if (response.statusCode != 200) {
        return [];
      }

      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body) as Map<String, dynamic>;
      final answers = data['Answer'] as List? ?? [];

      final allHosts = <String>[];
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

        allHosts.addAll(hosts);
      }

      return _dedupeHosts(allHosts);
    } finally {
      client?.close(force: true);
    }
  }

  /// 手动切换线路时使用：优先 DNS，DNS 无结果时才回退 OSS。
  static Future<List<ConfigLineOption>> fetchManualLineOptions() async {
    List<String> candidates = [];

    // -------- 第一步：DNS 查询（优先）--------
    try {
      candidates = await _fetchHostsFromDNS();
      if (candidates.isNotEmpty) {
        Logger.print('✅ 手动线路来源: DNS (${candidates.length})');
        candidates = _dedupeHosts(candidates);
        if (candidates.isNotEmpty) {
          // ⭐ 快速检测所有线路
          return await _quickCheckHosts(candidates);
        }
      } else {
        Logger.print('❌ 手动线路 DNS 无结果');
      }
    } catch (e) {
      Logger.print("❌ 手动线路 DNS 拉取异常: $e");
    }

    // -------- 第二步：OSS TXT 文件（备用）--------
    try {
      candidates = await _fetchHostList();
      if (candidates.isNotEmpty) {
        Logger.print('✅ 手动线路来源: OSS (${candidates.length})');
        candidates = _dedupeHosts(candidates);
        if (candidates.isNotEmpty) {
          return await _quickCheckHosts(candidates);
        }
      } else {
        Logger.print('❌ 手动线路 OSS 无结果');
      }
    } catch (e) {
      Logger.print("❌ 手动线路 OSS 拉取异常: $e");
    }

    // -------- 第三步：默认兜底 --------
    Logger.print("⚠️ 所有来源均无结果，使用默认线路");
    final defaultOk = await _quickCheck(_defaultHost);
    return [
      ConfigLineOption(
        host: _defaultHost,
        success: defaultOk,
        duration: -1,
      )
    ];
  }

  /// 快速检测主机列表
  static Future<List<ConfigLineOption>> _quickCheckHosts(
      List<String> hosts) async {
    final results = <ConfigLineOption>[];
    final uniqueHosts = _dedupeHosts(hosts);

    // ⭐ 分批检测
    for (int i = 0; i < uniqueHosts.length; i += _batchSize) {
      final batch = uniqueHosts.skip(i).take(_batchSize).toList();
      final futures = batch.map((host) async {
        final ok = await _quickCheck(host);
        return ConfigLineOption(
          host: host,
          success: ok,
          duration: -1,
        );
      }).toList();

      results.addAll(await Future.wait(futures));
    }

    return results;
  }

  /// 后台测速：每完成一条就回调一次，便于界面实时刷新。
  static Future<List<ConfigLineOption>> fetchManualLineLatencies(
    List<String> hosts, {
    void Function(ConfigLineOption result)? onResult,
  }) async {
    final candidates = _dedupeHosts(hosts);
    if (candidates.isEmpty) {
      return [];
    }

    final allResults = <ConfigLineOption>[];

    // ⭐ 分批测速，避免一次性发起过多请求
    for (int i = 0; i < candidates.length; i += _batchSize) {
      final batch = candidates.skip(i).take(_batchSize).toList();
      final futures = batch.map((host) async {
        final result = await _testHost(host);
        return ConfigLineOption(
          host: host,
          success: result.success,
          duration: result.success ? result.duration : -1,
        );
      }).toList();

      final batchResults = await Future.wait(futures);
      allResults.addAll(batchResults);

      // ⭐ 逐条回调
      for (final result in batchResults) {
        onResult?.call(result);
      }
    }

    // 排序：成功的在前，按延迟升序
    allResults.sort((a, b) {
      if (a.success != b.success) {
        return a.success ? -1 : 1;
      }
      return a.duration.compareTo(b.duration);
    });

    return allResults;
  }

  // ================== OSS 配置拉取（优化） ==================
  static Future<List<String>> _fetchHostList() async {
    HttpClient? client;
    try {
      client = _newClient(timeoutSec: 6);
      final request = await client.getUrl(Uri.parse(_configUrl));
      final response = await request.close();

      if (response.statusCode != 200) return [];

      final content = await response.transform(utf8.decoder).join();

      final hosts = content
          .split(RegExp(r'[\r\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.startsWith("https://"))
          .toList();

      final deduped = _dedupeHosts(hosts);
      Logger.print("🌐 OSS线路: ${deduped.length}");
      return deduped;
    } catch (e) {
      Logger.print("❌ OSS 拉取失败: $e");
      return [];
    } finally {
      client?.close(force: true);
    }
  }

  // ================== 测速选最快（优化并发） ==================
  static Future<String?> _findBestHost(List<String> hosts,
      {String tag = ""}) async {
    final expanded = _dedupeHosts(hosts);
    if (expanded.isEmpty) {
      Logger.print("⚠️ [$tag] 无候选线路");
      return null;
    }

    Logger.print("🏁 [$tag] 候选: ${expanded.length}");

    final allResults = <_HostResult>[];

    // ⭐ 分批测速
    for (int i = 0; i < expanded.length; i += _batchSize) {
      final batch = expanded.skip(i).take(_batchSize).toList();
      final futures = batch.map((host) => _testHost(host)).toList();
      final batchResults = await Future.wait(futures);
      allResults.addAll(batchResults);
    }

    final success = allResults.where((e) => e.success).toList();

    if (success.isEmpty) {
      Logger.print("❌ [$tag] 无可用线路");
      return null;
    }

    success.sort((a, b) => a.duration.compareTo(b.duration));

    Logger.print(
        "🏆 [$tag] 最优: ${success.first.host} (${success.first.duration}ms)");
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
      var testUrl = url;
      if (!testUrl.endsWith('/')) {
        testUrl = "$testUrl/";
      }
      testUrl = "${testUrl}admin/scripts/loading.js";

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
    } catch (e) {
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

class _PendingHostResult {
  final String host;
  final _HostResult result;

  const _PendingHostResult({required this.host, required this.result});
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
