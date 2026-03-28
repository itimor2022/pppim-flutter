import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'group_mine_setting_logic.dart';

class GroupMineSettingPage extends StatelessWidget {
  final String groupID;

  const GroupMineSettingPage({Key? key, required this.groupID})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(GroupMineSettingLogic(groupID: groupID));

    return Scaffold(
      appBar: TitleBar.back(title: '群扫雷功能设置'),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          children: [
            // 扫雷总开关
            _SectionCard(children: [
              _buildItemView(
                text: '本群扫雷发包功能',
                showSwitchButton: true,
                switchOn: logic.isOpen.value == 1,
                onChanged: (val) => logic.toggleIsOpen(val),
              ),
            ]),

            SizedBox(height: 10.h),

            // 免死号列表区块
            _SectionCard(
              children: [
                // 标题行（含"添加"按钮）
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: '免死号列表 (承担特殊奖励)'.toText
                          ..style = Styles.ts_0C1C33_17sp,
                      ),
                      GestureDetector(
                        onTap: logic.addDeathFreeUser,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Styles.c_0089FF,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 14.r),
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

                // 免死号用户列表 or 空状态文案
                if (logic.deathFreeUsers.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: '暂未设置免死号，点击添加'.toText..style = Styles.ts_8E9AB0_14sp,
                  )
                else
                  ...logic.deathFreeUsers.asMap().entries.map((entry) {
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
                            backgroundColor: Styles.c_0089FF.withOpacity(0.15),
                            child: Icon(Icons.shield,
                                color: Styles.c_0089FF, size: 18.r),
                          ),
                          title: Text(uid, style: Styles.ts_0C1C33_17sp),
                          trailing: GestureDetector(
                            onTap: () => logic.removeDeathFreeUser(uid),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
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

            SizedBox(height: 16.h),

            // 说明文字
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child:
                  '说明：免死号用户在中雷时享受特殊待遇（按独包比例赔付或完全免赔），但需代为承担抢到靓号时的特殊奖励金额。'.toText
                    ..style = Styles.ts_8E9AB0_14sp,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemView({
    required String text,
    bool switchOn = false,
    bool showSwitchButton = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(child: text.toText..style = Styles.ts_0C1C33_17sp),
          if (showSwitchButton)
            CupertinoSwitch(
              value: switchOn,
              activeColor: Styles.c_0089FF,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

/// 通用白色卡片容器
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
