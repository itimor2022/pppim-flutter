import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:openim_common/openim_common.dart';

import 'app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
} 

// 配置自定义缓存管理器
class CustomCacheManager extends fcm.CacheManager with fcm.ImageCacheManager {
  static const key = 'customCacheKey';
  
  static final CustomCacheManager _instance = CustomCacheManager._internal();
  
  factory CustomCacheManager() {
    return _instance;
  }
  
  CustomCacheManager._internal()
      : super(fcm.Config(
          key,
          stalePeriod: const Duration(days: 7), // 7天后缓存过期
          maxNrOfCacheObjects: 200, // 最多缓存200个文件
        ));
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  FlutterBugly.postCatchedException(
      () => Config.init(() => runApp(const ChatApp())));
}
