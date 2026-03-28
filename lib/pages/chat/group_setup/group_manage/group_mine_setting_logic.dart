import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

class GroupMineSettingLogic extends GetxController {
  final String groupID;

  final isLoading = true.obs;
  final isOpen = 1.obs;
  // 改为列表，支持多个免死号
  final deathFreeUsers = <String>[].obs;

  GroupMineSettingLogic({required this.groupID});

  @override
  void onInit() {
    super.onInit();
    _fetchSetting();
  }

  Future<void> _fetchSetting() async {
    try {
      isLoading.value = true;
      final res = await Apis.getGroupMineSetting(groupID: groupID);
      if (res != null) {
        isOpen.value = res['is_open'] ?? 1;
        // 兼容旧的单字符串格式：将逗号或竖线分隔的 userID 转为列表
        final raw = (res['death_free_user'] as String?) ?? '';
        if (raw.isEmpty) {
          deathFreeUsers.clear();
        } else {
          deathFreeUsers.assignAll(
            raw
                .split(RegExp(r'[,|/]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          );
        }
      }
    } catch (e) {
      Logger.print("fetch setting error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveSetting() async {
    try {
      await LoadingView.singleton.wrap(asyncFunction: () async {
        // 多个免死号用逗号拼接后保存到 death_free_user 字段
        await Apis.setGroupMineSetting(setting: {
          'group_id': groupID,
          'is_open': isOpen.value,
          'death_free_user': deathFreeUsers.join(','),
        });
      });
      IMViews.showToast('设置成功');
    } catch (e) {
      Logger.print("save setting error: $e");
      IMViews.showToast('设置失败');
    }
  }

  void toggleIsOpen(bool value) {
    isOpen.value = value ? 1 : 0;
    _saveSetting();
  }

  /// 弹出输入框，添加一个新的免死号 UserID
  void addDeathFreeUser() async {
    String? uid = await Get.bottomSheet(_InputSheet(hint: '输入要添加的免死号 UserID'));
    if (uid != null && uid.trim().isNotEmpty) {
      if (deathFreeUsers.contains(uid.trim())) {
        IMViews.showToast('该用户已经是免死号了');
        return;
      }

      try {
        final members = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
          groupID: groupID,
          userIDList: [uid.trim()],
        );
        if (members.isEmpty) {
          IMViews.showToast('用户不在该群内容或查询失败');
          return;
        }
      } catch (e) {
        IMViews.showToast('群成员校验失败');
        return;
      }

      deathFreeUsers.add(uid.trim());
      _saveSetting();
    }
  }

  /// 删除指定的免死号
  void removeDeathFreeUser(String uid) {
    deathFreeUsers.remove(uid);
    _saveSetting();
  }
}

// 通用输入底部弹窗
class _InputSheet extends StatefulWidget {
  final String hint;
  const _InputSheet({this.hint = '输入 UserID'});

  @override
  _InputSheetState createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('添加免死号',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1C33))),
          SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: widget.hint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(result: _ctrl.text.trim()),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF0089FF)),
              child: Text('确认添加', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
