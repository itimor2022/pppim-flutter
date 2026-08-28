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
  static const String _defaultHost = "https://172.252.172.80:443";

  /// ⭐ 远程线路配置（OSS）
  static const String _configUrl =
      "https://d2pvzx7xdvbqsq.cloudfront.net/im/qaq.txt";

  /// ⭐ 国内 DNS TXT 配置域名列表
  static const List<String> _dnsConfigDomains = [
    "cfg.147995.top",
    "cfg.147993.top",
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

  /// ⭐ 初始化阶段是否已完成（避免runApp前host被意外修改）
  static bool _initialized = false;

  static void addHostChangedListener(
      void Function(String oldHost, String newHost) listener) {
    _hostChangedListeners.add(listener);
  }

  static void removeHostChangedListener(
      void Function(String oldHost, String newHost) listener) {
    _hostChangedListeners.remove(listener);
  }

  /// ⭐ 公开的线路切换方法
  static Future<void> setServerHost(String host, {bool persist = true}) async {
    if (host.trim().isEmpty) {
      throw Exception('host 不能为空');
    }

    // 确保是 https 协议
    var newHost = host.trim();
    if (!newHost.startsWith('http://') && !newHost.startsWith('https://')) {
      newHost = 'https://$newHost';
    }

    // 移除末尾斜杠
    if (newHost.endsWith('/')) {
      newHost = newHost.substring(0, newHost.length - 1);
    }

    // ⭐ 关键：先校验 host 合法性（Uri.parse 可能抛 FormatException）
    if (!_isValidUrl(newHost)) {
      Logger.print("❌ host 格式非法: $newHost");
      throw Exception('host 格式非法');
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
  }

  /// ⭐ 关键：host 合法性校验，防止 Uri.parse 抛 FormatException 闪退
  static bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    // host 不能包含非法字符（空格、控制字符等）
    if (RegExp(r'[\s\x00-\x1F\x7F]').hasMatch(url)) return false;
    return true;
  }

  static void _applyHost(String host, {bool persist = false}) {
    final nextHost = host.trim();
    if (nextHost.isEmpty) {
      Logger.print("⚠️ _applyHost 收到空 host，已忽略");
      return;
    }

    // 确保协议
    var finalHost = nextHost;
    if (!finalHost.startsWith('http://') && !finalHost.startsWith('https://')) {
      finalHost = 'https://$finalHost';
    }
    if (finalHost.endsWith('/')) {
      finalHost = finalHost.substring(0, finalHost.length - 1);
    }

    // ⭐ 关键：赋值前再次校验，避免非法 host 被写入导致后续 getter 闪退
    if (!_isValidUrl(finalHost)) {
      Logger.print("❌ _applyHost 拒绝非法 host: $finalHost");
      return;
    }

    final oldHost = _host;
    if (oldHost == finalHost) {
      Logger.print("🔁 host 无变化: $finalHost");
      return;
    }

    _host = finalHost;
    Logger.print("🔄 host 切换: $oldHost -> $_host (persist=$persist)");

    if (persist) {
      // ⭐ 关键：fire-and-forget 的 persist 应在 try-catch 中，避免 IO 异常
      try {
        DataSp.putServerConfig({"serverIP": _host});
        Logger.print("💾 已持久化线路: $_host");
      } catch (e) {
        Logger.print("⚠️ 持久化线路异常: $e");
      }
    }

    // ⭐ 关键：refreshBaseUrl 必须 try-catch，防止 imApiUrl getter 抛异常
    try {
      HttpUtil.refreshBaseUrl();
    } catch (e) {
      Logger.print("⚠️ refreshBaseUrl 异常: $e");
    }

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

  /// ⭐ 关键：safeUri 不抛异常（Uri.tryParse），避免 getter 闪退
  static Uri? get _hostUri {
    if (!_hasScheme) return null;
    try {
      return Uri.tryParse(_host);
    } catch (_) {
      return null;
    }
  }

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

  /// ⭐ 统一的 HttpClient 工厂
  /// - 忽略证书校验，避免 IP+HTTPS / 自签名导致握手失败
  /// - ⭐ 设置 idleTimeout，防止 keep-alive 连接堆积导致文件描述符耗尽
  /// - ⭐ 设置 maxConnectionsPerHost 限制单 host 并发
  static HttpClient _newClient({int timeoutSec = 5}) {
    return HttpClient()
      ..connectionTimeout = Duration(seconds: timeoutSec)
      ..idleTimeout = Duration(seconds: timeoutSec)
      ..maxConnectionsPerHost = 4
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

      // ⭐ 关键：从缓存读取的 host 必须校验合法性，非法则回退默认
      final cache = DataSp.getServerConfig();
      final cachedHost = cache?['serverIP']?.toString();
      if (cachedHost != null &&
          cachedHost.isNotEmpty &&
          _isValidUrl(cachedHost)) {
        _applyHost(cachedHost);
        Logger.print("⚡ 初始化阶段读取缓存线路: $_host");
      } else {
        Logger.print(
            "ℹ️ 缓存线路为空或不合法，当前使用默认: $_host (cache=${cachedHost ?? 'null'})");
      }

      // ⭐ 关键：异步执行 initHost，不阻塞 runApp，避免长时间黑屏/ANR
      // 兜底：即使后台初始化失败，runApp 也能正常进入
      unawaited(_initHostSafely());

      _initialized = true;
    } catch (e, st) {
      Logger.print("初始化异常: $e\n$st");
      _initialized = true;
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

    try {
      FlutterBugly.init(androidAppId: "", iOSAppId: "");
    } catch (e) {
      Logger.print("⚠️ FlutterBugly.init 异常: $e");
    }
  }

  /// ⭐ 关键：后台异步线路初始化，全部包裹 try-catch，绝不抛出未捕获异常
  static Future<void> _initHostSafely() async {
    try {
      await _initHost();
    } catch (e, st) {
      Logger.print("❌ _initHostSafely 未捕获异常: $e\n$st");
      // 即便异常，也保证 host 至少是默认兜底
      try {
        if (!_isValidUrl(_host)) {
          _applyHost(_defaultHost);
        }
      } catch (_) {}
    }
  }

  // ================== 线路初始化（核心调度）==================
  static Future<void> _initHost() async {
    Logger.print("================ _initHost START ================");

    // -------- 第一步：缓存线路优先 --------
    try {
      final cached = DataSp.getServerConfig()?['serverIP']?.toString();
      if (cached != null &&
          cached.isNotEmpty &&
          _isValidUrl(cached) &&
          cached != _host) {
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
        Logger.print("ℹ️ 无缓存线路或已应用");
      }
    } catch (e) {
      Logger.print("❌ 缓存线路处理异常: $e");
    }

    // -------- 第二步：DNS 查询（优先）--------
    Logger.print("---------------- 步骤1: DNS 查询 ----------------");
    try {
      final dnsHosts = await _fetchHostsFromDNS();
      if (dnsHosts.isNotEmpty) {
        Logger.print("✅ DNS 查询成功，获取到 ${dnsHosts.length} 条线路");
        final picked = await _pickFirstAvailable(dnsHosts);
        if (picked != null) {
          _applyHost(picked);
          Logger.print("✅ DNS 线路可用: $picked");
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
        final picked = await _pickFirstAvailable(ossHosts);
        if (picked != null) {
          _applyHost(picked);
          Logger.print("✅ OSS 线路可用: $picked");
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
    try {
      final defaultOk = await _quickCheck(_defaultHost);
      if (defaultOk) {
        _applyHost(_defaultHost);
        Logger.print("✅ 默认域名可用: $_defaultHost");
      } else {
        // 即便默认不通，也保证 host 至少是 _defaultHost（避免空 host 导致后续 getter 闪退）
        _applyHost(_defaultHost);
        Logger.print("❌ 默认域名也不通，但仍然应用: $_defaultHost（避免空 host）");
      }
    } catch (e) {
      Logger.print("❌ 默认兜底异常: $e");
      // ⭐ 关键兜底：任何异常都要保证 host 是合法值
      try {
        _applyHost(_defaultHost);
      } catch (_) {}
    }

    Logger.print("================ _initHost END ==================");
  }

  /// ⭐ 关键：批量校验 + 短路返回。任何一个可用就立即返回剩余的不再测。
  /// 避免对所有 host 全部测一遍浪费时间和资源。
  static Future<String?> _pickFirstAvailable(List<String> hosts) async {
    for (final host in hosts) {
      try {
        if (!_isValidUrl(host)) continue;
        if (await _quickCheck(host)) {
          return host;
        }
      } catch (e) {
        Logger.print("⚠️ _pickFirstAvailable 单个 host 异常: $host -> $e");
      }
    }
    return null;
  }

  static Future<List<_HostResult>> _runLimited(
    List<String> items,
    int concurrency,
    Future<_HostResult> Function(String url) fn,
  ) async {
    final results = <_HostResult>[];
    final List<int> indices = List.generate(items.length, (i) => i);

    // 分批处理
    for (int i = 0; i < indices.length; i += concurrency) {
      final batch = indices.skip(i).take(concurrency).toList();
      final batchResults =
          await Future.wait(batch.map((index) => fn(items[index])).toList());
      results.addAll(batchResults);
    }

    return results;
  }

// 简单的同步工具
  static void synchronized(Object lock, void Function() action) {
    // Dart 是单线程的，这里主要是为了代码清晰
    // 实际可以使用 synchronized 包
    action();
  }

  // ================== 快速健康检查 ==================
  static Future<bool> _quickCheck(String host) async {
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

      // ⭐ 关键：Uri.parse 用 tryParse 替代，host 含特殊字符时不再抛异常
      final uri = Uri.tryParse("$baseUrl/admin/scripts/loading.js");
      if (uri == null) {
        Logger.print("⚡ quickCheck url 非法: $baseUrl");
        return false;
      }

      client = _newClient(timeoutSec: 3);
      final request = await client.getUrl(uri);
      final response = await request.close();
      try {
        await response.drain<void>().timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
      } catch (_) {}
      stopwatch.stop();

      final ok = response.statusCode == 200;
      Logger.print(
          "⚡ quickCheck $uri -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms) ${ok ? "✅" : "❌"}");
      return ok;
    } catch (e) {
      stopwatch.stop();
      Logger.print(
          "⚡ quickCheck $host -> 异常 (${stopwatch.elapsedMilliseconds}ms): $e");
      return false;
    } finally {
      try {
        client?.close(force: true);
      } catch (_) {}
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
    // 遍历所有 DNS 配置域名
    for (final domain in _dnsConfigDomains) {
      Logger.print("📡 尝试 DNS 查询: $domain");

      // 遍历所有 DoH 服务器
      for (final dohUrl in _dohServers) {
        HttpClient? client;
        try {
          final dohUri = Uri.tryParse(dohUrl);
          if (dohUri == null) continue;
          final uri = dohUri.replace(queryParameters: {
            'name': domain,
            'type': 'TXT',
            'ct': 'application/dns-json',
          });

          client = _newClient(timeoutSec: 7);
          final request = await client.getUrl(uri);
          request.headers.set('accept', 'application/dns-json');

          final response = await request.close();
          if (response.statusCode != 200) {
            try {
              client.close(force: true);
            } catch (_) {}
            client = null;
            continue;
          }

          // ⭐ 关键：join() 加超时，防止 chunked / Content-Length 不一致时永久挂起
          final body = await response
              .transform(utf8.decoder)
              .join()
              .timeout(const Duration(seconds: 5), onTimeout: () => '');
          try {
            client.close(force: true);
          } catch (_) {}
          client = null;

          if (body.isEmpty) continue;

          // ⭐ 关键：json.decode 用 try-catch 包裹，避免 body 非法时抛异常
          Map<String, dynamic> data;
          try {
            final decoded = json.decode(body);
            if (decoded is! Map<String, dynamic>) continue;
            data = decoded;
          } catch (_) {
            continue;
          }
          final answers = (data['Answer'] as List?) ?? [];

          for (final ans in answers) {
            if (ans is! Map) continue;
            if (ans['type'] != 16) continue;

            String txt = (ans['data'] ?? '')
                .toString()
                .replaceAll('"', '')
                .replaceAll('\\', '')
                .trim();

            if (txt.isEmpty) continue;

            List<String> hosts;

            // ⭐ 关键：base64 decode 容错（txt 可能是纯文本或 base64）
            try {
              final padded =
                  txt.length % 4 == 0 ? txt : txt + '=' * (4 - txt.length % 4);
              final decoded = utf8.decode(base64.decode(padded));
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
              Logger.print("✅ DNS 查询成功: $domain -> ${hosts.length} 条线路");
              // ⭐ 立即返回，不再继续查询
              return hosts;
            }
          }
        } catch (e) {
          Logger.print("⚠️ DoH 查询失败: $dohUrl, error: $e");
        } finally {
          try {
            client?.close(force: true);
          } catch (_) {}
        }
      }
    }

    Logger.print("❌ 所有 DNS 查询均失败");
    return [];
  }

  /// 手动切换线路时使用：优先 DNS，DNS 无结果时才回退 OSS。
  static Future<List<ConfigLineOption>> fetchManualLineOptions() async {
    List<String> candidates = [];

    // -------- 第一步：DNS 查询（优先）--------
    try {
      candidates = await _fetchHostsFromDNS();
      if (candidates.isNotEmpty) {
        Logger.print('✅ 手动线路来源: DNS (${candidates.length})');

        // DNS 返回的线路直接使用，不需要再走 OSS
        candidates = _dedupeHosts(candidates);
        if (candidates.isNotEmpty) {
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
      } else {
        Logger.print('❌ 手动线路 OSS 无结果');
      }
    } catch (e) {
      Logger.print("❌ 手动线路 OSS 拉取异常: $e");
    }

    // -------- 第三步：默认兜底 --------
    Logger.print("⚠️ 所有来源均无结果，使用默认线路");
    try {
      final defaultOk = await _quickCheck(_defaultHost);
      return [
        ConfigLineOption(
          host: _defaultHost,
          success: defaultOk,
          duration: -1,
        )
      ];
    } catch (e) {
      Logger.print("⚠️ 默认线路测速异常: $e");
      return [
        ConfigLineOption(
          host: _defaultHost,
          success: false,
          duration: -1,
        )
      ];
    }
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

    // ⭐ 关键：限制并发为 4，避免短时间内大量 HttpClient 堆积导致 OOM / 闪退
    const concurrency = 4;
    final all = <Future<_PendingHostResult>>[];

    Future<_PendingHostResult> runOne(String host) {
      return _testHost(host)
          .then<_PendingHostResult>(
        (result) => _PendingHostResult(host: host, result: result),
      )
          .catchError((e, s) {
        Logger.print("⚠️ _testHost 异常: $host -> $e");
        return _PendingHostResult(
          host: host,
          result: _HostResult(host: host, success: false, duration: 999999),
        );
      });
    }

    // ⭐ 用按批分组的方式实现并发限制（每批最多 concurrency 个）
    // 每个 future 完成时立即回调 onResult，实现 UI 实时刷新
    Future<_PendingHostResult> runOneWithCallback(String host) {
      final f = runOne(host);
      // ⭐ 挂一个链式 then 在 f 上，完成时回调，不影响 f 的主流程
      f.then((item) {
        try {
          onResult?.call(
            ConfigLineOption(
              host: item.host,
              success: item.result.success,
              duration: item.result.success ? item.result.duration : -1,
            ),
          );
        } catch (e) {
          Logger.print("⚠️ onResult 回调异常: $e");
        }
      }).catchError((e) {
        Logger.print("⚠️ onResult 链异常: $e");
      });
      return f;
    }

    for (int i = 0; i < candidates.length; i += concurrency) {
      final batch = candidates.skip(i).take(concurrency).toList();
      final batchFutures = batch.map(runOneWithCallback).toList();
      all.addAll(batchFutures);
      // 等待本批全部完成再开始下一批
      try {
        await Future.wait(batchFutures);
      } catch (e) {
        Logger.print("⚠️ 测速批次异常: $e");
      }
    }

    final results = <_HostResult>[];
    for (final f in all) {
      final item = await f;
      results.add(item.result);
    }

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
    HttpClient? client;
    try {
      client = _newClient(timeoutSec: 6);

      final configUri = Uri.tryParse(_configUrl);
      if (configUri == null) return [];
      final request = await client.getUrl(configUri);
      final response = await request.close();

      if (response.statusCode != 200) return [];

      // ⭐ 关键：join 加超时，防止无限挂起
      final content = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5), onTimeout: () => '');

      if (content.isEmpty) return [];

      final hosts = content
          .split(RegExp(r'[\r\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.startsWith("https://")) // ⭐ 强制 https
          .toList();

      final deduped = _dedupeHosts(hosts);
      Logger.print("🌐 OSS线路: ${deduped.length}");
      return deduped;
    } catch (e) {
      Logger.print("❌ _fetchHostList 异常: $e");
      return [];
    } finally {
      try {
        client?.close(force: true);
      } catch (_) {}
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
      // ⭐ 关键：testUrl 用 tryParse，非法 url 直接返回失败而非抛异常
      var testUrl = url;
      if (!testUrl.endsWith('/')) {
        testUrl = "$testUrl/";
      }
      testUrl = "${testUrl}admin/scripts/loading.js";

      final parsedUri = Uri.tryParse(testUrl);
      if (parsedUri == null) {
        stopwatch.stop();
        return _HostResult(host: url, success: false, duration: 999999);
      }

      client = _newClient(timeoutSec: 5);

      // ================= HEAD =================
      var request = await client.openUrl('HEAD', parsedUri);
      var response = await request.close();

      // ================= fallback GET =================
      if (response.statusCode >= 400) {
        try {
          await response.drain<void>().timeout(
                const Duration(seconds: 1),
                onTimeout: () {},
              );
        } catch (_) {}
        final getReq = await client.getUrl(parsedUri);
        response = await getReq.close();
      }

      try {
        await response.drain<void>().timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
      } catch (_) {}
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
      try {
        client?.close(force: true);
      } catch (_) {}
    }
  }

  // ================== 原有配置 ==================
  static late String cachePath;

  static const _ipRegex =
      '((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)';
  static bool get _isIP {
    try {
      final hostValue = _hostUri?.host ?? _host.split(':').first;
      return RegExp(_ipRegex).hasMatch(hostValue);
    } catch (_) {
      return false;
    }
  }

  static bool get isDynamicHostReady {
    try {
      return _host != _defaultHost && _isValidUrl(_host);
    } catch (_) {
      return false;
    }
  }

  static String get serverIp => _host;

  static String get imApiUrl {
    try {
      return "$_host/api";
    } catch (e) {
      Logger.print("⚠️ imApiUrl getter 异常: $e");
      return "$_defaultHost/api";
    }
  }

  static String get appAuthUrl {
    try {
      return "$_host/chat";
    } catch (e) {
      Logger.print("⚠️ appAuthUrl getter 异常: $e");
      return "$_defaultHost/chat";
    }
  }

  /// ⭐ 关键：imWsUrl 用 tryParse + 完整 try-catch，防止 host 非法时抛 FormatException 闪退
  static String get imWsUrl {
    try {
      // ⭐ 先校验 _host 合法性
      if (!_isValidUrl(_host)) {
        return "${_toWsScheme('https')}://${_extractHostSafe(_defaultHost)}/msg_gateway";
      }
      final uri = Uri.tryParse(_host);
      if (uri == null) {
        return "${_toWsScheme('https')}://${_extractHostSafe(_defaultHost)}/msg_gateway";
      }
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final port = uri.hasPort ? ':${uri.port}' : '';
      return "$scheme://${uri.host}$port/msg_gateway";
    } catch (e) {
      Logger.print("⚠️ imWsUrl getter 异常: $e，回退默认: $_defaultHost");
      return "${_toWsScheme('https')}://${_extractHostSafe(_defaultHost)}/msg_gateway";
    }
  }

  /// 从 url 中安全提取 host
  static String _extractHostSafe(String url) {
    try {
      final u = Uri.tryParse(url);
      if (u == null || u.host.isEmpty) return '127.0.0.1';
      return u.host;
    } catch (_) {
      return '127.0.0.1';
    }
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
