import 'package:get/get.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'Api/RedPacketApi.dart';

class WalletBalanceController extends GetxController {
  final balance = '0.000'.obs;

  @override
  void onInit() {
    super.onInit();
    refreshBalance();
  }

  Future<void> refreshBalance() async {
    try {
      final userID = OpenIM.iMManager.userID;
      final result = await RedPacketApi.getWalletBalance(userID: userID);
      if (result['balance'] != null) {
        final amountInFen = double.tryParse(result['balance'].toString()) ?? 0;
        balance.value = (amountInFen / 100).toStringAsFixed(2);
      }
    } catch (e) {
      //
    }
  }
}
