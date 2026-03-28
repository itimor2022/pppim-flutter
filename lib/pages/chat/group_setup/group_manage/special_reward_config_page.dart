import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'special_reward_config_logic.dart';

class SpecialRewardConfigPage extends StatelessWidget {
  const SpecialRewardConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(SpecialRewardConfigLogic());

    return Scaffold(
      appBar: TitleBar.back(
        title: '特殊金额奖励配置 (全局)',
        right: GestureDetector(
          onTap: logic.saveConfigs,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: '保存'.toText..style = Styles.ts_0C1C33_17sp,
          ),
        ),
      ),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.isLoading.value && logic.configs.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          children: [
            ...logic.configs.asMap().entries.map((entry) {
              final index = entry.key;
              final amountCtrl = logic.grabCtrls[index];
              final rewardCtrl = logic.rewardCtrls[index];

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Styles.c_FFFFFF,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        '配置项 ${index + 1}'.toText..style = Styles.ts_0C1C33_17sp..style = TextStyle(fontWeight: FontWeight.bold),
                        GestureDetector(
                          onTap: () => logic.removeConfig(index),
                          child: Icon(Icons.delete, color: Colors.red, size: 20.w),
                        ),
                      ],
                    ),
                    Divider(height: 16.h, color: Styles.c_F4F5F7),
                    _buildInputItem('触发抢到的金额(元):', amountCtrl),
                    SizedBox(height: 10.h),
                    _buildInputItem('派发奖励金额(元):', rewardCtrl),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: logic.addConfig,
              child: Container(
                height: 44.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Styles.c_FFFFFF,
                  border: Border.all(color: Styles.c_0089FF),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: '+ 添加特殊奖励配置'.toText..style = TextStyle(color: Styles.c_0089FF, fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        );
      }),
    );
  }

  Widget _buildInputItem(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: label.toText..style = Styles.ts_0C1C33_17sp,
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4.h),
              border: InputBorder.none,
              hintText: '如 5.20',
              hintStyle: Styles.ts_8E9AB0_14sp,
            ),
            style: Styles.ts_0C1C33_17sp,
          ),
        ),
      ],
    );
  }
}
