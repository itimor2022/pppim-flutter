import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Api/RedPacketApi.dart';
import 'Widgets/CompatibilityWidgets.dart';

class WalletRecordController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final incomeList = <dynamic>[].obs;
  final expenseList = <dynamic>[].obs;
  final incomeRefreshController = RefreshController();
  final expenseRefreshController = RefreshController();
  int incomePage = 1;
  int expensePage = 1;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    onIncomeRefresh();
    onExpenseRefresh();
    super.onInit();
  }

  @override
  void onClose() {
    tabController.dispose();
    incomeRefreshController.dispose();
    expenseRefreshController.dispose();
    super.onClose();
  }

  void onIncomeRefresh() async {
    incomePage = 1;
    final list = await _fetchRecords(1, incomePage);
    incomeList.assignAll(list);
    incomeRefreshController.refreshCompleted();
    if (list.length < 20) {
      incomeRefreshController.loadNoData();
    } else {
      incomeRefreshController.resetNoData();
    }
  }

  void onIncomeLoadMore() async {
    incomePage++;
    final list = await _fetchRecords(1, incomePage);
    if (list.isEmpty) {
      incomeRefreshController.loadNoData();
    } else {
      incomeList.addAll(list);
      incomeRefreshController.loadComplete();
    }
  }

  void onExpenseRefresh() async {
    expensePage = 1;
    final list = await _fetchRecords(2, expensePage);
    expenseList.assignAll(list);
    expenseRefreshController.refreshCompleted();
    if (list.length < 20) {
      expenseRefreshController.loadNoData();
    } else {
      expenseRefreshController.resetNoData();
    }
  }

  void onExpenseLoadMore() async {
    expensePage++;
    final list = await _fetchRecords(2, expensePage);
    if (list.isEmpty) {
      expenseRefreshController.loadNoData();
    } else {
      expenseList.addAll(list);
      expenseRefreshController.loadComplete();
    }
  }

  Future<List<dynamic>> _fetchRecords(int type, int page) async {
    try {
      final res = await RedPacketApi.getWalletRecords(
        page: page,
        limit: 20,
        type: type,
      );
      return res['list'] ?? [];
    } catch (e) {
      return [];
    }
  }
}

class WalletRecordPage extends StatelessWidget {
  final logic = Get.put(WalletRecordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarNewWidget(title: '钱包明细'), // Uses common AppBar
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: logic.tabController,
              labelColor: Color(0xffE84D3D),
              unselectedLabelColor: Color(0xff333333),
              indicatorColor: Color(0xffE84D3D),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "收入"),
                Tab(text: "支出"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: logic.tabController,
              children: [
                _buildList(logic.incomeList, logic.incomeRefreshController,
                    logic.onIncomeRefresh, logic.onIncomeLoadMore, true),
                _buildList(logic.expenseList, logic.expenseRefreshController,
                    logic.onExpenseRefresh, logic.onExpenseLoadMore, false),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildList(RxList<dynamic> list, RefreshController controller,
      VoidCallback onRefresh, VoidCallback onLoadMore, bool isIncome) {
    return Obx(() => SmartRefresher(
          controller: controller,
          onRefresh: onRefresh,
          onLoading: onLoadMore,
          enablePullUp: true,
          header: IMViews.buildHeader(),
          footer: IMViews.buildFooter(),
          child: list.isEmpty
              ? _buildEmptyView()
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildItem(item, isIncome);
                  },
                ),
        ));
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Build empty view or use common one
          Icon(Icons.list_alt, size: 50.sp, color: Colors.grey[300]),
          SizedBox(height: 10.h),
          Text("暂无记录", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildItem(dynamic item, bool isIncome) {
    // item: type, amount, title, create_time, status
    String title = item['title'] ?? (isIncome ? "收到红包" : "发出红包");
    String amount = item['amount'] ?? "0";
    String time = item['create_time'] ?? "";
    // Convert Fen to Yuan (Fen unit: /100)
    double amountVal = (double.tryParse(amount) ?? 0) / 100;
    String amountStr = "${isIncome ? '+' : '-'}${amountVal.toStringAsFixed(2)}";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xffEBEBEB), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16.sp,
                      color: Color(0xff333333),
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 5.h),
              Text(time,
                  style: TextStyle(fontSize: 12.sp, color: Color(0xff999999))),
            ],
          ),
          Text(amountStr,
              style: TextStyle(
                  fontSize: 18.sp,
                  color: isIncome ? Color(0xffE84D3D) : Color(0xff333333),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
