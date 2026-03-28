import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'workbench_logic.dart';

class WorkbenchPage extends StatelessWidget {
  final logic = Get.find<WorkbenchLogic>();

  WorkbenchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.workbench(),
      backgroundColor: Styles.c_F8F9FA,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Original H5 Discovery Logic (Commented out per user request)
    // return Obx(() => H5Container(url: logic.url.value));

    return SmartRefresher(
      controller: logic.refreshCtrl,
      header: IMViews.buildHeader(),
      enablePullDown: true,
      enablePullUp: false,
      onRefresh: logic.refreshList,
      child: Obx(() => logic.list.isNotEmpty ? _buildMPView() : _emptyListView),
    );
  }

  Widget _buildMPView() => ListView.separated(
        padding: EdgeInsets.only(top: 12.h),
        itemCount: logic.list.length,
        separatorBuilder: (_, __) => Divider(
          height: 0.5.h,
          thickness: 0.5.h,
          color: Styles.c_E8EAEF,
          indent: 54.w,
        ),
        itemBuilder: (_, index) {
          final info = logic.list.elementAt(index);
          print("info.value.icon: ${info.value.icon}");
          return Obx(() => GestureDetector(
                onTap: () => logic.startUniMP(info),
                child: _buildItemView(info.value),
              ));
        },
      );

  Widget _buildItemView(UniMPInfo info) => Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        color: Styles.c_FFFFFF,
        child: Row(
          children: [
            Container(
              width: 28.h,
              height: 28.h,
              margin: EdgeInsets.only(right: 12.w),
              child: Stack(
                children: [
                  info.icon != null
                      ? ImageUtil.networkImage(
                          url: info.icon!,
                          width: 28.h,
                          height: 28.h,
                        )
                      : const SizedBox(),
                  if (null != info.progress &&
                      info.progress! > 0 &&
                      info.progress! < 100)
                    Container(
                      width: 28.h,
                      height: 28.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: '${info.progress}%'.toText
                        ..style = Styles.ts_FFFFFF_10sp,
                    )
                ],
              ),
            ),
            Expanded(
              child: (info.name ?? '').toText..style = Styles.ts_0C1C33_17sp,
            ),
            ImageRes.rightArrow.toImage
              ..width = 16.w
              ..height = 16.h,
          ],
        ),
      );

  Widget get _emptyListView => ListView(
        children: [
          SizedBox(
            width: 1.sw,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                157.verticalSpace,
                ImageRes.blacklistEmpty.toImage
                  ..width = 120.w
                  ..height = 120.h,
                22.verticalSpace,
                StrRes.notFoundMinP.toText..style = Styles.ts_8E9AB0_16sp,
              ],
            ),
          ),
        ],
      );
}
