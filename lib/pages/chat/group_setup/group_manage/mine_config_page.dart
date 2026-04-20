import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'mine_reward_config_page.dart';

class MineConfigLogic extends GetxController {
  final String groupID;
  MineConfigLogic({required this.groupID});

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
      final res = await Apis.getGroupMineConfigs(groupID: groupID);
      if (res != null && res is List) {
        configs.assignAll(List<Map<String, dynamic>>.from(res));
      }
      // 初始化 5-9 档位（如果后端无数据）
      if (configs.isEmpty) {
        for (int i = 5; i <= 9; i++) {
          configs.add({
            'packet_count': i,
            'min_amount': 10 * 100, // 10元
            'max_amount': 200 * 100, // 200元
            'single_odds': "1.0",
            'multi_odds': "1.5",
            'multi_count_limit': 3,
            'is_open': 1,
          });
        }
      }
    } catch (e) {
      Logger.print('load configs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void saveConfigs() async {
    try {
      await LoadingView.singleton.wrap(
        asyncFunction: () => Apis.setGroupMineConfigs(
          groupID: groupID,
          configs: configs.toList(),
        ),
      );
      IMViews.showToast('本群配置保存成功!');
      Get.back();
    } catch (e) {
      Logger.print('save error: $e');
      IMViews.showToast('保存失败');
    }
  }

  void updateField(int index, String key, dynamic value) {
    var item = configs[index];
    item[key] = value;
    configs[index] = item; // trigger reaction if needed
  }
}

class MineConfigPage extends StatefulWidget {
  final String groupID;

  const MineConfigPage({Key? key, required this.groupID}) : super(key: key);

  @override
  State<MineConfigPage> createState() => _MineConfigPageState();
}

class _MineConfigPageState extends State<MineConfigPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MineConfigLogic logic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    logic = Get.put(MineConfigLogic(groupID: widget.groupID));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(
        title: '本群扫雷配置',
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
        return Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0089FF),
                unselectedLabelColor: const Color(0xFF666666),
                indicatorColor: const Color(0xFF0089FF),
                tabs: const [
                  Tab(text: '5包'),
                  Tab(text: '6包'),
                  Tab(text: '7包'),
                  Tab(text: '8包'),
                  Tab(text: '9包'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (int i = 5; i <= 9; i++)
                    _buildConfigView(i),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildConfigView(int packetCount) {
    final index = logic.configs.indexWhere((c) => c['packet_count'] == packetCount);
    if (index == -1) {
      return const Center(child: Text('暂无配置'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MineConfigItemWidget(
        key: ValueKey(packetCount),
        index: index,
        item: logic.configs[index],
        logic: logic,
      ),
    );
  }
}

class MineConfigItemWidget extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final MineConfigLogic logic;
  const MineConfigItemWidget({
    Key? key,
    required this.index,
    required this.item,
    required this.logic,
  }) : super(key: key);

  @override
  State<MineConfigItemWidget> createState() => _MineConfigItemWidgetState();
}

class _MineConfigItemWidgetState extends State<MineConfigItemWidget> {
  late TextEditingController minAmtC;
  late TextEditingController maxAmtC;
  late TextEditingController singleC;
  late TextEditingController multiC;
  late TextEditingController multiLimitC;

  @override
  void initState() {
    super.initState();
    minAmtC = TextEditingController(
        text: ((widget.item['min_amount'] ?? 0) / 100).toInt().toString());
    maxAmtC = TextEditingController(
        text: ((widget.item['max_amount'] ?? 0) / 100).toInt().toString());
    singleC = TextEditingController(text: widget.item['single_odds']);
    multiC = TextEditingController(text: widget.item['multi_odds']);
    multiLimitC = TextEditingController(
        text: widget.item['multi_count_limit'].toString());
  }

  @override
  void dispose() {
    minAmtC.dispose();
    maxAmtC.dispose();
    singleC.dispose();
    multiC.dispose();
    multiLimitC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.item['packet_count'] ?? 5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$count 包配置',
                  style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              CupertinoSwitch(
                value: widget.item['is_open'] == 1 ||
                    widget.item['is_open'] == true ||
                    widget.item['is_open'] == null,
                activeColor: const Color(0xFF0089FF),
                onChanged: (v) => widget.logic
                    .updateField(widget.index, 'is_open', v ? 1 : 0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('最小金额(元): ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
              Expanded(
                  child: TextField(
                controller: minAmtC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4)),
                onChanged: (v) => widget.logic.updateField(
                    widget.index, 'min_amount', (int.tryParse(v) ?? 0) * 100),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('最大金额(元): ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
              Expanded(
                  child: TextField(
                controller: maxAmtC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4)),
                onChanged: (v) => widget.logic.updateField(
                    widget.index, 'max_amount', (int.tryParse(v) ?? 0) * 100),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('单雷赔率: ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
              Expanded(
                  child: TextField(
                controller: singleC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4)),
                onChanged: (v) =>
                    widget.logic.updateField(widget.index, 'single_odds', v),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('多雷赔率: ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
              Expanded(
                  child: TextField(
                controller: multiC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4)),
                onChanged: (v) =>
                    widget.logic.updateField(widget.index, 'multi_odds', v),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('多雷上限(个): ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
              Expanded(
                  child: TextField(
                controller: multiLimitC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4)),
                onChanged: (v) => widget.logic.updateField(
                    widget.index, 'multi_count_limit', int.tryParse(v) ?? 3),
              )),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          TextButton.icon(
            onPressed: () => Get.to(() => MineRewardConfigPage(
              groupID: widget.logic.groupID,
              packetCount: count,
            )),
            icon: const Icon(Icons.card_giftcard, size: 18),
            label: const Text('配置多雷奖励'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0089FF),
            ),
          ),
        ],
      ),
    );
  }
}
