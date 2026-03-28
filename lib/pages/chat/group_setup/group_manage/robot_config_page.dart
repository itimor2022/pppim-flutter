import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'robot_config_logic.dart';

class RobotConfigPage extends StatelessWidget {
  final String groupID;

  const RobotConfigPage({Key? key, required this.groupID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(RobotConfigLogic(groupID: groupID));

    return Scaffold(
      appBar: TitleBar.back(
        title: '群机器人高级设置',
        right: GestureDetector(
          onTap: logic.saveConfig,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: '保存'.toText..style = Styles.ts_0C1C33_17sp,
          ),
        ),
      ),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Styles.c_FFFFFF,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                children: [
                  _buildItemView(
                    text: '自动抢包',
                    showSwitchButton: true,
                    switchOn: logic.autoGrab.value == 1,
                    onChanged: (val) => logic.autoGrab.value = val ? 1 : 0,
                  ),
                  Divider(height: 1.h, color: Styles.c_F4F5F7, indent: 16.w),
                  _buildInputItem(
                    text: '抢包延迟 (秒)',
                    controller: logic.grabDelayCtrl,
                  ),
                  Divider(height: 1.h, color: Styles.c_F4F5F7, indent: 16.w),
                  _buildItemView(
                    text: '自动发包',
                    showSwitchButton: true,
                    switchOn: logic.autoSend.value == 1,
                    onChanged: (val) => logic.autoSend.value = val ? 1 : 0,
                  ),
                  Divider(height: 1.h, color: Styles.c_F4F5F7, indent: 16.w),
                  _buildInputItem(
                    text: '发包间隔 (秒)',
                    controller: logic.sendIntervalCtrl,
                  ),
                  Divider(height: 1.h, color: Styles.c_F4F5F7, indent: 16.w),
                  _buildInputItem(
                    text: '发包雷号池 (如 1/2/3)',
                    controller: logic.sendMinePoolCtrl,
                    hint: "雷号用/分隔",
                  ),
                  Divider(height: 1.h, color: Styles.c_F4F5F7, indent: 16.w),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              decoration: BoxDecoration(
                color: Styles.c_FFFFFF,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Expanded(
                            child: '发包抓包机器人列表'.toText
                              ..style = Styles.ts_0C1C33_17sp),
                        GestureDetector(
                          onTap: logic.addMachineUser,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                                color: Styles.c_0089FF,
                                borderRadius: BorderRadius.circular(12.r)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    color: Colors.white, size: 14.r),
                                SizedBox(width: 4.w),
                                '添加'.toText
                                  ..style = const TextStyle(
                                      color: Colors.white, fontSize: 13),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (logic.machineUsers.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      child: '暂未设置机器号，点击添加'.toText
                        ..style = Styles.ts_8E9AB0_14sp,
                    )
                  else
                    ...logic.machineUsers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final uid = entry.value;
                      return Column(
                        children: [
                          if (idx > 0)
                            Divider(
                                height: 1.h,
                                color: Styles.c_F4F5F7,
                                indent: 16.w),
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 2.h),
                            leading: CircleAvatar(
                              radius: 18.r,
                              backgroundColor:
                                  Styles.c_0089FF.withOpacity(0.15),
                              child: Icon(Icons.smart_toy,
                                  color: Styles.c_0089FF, size: 18.r),
                            ),
                            title: Text(uid, style: Styles.ts_0C1C33_17sp),
                            trailing: GestureDetector(
                              onTap: () => logic.removeMachineUser(uid),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8.r)),
                                child: Text('删除',
                                    style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemView({
    required String text,
    String? value,
    bool switchOn = false,
    bool showSwitchButton = false,
    bool showRightArrow = false,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Expanded(
              child: text.toText..style = Styles.ts_0C1C33_17sp,
            ),
            if (value != null) value.toText..style = Styles.ts_8E9AB0_14sp,
            if (showSwitchButton)
              CupertinoSwitch(
                value: switchOn,
                activeColor: Styles.c_0089FF,
                onChanged: onChanged,
              ),
            if (showRightArrow)
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: ImageRes.rightArrow.toImage
                  ..width = 16.w
                  ..height = 16.h,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputItem({
    required String text,
    required TextEditingController controller,
    String? hint,
  }) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: text.toText..style = Styles.ts_0C1C33_17sp,
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint ?? '输入数值',
                hintStyle: Styles.ts_8E9AB0_14sp,
              ),
              style: Styles.ts_0C1C33_17sp,
            ),
          ),
        ],
      ),
    );
  }
}
