import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../RedPacket/Api/RedPacketApi.dart';

class SignInLogic extends GetxController {
  final signedDays = <int>[].obs;
  final isTodaySigned = false.obs;
  final rewardAmount = 0.obs;
  final records = <Map<String, dynamic>>[].obs;
  final month = DateTime.now().obs;
  final loading = false.obs;
  final signing = false.obs;

  @override
  void onInit() {
    refreshData();
    super.onInit();
  }

  Future<void> refreshData() async {
    loading.value = true;
    try {
      await Future.wait([
        _queryStatus(),
        _queryCalendar(),
      ]);
    } finally {
      loading.value = false;
    }
  }

  Future<void> _queryStatus() async {
    final data = await RedPacketApi.getSignInStatus();
    isTodaySigned.value = data['signed'] == true;
    rewardAmount.value = _parseAmount(data['rewardAmount']);
  }

  Future<void> _queryCalendar() async {
    final data = await RedPacketApi.getSignInCalendar(
      year: month.value.year,
      month: month.value.month,
    );
    rewardAmount.value = _parseAmount(data['rewardAmount']);
    signedDays.assignAll(
      ((data['signedDays'] as List?) ?? const [])
          .map((e) => int.tryParse('$e') ?? 0)
          .where((e) => e > 0),
    );
    records.assignAll(
      ((data['records'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Future<bool> signIn() async {
    if (signing.value || isTodaySigned.value) return isTodaySigned.value;
    signing.value = true;
    try {
      final data = await RedPacketApi.signIn();
      isTodaySigned.value = true;
      rewardAmount.value = _parseAmount(data['rewardAmount']);
      await _queryCalendar();
      IMViews.showToast(data['alreadySigned'] == true ? '今天已签到' : '签到成功');
      return true;
    } finally {
      signing.value = false;
    }
  }

  int get daysInMonth =>
      DateTime(month.value.year, month.value.month + 1, 0).day;

  int get leadingEmptyCount =>
      DateTime(month.value.year, month.value.month, 1).weekday - 1;

  String get monthLabel =>
      '${month.value.year}年${month.value.month.toString().padLeft(2, '0')}月';

  String get rewardText => _formatFen(rewardAmount.value);

  bool isSignedDay(int day) => signedDays.contains(day);

  bool isToday(int day) {
    final now = DateTime.now();
    return now.year == month.value.year &&
        now.month == month.value.month &&
        now.day == day;
  }

  int _parseAmount(dynamic value) => int.tryParse('$value') ?? 0;

  String _formatFen(int fen) {
    final negative = fen < 0;
    final absFen = fen.abs();
    final yuan = absFen ~/ 100;
    final cent = (absFen % 100).toString().padLeft(2, '0');
    return '${negative ? '-' : ''}$yuan.$cent';
  }
}
