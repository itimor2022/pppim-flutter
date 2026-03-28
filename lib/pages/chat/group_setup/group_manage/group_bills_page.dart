import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class GroupBillsLogic extends GetxController {
  final String groupID;
  GroupBillsLogic({required this.groupID});

  var bills = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  int page = 1;
  int total = 0;

  @override
  void onReady() {
    super.onReady();
    loadData();
  }

  void loadData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final res =
          await Apis.getGroupBills(groupID: groupID, page: page, limit: 20);
      if (res != null) {
        total = res['total'] ?? 0;
        final list = List<Map<String, dynamic>>.from(res['list'] ?? []);
        if (page == 1) {
          bills.assignAll(list);
        } else {
          bills.addAll(list);
        }
        page++;
      }
    } catch (e) {
      Logger.print('load bills error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class GroupBillsPage extends StatelessWidget {
  final String groupID;

  const GroupBillsPage({Key? key, required this.groupID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(GroupBillsLogic(groupID: groupID));
    return Scaffold(
      appBar: TitleBar.back(title: '本群扫雷账单'),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.bills.isEmpty && logic.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (logic.bills.isEmpty) {
          return const Center(child: Text('暂无历史红包'));
        }
        return ListView.builder(
          itemCount: logic.bills.length,
          itemBuilder: (_, index) {
            final item = logic.bills[index];
            final state = item['status'] == 1 ? "进行中" : "已结束";
            final totalAmt =
                ((item['total_amount'] ?? 0) / 100).toStringAsFixed(2);
            final grabbedAmt =
                ((item['grabbed_amount'] ?? 0) / 100).toStringAsFixed(2);
            final mineNums = item['mine_nums'] ?? '';
            final time = item['create_time'];
            String timeStr = "";
            DateTime? dt;
            if (time is String) {
              dt = DateTime.tryParse(time);
            } else if (time is int && time > 0) {
              dt = DateTime.fromMillisecondsSinceEpoch(time * 1000);
            }

            if (dt != null) {
              timeStr =
                  "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }

            final grabbedCount = item['grabbed_count'] ?? 0;
            final totalCount =
                item['total_count'] ?? 12; // Fallback to 12 if not provided
            final hitCount = item['hit_count'] ?? 0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('单包额: $totalAmt元',
                          style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(state,
                          style: TextStyle(
                              color:
                                  state == '进行中' ? Colors.green : Colors.grey,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('雷号: $mineNums',
                          style: TextStyle(
                              color: Color(0xFF666666), fontSize: 14)),
                      Text('进度: $grabbedCount/$totalCount 包',
                          style: TextStyle(
                              color: Color(0xFF666666), fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('已从包内领取: $grabbedAmt元',
                          style: TextStyle(
                              color: Color(0xFF999999), fontSize: 13)),
                      Text('中雷: $hitCount 次',
                          style: TextStyle(
                              color:
                                  hitCount > 0 ? Colors.red : Color(0xFF999999),
                              fontSize: 13,
                              fontWeight: hitCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('发布时间: $timeStr',
                      style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
