import 'package:get/get.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'Api/RedPacketApi.dart';

class WalletBalanceController extends GetxController {
  final balance = '0.000'.obs;

  @override
  void onInit() {
    super.onInit();
    _getWalletBalance();
  }

  void _getWalletBalance() async {
    try {
      final userID = OpenIM.iMManager.userID;
      final result = await RedPacketApi.getWalletBalance(userID: userID);
      if (result['balance'] != null) {
        // Balance is in Fen (cents), convert to Yuan
        final amountInFen = double.tryParse(result['balance'].toString()) ?? 0;
        balance.value = (amountInFen / 100).toStringAsFixed(2);
      }
    } catch (e) {
      // Handle error (e.g., show toast)
      // print("Failed to get wallet balance: $e");
    }
  }
}
