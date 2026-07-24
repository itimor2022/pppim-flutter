import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'storage_manage_logic.dart';

class StorageManagePage extends StatelessWidget {
  final logic = Get.find<StorageManageLogic>();

  StorageManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(title: '存储空间'),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() => logic.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryCard(),
                  10.verticalSpace,
                  _buildItem(
                    title: '临时文件',
                    size: IMUtils.formatFileSize(logic.tempSize.value),
                    onTap: () => _showClearDialog('临时文件', logic.clearTemp),
                  ),
                  _buildItem(
                    title: '下载文件',
                    size: IMUtils.formatFileSize(logic.downloadSize.value),
                    onTap: () => _showClearDialog('下载文件', logic.clearDownload),
                  ),
                  _buildItem(
                    title: '图片缓存',
                    size: IMUtils.formatFileSize(logic.cacheSize.value),
                    onTap: () => _showClearDialog('图片缓存', logic.clearCache),
                  ),
                  _buildItem(
                    title: '收藏表情',
                    size: '${logic.favoriteCount.value} 个',
                    onTap: () => _showClearDialog('收藏表情', logic.clearFavorite),
                  ),
                  _buildItem(
                    title: '通话记录',
                    size: '${logic.callRecordCount.value} 条',
                    onTap: () => _showClearDialog('通话记录', logic.clearCallRecords),
                  ),
                  20.verticalSpace,
                  _buildClearAllButton(),
                ],
              ),
            )),
    );
  }

  Widget _buildSummaryCard() {
    final totalSize = logic.tempSize.value +
        logic.downloadSize.value + logic.cacheSize.value;
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(6.r),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 10.h,
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          '存储空间使用情况'.toText
            ..style = Styles.ts_0C1C33_17sp,
          20.verticalSpace,
          Container(
            height: 80.h,
            width: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Styles.c_0089FF, width: 4.w),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IMUtils.formatFileSize(totalSize).toText
                    ..style = TextStyle(
                      color: Styles.c_0089FF,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  4.verticalSpace,
                  '总计'.toText..style = Styles.ts_8E9AB0_12sp,
                ],
              )),
          ),
          20.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required String size,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(6.r),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 5.h,
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            child: Container(
              height: 57.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  title.toText..style = Styles.ts_0C1C33_17sp,
                  const Spacer(),
                  size.toText..style = Styles.ts_8E9AB0_14sp,
                  8.horizontalSpace,
                  ImageRes.rightArrow.toImage
                    ..width = 24.w
                    ..height = 24.h,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearAllButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      child: Button(
        text: '清理全部',
        onTap: () => _showClearDialog('全部数据', logic.clearAll),
        textStyle: Styles.ts_FFFFFF_17sp,
        height: 44.h,
        enabledColor: Styles.c_FF381F,
        radius: 6.r,
      ),
    );
  }

  void _showClearDialog(String title, Future<void> Function() onConfirm) {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('确认清理'),
        content: Text('确定要清理 $title 吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('确定'),
            onPressed: () {
              Get.back();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}
