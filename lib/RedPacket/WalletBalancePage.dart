import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'Widgets/CompatibilityWidgets.dart';
import 'WalletBalanceController.dart';
import '../routes/app_pages.dart';

class WalletBalancePage extends GetView<WalletBalanceController> {
  const WalletBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarNewWidget(title: '我的钱包'),
      body: Container(
        color: const Color(0xffF8F8F8),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.w),
              padding: EdgeInsets.all(20.w),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DefaultText(
                    text: "余额",
                    fontSize: 16.sp,
                    textColor: Colors.black,
                  ),
                  Obx(() => DefaultText(
                        text: "${controller.balance.value} 元",
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        textColor: const Color(0xffFF563F),
                      )),
                ],
              ),
            ),
            SizedBox(height: 10.w),
            _buildMenuItem(
                "支付密码设置", () => Get.toNamed(AppRoutes.setPayPassword)),
            Container(height: 1, color: Colors.grey[200]),
            _buildMenuItem("提现", () => Get.toNamed(AppRoutes.withdraw)),
            Container(height: 1, color: Colors.grey[200]),
            _buildMenuItem(
                "红包记录", () => Get.toNamed(AppRoutes.redPacketRecordList)),
            Container(height: 1, color: Colors.grey[200]),
            _buildMenuItem("钱包明细", () => Get.toNamed(AppRoutes.walletRecords)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.w),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultText(
              text: title,
              fontSize: 16.sp,
              textColor: Colors.black,
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
