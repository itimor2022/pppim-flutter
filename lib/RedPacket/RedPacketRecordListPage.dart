import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Api/RedPacketApi.dart';

class RedPacketRecordListController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final year = DateTime.now().year.obs;
  int tempYear = DateTime.now().year; // For picker

  // Separated variables
  final receivedTotalAmount = "0.00".obs;
  final receivedTotalCount = 0.obs;
  final sentTotalAmount = "0.00".obs;
  final sentTotalCount = 0.obs;

  late TabController tabController;
  final receivedList = <dynamic>[].obs;
  final sentList = <dynamic>[].obs;
  final receivedRefreshController = RefreshController();
  final sentRefreshController = RefreshController();
  int receivedPage = 1;
  int sentPage = 1;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      update(); // Update UI when tab changes
    });
    onReceivedRefresh();
    onSentRefresh();
    super.onInit();
  }

  void onYearChanged(int newYear) {
    year.value = newYear;
    onReceivedRefresh();
    onSentRefresh();
  }

  void onReceivedRefresh() async {
    receivedPage = 1;
    final res = await _fetchReceived(receivedPage);
    if (res.isEmpty) {
      receivedRefreshController.refreshFailed();
      return;
    }
    final list = res['list'] ?? [];

    // Process Total Count
    if (res['total_count'] != null) {
      receivedTotalCount.value = res['total_count'] is int
          ? res['total_count']
          : int.tryParse(res['total_count'].toString()) ?? 0;
    }

    // Process Total Amount
    if (res['total_amount'] != null) {
      receivedTotalAmount.value =
          (double.parse(res['total_amount'].toString()) / 100)
              .toStringAsFixed(2);
    }

    receivedList.assignAll(list);
    receivedRefreshController.refreshCompleted();
    if (list.length < 20)
      receivedRefreshController.loadNoData();
    else
      receivedRefreshController.resetNoData();

    update();
  }

  void onReceivedLoadMore() async {
    receivedPage++;
    final res = await _fetchReceived(receivedPage);
    if (res.isEmpty) {
      receivedPage--;
      receivedRefreshController.loadFailed();
      return;
    }
    final list = res['list'] ?? [];
    if (list.isEmpty) {
      receivedRefreshController.loadNoData();
    } else {
      receivedList.addAll(list);

      // Update totals if provided in next pages
      if (res['total_amount'] != null) {
        receivedTotalAmount.value =
            (double.parse(res['total_amount'].toString()) / 100)
                .toStringAsFixed(2);
      }
      receivedRefreshController.loadComplete();
    }
    update();
  }

  void onSentRefresh() async {
    sentPage = 1;
    final res = await _fetchSent(sentPage);
    if (res.isEmpty) {
      sentRefreshController.refreshFailed();
      return;
    }
    final list = res['list'] ?? [];

    if (res['total_amount'] != null) {
      sentTotalAmount.value =
          (double.parse(res['total_amount'].toString()) / 100)
              .toStringAsFixed(2);
    }
    if (res['total_count'] != null) {
      sentTotalCount.value = res['total_count'] is int
          ? res['total_count']
          : int.tryParse(res['total_count'].toString()) ?? 0;
    }

    sentList.assignAll(list);
    sentRefreshController.refreshCompleted();
    if (list.length < 20)
      sentRefreshController.loadNoData();
    else
      sentRefreshController.resetNoData();

    update();
  }

  void onSentLoadMore() async {
    sentPage++;
    final res = await _fetchSent(sentPage);
    if (res.isEmpty) {
      sentPage--;
      sentRefreshController.loadFailed();
      return;
    }
    final list = res['list'] ?? [];
    if (list.isEmpty) {
      sentRefreshController.loadNoData();
    } else {
      sentList.addAll(list);

      if (res['total_amount'] != null) {
        sentTotalAmount.value =
            (double.parse(res['total_amount'].toString()) / 100)
                .toStringAsFixed(2);
      }
      sentRefreshController.loadComplete();
    }
    update();
  }

  Future<Map<String, dynamic>> _fetchReceived(int page) async {
    try {
      final res = await RedPacketApi.getRecvRedPacketList(
          page: page, limit: 20, year: year.value);
      return res; // api returns map
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchSent(int page) async {
    try {
      final res = await RedPacketApi.getSendRedPacketList(
          page: page, limit: 20, year: year.value);
      return res;
    } catch (e) {
      return {};
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    receivedRefreshController.dispose();
    sentRefreshController.dispose();
    super.onClose();
  }
}

class RedPacketRecordListPage extends StatelessWidget {
  final logic = Get.put(RedPacketRecordListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: Stack(
        children: [
          Column(
            children: [
              // Custom Header
              Container(
                width: double.infinity,
                height: 220.h,
                decoration: BoxDecoration(
                  color: const Color(0xffE84D3D), // Red Packet Red
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50.r), // Curved bottom
                    bottomRight: Radius.circular(50.r),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // AppBar Content
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Icon(Icons.arrow_back_ios,
                                  color: Colors.white, size: 20.sp),
                            ),
                            Text("红包记录",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold)),
                            GestureDetector(
                                onTap: _showDatePicker,
                                child: Obx(() => Text("${logic.year.value}年",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp)))),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // TabBar
                      Container(
                          width: 200.w,
                          child: TabBar(
                            controller: logic.tabController,
                            indicatorColor: Colors.white,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors
                                .transparent, // Remove underlining divider
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            labelStyle: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold),
                            tabs: [
                              Tab(text: "我收到的"),
                              Tab(text: "我发出的"),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
              // Spacer/Content
              SizedBox(height: 135.w),
              Expanded(
                child: TabBarView(
                  controller: logic.tabController,
                  children: [
                    _buildReceivedList(),
                    _buildSentList(),
                  ],
                ),
              )
            ],
          ),
          // Floating Info Box
          Positioned(
            top: 120.w,
            left: 20.w,
            right: 20.w,
            child: Container(
              height: 220.h,
              decoration: BoxDecoration(
                color: Colors.white, // White Card
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    margin:
                        EdgeInsets.only(top: 0), // Adjust overlapping if needed
                    child: AvatarView(
                      url: OpenIM.iMManager.userInfo.faceURL ?? "",
                      text: OpenIM.iMManager.userInfo.nickname,
                      width: 50.w,
                      height: 50.w,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  GetBuilder<RedPacketRecordListController>(builder: (logic) {
                    final isReceived = logic.tabController.index == 0;
                    return Text(
                      "${OpenIM.iMManager.userInfo.nickname}共${isReceived ? "收到" : "发出"}",
                      style:
                          TextStyle(color: Color(0xff666666), fontSize: 13.sp),
                    );
                  }),
                  SizedBox(height: 5.h),
                  GetBuilder<RedPacketRecordListController>(builder: (logic) {
                    final isReceived = logic.tabController.index == 0;
                    final amount = isReceived
                        ? logic.receivedTotalAmount.value
                        : logic.sentTotalAmount.value;
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: "$amount",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: " 元",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 5.h),
                  GetBuilder<RedPacketRecordListController>(builder: (logic) {
                    final isReceived = logic.tabController.index == 0;
                    final count = isReceived
                        ? logic.receivedTotalCount.value
                        : logic.sentTotalCount.value;
                    return Text(
                      "共${isReceived ? "收到" : "发出"} $count 个红包",
                      style:
                          TextStyle(color: Color(0xff999999), fontSize: 13.sp),
                    );
                  }),
                  // Count summary if possible
                  // Obx(() => Text("发出红包总数 ${count}个", style: ...)) // API might need to return count
                ],
              ),
            ),
          ),
          // User Avatar Overlay on top border of card? No, inside card.
          // User Image shows avatar floating half out?
          // To do that, need Stack inside Stack or adjust top margin.
          // Let's stick to simple card layout first for robustness.
        ],
      ),
    );
  }

  void _showDatePicker() {
    Get.bottomSheet(
      Container(
        height: 250.h,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text("取消", style: TextStyle(fontSize: 16.sp)),
                  ),
                  Text("选择年份",
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    child: Text("确定",
                        style: TextStyle(
                            fontSize: 16.sp, color: Color(0xffE44545))),
                    onTap: () {
                      logic.onYearChanged(logic.tempYear);
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // 10 years
                itemExtent: 50.h,
                itemBuilder: (context, index) {
                  final y = DateTime.now().year - index;
                  return GestureDetector(
                    onTap: () {
                      logic.tempYear = y;
                      logic.onYearChanged(
                          y); // Immediate update or wait confirm? Logic above suggests confirm. Fixing logic.
                      // Actually better to use CupertinoPicker or simple list.
                      // For simplicity, let's just trigger refresh on tap and close? Or use state.
                      Get.back();
                    },
                    child: Center(
                        child: Text("$y年", style: TextStyle(fontSize: 18.sp))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedList() {
    return Obx(() => SmartRefresher(
          controller: logic.receivedRefreshController,
          onRefresh: logic.onReceivedRefresh,
          onLoading: logic.onReceivedLoadMore,
          enablePullUp: true,
          header: IMViews.buildHeader(),
          footer: IMViews.buildFooter(),
          child: ListView.builder(
            itemCount: logic.receivedList.length,
            itemBuilder: (context, index) {
              final item = logic.receivedList[index];
              return _buildItem(
                  isReceived: true,
                  title:
                      "来自 ${item['sender_nickname'] ?? item['nickname'] ?? item['sender_id']}", // Should fetch nickname asynchronously or cache?
                  subtitle: item['create_time'],
                  amount:
                      "${(double.parse(item['amount'] ?? '0') / 100).toStringAsFixed(2)} 元", // Assuming Fen unit
                  type: item['type']);
            },
          ),
        ));
  }

  Widget _buildSentList() {
    return Obx(() => SmartRefresher(
          controller: logic.sentRefreshController,
          onRefresh: logic.onSentRefresh,
          onLoading: logic.onSentLoadMore,
          enablePullUp: true,
          header: IMViews.buildHeader(),
          footer: IMViews.buildFooter(),
          child: ListView.builder(
            itemCount: logic.sentList.length,
            itemBuilder: (context, index) {
              final item = logic.sentList[index];
              // item has type, amount, count...
              final claimed =
                  (item['count'] ?? 0) - (item['remain_count'] ?? 0);
              final total = item['count'] ?? 0;
              final status = item['status'];
              String statusStr =
                  "${claimed != 0 ? "已领取" : ""} $claimed/$total 个";
              if (status == 3) statusStr += " 已过期";

              return _buildItem(
                  isReceived: false,
                  title: _getTypeStr(item['type']),
                  subtitle: item['create_time'],
                  amount:
                      "${(double.parse(item['amount'] ?? '0') / 100).toStringAsFixed(2)} 元",
                  statusStr: statusStr // Custom status string
                  );
            },
          ),
        ));
  }

  String _getTypeStr(int? type) {
    if (type == 1) return "普通红包";
    if (type == 2) return "拼手气红包";
    if (type == 3) return "专属红包";
    return "红包";
  }

  Widget _buildItem({
    required bool isReceived,
    required String title,
    required String subtitle,
    required String amount,
    int? type,
    int? status,
    String? statusStr,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      margin: EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Color(0xff333333),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 6.h),
              Text(subtitle,
                  style: TextStyle(color: Color(0xff999999), fontSize: 12.sp)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: TextStyle(
                      color: Color(0xffE44545),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 6.h),
              if (statusStr != null)
                Text(statusStr,
                    style: TextStyle(color: Color(0xff999999), fontSize: 12.sp))
              else if (status != null)
                Text(_getStatusStr(status),
                    style: TextStyle(color: Color(0xff999999), fontSize: 12.sp))
              else if (type != null)
                Text(_getTypeStr(type),
                    style: TextStyle(color: Color(0xff999999), fontSize: 12.sp))
            ],
          )
        ],
      ),
    );
  }

  String _getStatusStr(int? status) {
    if (status == 1) return "进行中";
    if (status == 2) return "已领完";
    if (status == 3) return "已过期";
    return "";
  }
}
