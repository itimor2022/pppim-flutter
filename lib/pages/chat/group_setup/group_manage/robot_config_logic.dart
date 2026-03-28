import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';

class RobotConfigLogic extends GetxController {
  final String groupID;

  final isLoading = true.obs;
  
  final autoGrab = 0.obs;
  final grabDelayCtrl = TextEditingController();
  final autoSend = 0.obs;
  final sendIntervalCtrl = TextEditingController();
  final sendMinePoolCtrl = TextEditingController();
  final machineUsers = <String>[].obs;

  RobotConfigLogic({required this.groupID});

  @override
  void onInit() {
    super.onInit();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      isLoading.value = true;
      final res = await Apis.getGroupRobotConfig(groupID: groupID);
      if (res != null) {
        autoGrab.value = res['auto_grab'] ?? 0;
        grabDelayCtrl.text = (res['grab_delay'] ?? 3).toString();
        autoSend.value = res['auto_send'] ?? 0;
        sendIntervalCtrl.text = (res['send_interval'] ?? 30).toString();
        sendMinePoolCtrl.text = res['send_mine_pool'] ?? "";
        
        final machineUsersStr = res['machine_users'] ?? "";
        if (machineUsersStr.isNotEmpty) {
           try {
              final decoded = jsonDecode(machineUsersStr);
              if (decoded is List) {
                 machineUsers.assignAll(decoded.map((e) => e.toString()).toList());
              }
           } catch(e) {}
        }
      }
    } catch (e) {
      Logger.print("fetch config error: \$e");
    } finally {
      isLoading.value = false;
    }
  }

  void saveConfig() async {
    try {
      final delay = int.tryParse(grabDelayCtrl.text) ?? 3;
      final interval = int.tryParse(sendIntervalCtrl.text) ?? 30;
      final finalMachineUsers = jsonEncode(machineUsers);

      await LoadingView.singleton.wrap(asyncFunction: () async {
        await Apis.setGroupRobotConfig(config: {
          'group_id': groupID,
          'auto_grab': autoGrab.value,
          'grab_delay': delay,
          'auto_send': autoSend.value,
          'send_interval': interval,
          'send_mine_pool': sendMinePoolCtrl.text,
          'machine_users': finalMachineUsers,
        });
      });
      IMViews.showToast('高级功能设置成功');
      Get.back();
    } catch (e) {
      Logger.print("save config error: \$e");
      IMViews.showToast('设置失败');
    }
  }

  void addMachineUser() async {
    String? uid = await Get.bottomSheet(_RobotInputSheet(hint: '输入要添加的机器号 UserID'));
    if (uid != null && uid.trim().isNotEmpty) {
      if (machineUsers.contains(uid.trim())) {
        IMViews.showToast('该机器号已经在列表中了');
        return;
      }
      
      try {
        final members = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
          groupID: groupID,
          userIDList: [uid.trim()],
        );
        if (members.isEmpty) {
          IMViews.showToast('查无此人或该用户不在本群');
          return;
        }
      } catch (e) {
        IMViews.showToast('群成员校验失败');
        return;
      }

      machineUsers.add(uid.trim());
    }
  }

  void removeMachineUser(String uid) {
    machineUsers.remove(uid);
  }

  @override
  void onClose() {
    grabDelayCtrl.dispose();
    sendIntervalCtrl.dispose();
    sendMinePoolCtrl.dispose();
    super.onClose();
  }
}

// 通用输入底部弹窗
class _RobotInputSheet extends StatefulWidget {
  final String hint;
  const _RobotInputSheet({this.hint = '输入 UserID'});

  @override
  _RobotInputSheetState createState() => _RobotInputSheetState();
}

class _RobotInputSheetState extends State<_RobotInputSheet> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('添加机器号', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0C1C33))),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.text, // 机器号可能是文本
            decoration: InputDecoration(
              hintText: widget.hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(result: _ctrl.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0089FF)),
              child: const Text('确认添加', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
