import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pinput/pinput.dart';

import '../routes/app_pages.dart';
import 'Api/RedPacketApi.dart';
import 'WalletBalanceController.dart';
import 'Widgets/CompatibilityWidgets.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController(text: '');
  final _submitting = false.obs;
  final _balance = '0.00'.obs;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    _submitting.close();
    _balance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return cancelFocusEvent(
      context: context,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F1E8),
        appBar: const AppBarNewWidget(title: '提现'),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
          children: [
            _buildBalanceCard(),
            16.verticalSpace,
            _buildFormCard(),
            24.verticalSpace,
            Obx(
              () => Button(
                text: _submitting.value ? '提交中...' : '提交提现申请',
                height: 46.h,
                enabled: !_submitting.value,
                enabledColor: Colors.white,
                disabledColor: Colors.white.withOpacity(0.45),
                textStyle: TextStyle(
                  color: _submitting.value
                      ? const Color(0xFFB85E3C)
                      : const Color(0xFFE56B3E),
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
                onTap: _submitWithdraw,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC978), Color(0xFFFF8C5D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26E08A4F),
            blurRadius: 30.r,
            offset: Offset(0, 16.h),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前余额',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            10.verticalSpace,
            Text(
              '¥${_balance.value}',
              style: TextStyle(
                fontSize: 34.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '提现金额',
            style: TextStyle(
              fontSize: 17.sp,
              color: const Color(0xFF202633),
              fontWeight: FontWeight.w700,
            ),
          ),
          14.verticalSpace,
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EE),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE26B3D),
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1A17),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC6C3BC),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          18.verticalSpace,
          Text(
            'UID',
            style: TextStyle(
              fontSize: 17.sp,
              color: const Color(0xFF202633),
              fontWeight: FontWeight.w700,
            ),
          ),
          14.verticalSpace,
          TextField(
            controller: _remarkCtrl,
            maxLength: 30,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F3EC),
              hintText: '请输入 UID',
              hintStyle: TextStyle(color: Color(0xff999999)),
              counterText: '',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBalance() async {
    try {
      final result =
          await RedPacketApi.getWalletBalance(userID: OpenIM.iMManager.userID);
      final amountInFen = double.tryParse(result['balance'].toString()) ?? 0;
      _balance.value = (amountInFen / 100).toStringAsFixed(2);
    } catch (_) {}
  }

  Future<void> _submitWithdraw() async {
    final amountText = _amountCtrl.text.trim();
    final remarkText = _remarkCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 0.01) {
      IMViews.showToast('请输入正确金额');
      return;
    }
    if (remarkText.isEmpty) {
      IMViews.showToast('请输入UID');
      return;
    }
    _showPayDialog(amount);
  }

  void _showPayDialog(double totalAmount) {
    Get.defaultDialog(
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0),
      contentPadding:
          EdgeInsets.only(left: 15.w, right: 15.w, bottom: 25.w, top: 25.w),
      radius: 10,
      backgroundColor: Colors.white,
      content: SizedBox(
        width: 291.w,
        child: Column(
          children: [
            '确认提现'.toText
              ..style = TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff161616),
              ),
            24.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultText(
                  text: totalAmount.toStringAsFixed(2),
                  textColor: const Color(0xff161616),
                  fontWeight: FontWeight.bold,
                  fontSize: 38.sp,
                ),
                Container(
                  margin: EdgeInsets.only(left: 4.w, top: 14.w),
                  child: DefaultText(
                    text: "元",
                    textColor: const Color(0xff161616),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            18.verticalSpace,
            Pinput(
              autofocus: true,
              length: 6,
              obscureText: true,
              onCompleted: (pin) async => _doWithdraw(totalAmount, pin),
              defaultPinTheme: PinTheme(
                width: 43.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: const Color(0xffE7E7E7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: TextStyle(
                  color: const Color(0xff3D3D3D),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doWithdraw(double totalAmount, String pin) async {
    final amountInFen = (totalAmount * 100).round().toString();
    final remark =
        _remarkCtrl.text.trim().isEmpty ? '用户提现' : _remarkCtrl.text.trim();
    try {
      _submitting.value = true;
      await RedPacketApi.applyWithdraw(
        amount: amountInFen,
        password: pin,
        remark: remark,
      );
      await _refreshWalletBalance();
      Get.back();
      IMViews.showToast('提现申请已提交');
      Get.back(result: true);
    } catch (e) {
      Get.back();
      final errorStr = e.toString();
      if (errorStr.contains('20015') || errorStr.contains('密码未设置')) {
        Get.defaultDialog(
          title: "提示",
          middleText: "支付密码未设置，是否前往设置？",
          textConfirm: "去设置",
          textCancel: "取消",
          onConfirm: () {
            Get.back();
            Get.toNamed(AppRoutes.setPayPassword);
          },
        );
        return;
      }
      if (errorStr.contains('20016') || errorStr.contains('密码错误')) {
        IMViews.showToast("支付密码错误");
        return;
      }
      if (errorStr.contains('20017') || errorStr.contains('余额不足')) {
        IMViews.showToast("余额不足");
        return;
      }
      IMViews.showToast(errorStr);
    } finally {
      _submitting.value = false;
    }
  }

  Future<void> _refreshWalletBalance() async {
    await _loadBalance();
    if (Get.isRegistered<WalletBalanceController>()) {
      await Get.find<WalletBalanceController>().refreshBalance();
    }
  }
}
