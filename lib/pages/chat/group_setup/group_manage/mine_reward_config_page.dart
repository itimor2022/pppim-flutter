import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class MineRewardConfigLogic extends GetxController {
  final String groupID;
  final int packetCount;
  
  MineRewardConfigLogic({required this.groupID, required this.packetCount});

  var configs = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadData();
  }

  void loadData() async {
    isLoading.value = true;
    try {
      final res = await Apis.getMineRewardConfigs(
        groupID: groupID,
        packetCount: packetCount,
      );
      if (res != null && res is List) {
        configs.assignAll(List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      Logger.print('load mine reward configs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void saveConfigs() async {
    try {
      await LoadingView.singleton.wrap(
        asyncFunction: () => Apis.setMineRewardConfigs(
          groupID: groupID,
          packetCount: packetCount,
          configs: configs.toList(),
        ),
      );
      IMViews.showToast('奖励配置保存成功!');
      Get.back();
    } catch (e) {
      Logger.print('save error: $e');
      IMViews.showToast('保存失败');
    }
  }

  void updateConfig(String mineType, int minHitCount, String rewardType, String rewardValue) {
    final index = configs.indexWhere(
      (c) => c['mine_type'] == mineType && c['min_hit_count'] == minHitCount,
    );
    
    final newConfig = {
      'mine_type': mineType,
      'min_hit_count': minHitCount,
      'reward_type': rewardType,
      'reward_value': rewardValue,
    };
    
    if (index >= 0) {
      configs[index] = newConfig;
    } else {
      configs.add(newConfig);
    }
  }
}

class MineRewardConfigPage extends StatelessWidget {
  final String groupID;
  final int packetCount;

  const MineRewardConfigPage({
    Key? key,
    required this.groupID,
    required this.packetCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(
      MineRewardConfigLogic(groupID: groupID, packetCount: packetCount),
      tag: '${groupID}_$packetCount',
    );

    return Scaffold(
      appBar: TitleBar.back(
        title: '$packetCount包 多雷奖励配置',
        right: GestureDetector(
          onTap: logic.saveConfigs,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text('保存',
                style: TextStyle(color: Color(0xFF0089FF), fontSize: 16)),
          ),
        ),
      ),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.isLoading.value && logic.configs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '说明: 当中雷人数达到设定值时,由免死号额外奖励发包者',
              style: TextStyle(color: Color(0xFF999999), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildMineTypeSection(logic, '单雷', 'single'),
            const SizedBox(height: 12),
            _buildMineTypeSection(logic, '双雷', 'double'),
            const SizedBox(height: 12),
            _buildMineTypeSection(logic, '三雷', 'triple'),
            const SizedBox(height: 12),
            _buildMineTypeSection(logic, '四雷', 'quad'),
            const SizedBox(height: 12),
            _buildMineTypeSection(logic, '五雷', 'penta'),
          ],
        );
      }),
    );
  }

  Widget _buildMineTypeSection(MineRewardConfigLogic logic, String label, String mineType) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        children: [
          for (int hitCount = 4; hitCount <= 9; hitCount++)
            _buildRewardRow(logic, mineType, hitCount),
        ],
      ),
    );
  }

  Widget _buildRewardRow(MineRewardConfigLogic logic, String mineType, int hitCount) {
    final existing = logic.configs.firstWhere(
      (c) => c['mine_type'] == mineType && c['min_hit_count'] == hitCount,
      orElse: () => <String, dynamic>{},
    );
    
    final rewardTypeCtrl = TextEditingController(text: existing['reward_type'] ?? 'fixed');
    final rewardValueCtrl = TextEditingController(text: existing['reward_value']?.toString() ?? '0');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('中$hitCount人:', style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: TextField(
              controller: rewardValueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '金额(分)或百分比',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) => logic.updateConfig(mineType, hitCount, rewardTypeCtrl.text, v),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: rewardTypeCtrl.text,
            items: const [
              DropdownMenuItem(value: 'fixed', child: Text('固定')),
              DropdownMenuItem(value: 'percent', child: Text('百分比')),
            ],
            onChanged: (v) {
              if (v != null) {
                rewardTypeCtrl.text = v;
                logic.updateConfig(mineType, hitCount, v, rewardValueCtrl.text);
              }
            },
          ),
        ],
      ),
    );
  }
}
