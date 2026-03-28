import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'Widgets/CompatibilityWidgets.dart';
import 'RedPacketRecordsController.dart';
import '../routes/app_pages.dart';

class RedPacketRecordsPage extends GetView<RedPacketRecordsController> {
  @override
  Widget build(BuildContext context) {
    return DefaultContainer(
      assetSrc: 'assets/images/220.png',
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBarNewWidget(
          title: '',
          backgroundColor: Colors.transparent,
          titleColor: Colors.white,
          actions: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.redPacketRecordList),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 15.w),
                  child: Text(
                    "红包记录",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        body: SafeArea(
          child: Obx(
            () => Column(
              children: [
                // Note: radBagList logic might need null checks in controller or here.
                // Assuming controller initializes it safe.
                Center(
                  child: DefaultContainer(
                    color: const Color(0xffFFE9C7),
                    padding: EdgeInsets.all(2.w),
                    borderRadius: 100,
                    child: AvatarView(
                      url: "${controller.radBagList.value.avatar}",
                      text: "${controller.radBagList.value.nickname}",
                      width: 64.w,
                      height: 64.w,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                ),
                DefaultContainer(
                  color: Colors.transparent,
                  margin: EdgeInsets.only(top: 16.w, bottom: 4.w),
                  child: DefaultText(
                    text:
                        "${controller.radBagList.value.nickname}发出的${getRedBagType()}",
                    fontSize: 18.sp,
                    textColor: const Color(0xff161616),
                  ),
                ),
                DefaultContainer(
                  color: Colors.transparent,
                  margin: EdgeInsets.only(bottom: 8.w),
                  child: DefaultText(
                    text: "${controller.radBagList.value.redPacketRemarks}",
                    fontSize: 14.sp,
                    textColor: const Color(0xffB3B3B3),
                  ),
                ),

                /// 如果已领取 就显示领取金额
                if (controller.radBagList.value.down!)
                  DefaultContainer(
                    color: Colors.transparent,
                    margin: EdgeInsets.only(bottom: 40.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DefaultText(
                          text: "${controller.radBagList.value.money} 元",
                          fontSize: 44.sp,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xffFC4F3E),
                        ),
                      ],
                    ),
                  ),

                /// 不是我领取的
                if (!controller.radBagList.value.down!)
                  DefaultContainer(
                    color: Colors.transparent,
                    margin: EdgeInsets.only(bottom: 40.w),
                  ),

                DefaultContainer(
                  color: Colors.transparent,
                  margin: EdgeInsets.only(left: 12.w, bottom: 8.w),
                  alignment: Alignment.centerLeft,
                  child: DefaultText(
                    text: controller.radBagList.value.mopTime != "0"
                        ? "${controller.radBagList.value.totalPacket}个红包，${controller.radBagList.value.mopTime}被抢完"
                        : "${controller.radBagList.value.expired! ? "已过期。" : ""}已被领取 ${(controller.radBagList.value.totalPacket ?? 0) - (controller.radBagList.value.remainingPacket ?? 0)}/${controller.radBagList.value.totalPacket}个，共 ${controller.radBagList.value.downAmount}/${controller.radBagList.value.totalAmount} 元",
                    fontSize: 14.sp,
                    textColor: const Color(0xffB3B3B3),
                  ),
                ),
                controller.radBagList.value.redLists == null &&
                        controller.radBagList.value.redLists!.isEmpty
                    ? const SizedBox()
                    : Expanded(
                        child: SingleChildScrollView(
                        child: Column(
                          children:
                              controller.radBagList.value.redLists!.map((e) {
                            return Container(
                              padding: EdgeInsets.only(
                                  left: 12.w,
                                  right: 12.w,
                                  top: 10.w,
                                  bottom: 10.w),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: const Color(0xffE5E5E5),
                                      width: 1.w),
                                ),
                              ),
                              child: Row(
                                children: [
                                  AvatarView(
                                    url: "${e.avatar}",
                                    text: "${e.nickname}",
                                    borderRadius: BorderRadius.circular(100.r),
                                    width: 44.w,
                                    height: 44.w,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DefaultText(
                                          text: "${e.nickname}",
                                          fontSize: 16.sp,
                                          textColor: const Color(0xff333333),
                                        ),
                                        DefaultText(
                                          text: "${e.receiveDate}",
                                          fontSize: 13.sp,
                                          textColor: const Color(0xff939393),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          DefaultText(
                                            text: "${e.money} 元",
                                            fontSize: 16.sp,
                                            textColor: const Color(0xff343434),
                                          ),
                                          if (e.isHit == true)
                                            Container(
                                              margin:
                                                  EdgeInsets.only(left: 4.w),
                                              child: DefaultText(
                                                text: "💣",
                                                fontSize: 16.sp,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (e.bestLuck == 1)
                                        DefaultContainer(
                                          color: const Color(0xffFFECEE),
                                          borderRadius: 100,
                                          margin: EdgeInsets.only(top: 5.w),
                                          padding: EdgeInsets.only(
                                              left: 5.w,
                                              right: 5.w,
                                              top: 2.w,
                                              bottom: 2.w),
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                'assets/images/223.png',
                                                width: 16.w,
                                              ),
                                              DefaultText(
                                                text: "手气最佳",
                                                textColor:
                                                    const Color(0xffFD1C51),
                                                fontSize: 12.sp,
                                              )
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )),
                if (!controller.radBagList.value.expired! &&
                    controller.radBagList.value.remainingPacket! > 0)
                  Container(
                    margin: EdgeInsets.only(bottom: 20.w),
                    child: DefaultText(
                      text: "未领取的红包，将在24小时后发起退款",
                      fontSize: 12.sp,
                      textColor: const Color(0xffB3B3B3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 红包类型
  String getRedBagType() {
    if (controller.radBagList.value.packetType == 1) {
      return '普通红包';
    } else if (controller.radBagList.value.packetType == 2) {
      return '拼手气红包';
    } else if (controller.radBagList.value.packetType == 6) {
      return '扫雷红包';
    } else {
      return '专属红包';
    }
  }
}
