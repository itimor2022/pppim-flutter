import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:openim_common/src/controller/cache_controller.dart';

class StorageManageLogic extends GetxController {
  final tempSize = 0.obs;
  final downloadSize = 0.obs;
  final cacheSize = 0.obs;
  final favoriteCount = 0.obs;
  final callRecordCount = 0.obs;
  final isLoading = false.obs;

  final cacheController = Get.find<CacheController>();

  @override
  void onReady() {
    super.onReady();
    loadCacheSizes();
    super.onReady();
  }

  Future<void> loadCacheSizes() async {
    isLoading.value = true;
    try {
      final sizes = await IMUtils.getCacheSizes();
      tempSize.value = sizes['temp'] ?? 0;
      downloadSize.value = sizes['download'] ?? 0;
      cacheSize.value = sizes['cache'] ?? 0;
      favoriteCount.value = cacheController.getFavoriteCount();
      callRecordCount.value = cacheController.getCallRecordCount();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearTemp() async {
    final size = await IMUtils.clearTempFiles();
    tempSize.value = 0;
    IMViews.showToast('已清理 ${IMUtils.formatFileSize(size)}');
  }

  Future<void> clearDownload() async {
    final size = await IMUtils.clearDownloadFiles();
    downloadSize.value = 0;
    IMViews.showToast('已清理 ${IMUtils.formatFileSize(size)}');
  }

  Future<void> clearCache() async {
    final size = await IMUtils.clearApplicationCache();
    cacheSize.value = 0;
    IMViews.showToast('已清理 ${IMUtils.formatFileSize(size)}');
  }

  Future<void> clearFavorite() async {
    await cacheController.clearFavoriteEmoji();
    favoriteCount.value = 0;
    IMViews.showToast('已清理');
  }

  Future<void> clearCallRecords() async {
    await cacheController.clearCallRecords();
    callRecordCount.value = 0;
    IMViews.showToast('已清理');
  }

  Future<void> clearAll() async {
    await clearTemp();
    await clearDownload();
    await clearCache();
    await clearFavorite();
    await clearCallRecords();
    IMViews.showToast('已清理完成');
  }
}