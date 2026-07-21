import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pinput/pinput.dart';

import '../core/controller/im_controller.dart';
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
  final imLogic = Get.find<IMController>();
  final _amountCtrl = TextEditingController();
  final _submitting = false.obs;
  final _balance = '0.00'.obs;
  final RxList<WithdrawMethod> _methods = <WithdrawMethod>[].obs;
  final Rx<WithdrawMethod?> _selectedMethod = Rx<WithdrawMethod?>(null);

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadMethods();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _submitting.close();
    _balance.close();
    _methods.close();
    _selectedMethod.close();
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
            '提现方式',
            style: TextStyle(
              fontSize: 17.sp,
              color: const Color(0xFF202633),
              fontWeight: FontWeight.w700,
            ),
          ),
          14.verticalSpace,
          Obx(
            () {
              if (_methods.isEmpty) {
                return GestureDetector(
                  onTap: _goAddMethod,
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F3EC),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 18.sp, color: const Color(0xFFE56B3E)),
                        6.horizontalSpace,
                        Text(
                          '暂无提现方式，点击添加',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFFE56B3E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final method = _selectedMethod.value;
              return GestureDetector(
                onTap: _showMethodPicker,
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3EC),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          method?.displayText ?? '请选择提现方式',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF1B1A17),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right,
                          size: 20.sp, color: const Color(0xFF999999)),
                    ],
                  ),
                ),
              );
            },
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

  void _loadMethods() {
    final ex = imLogic.userInfo.value.ex;
    final list = WithdrawMethodUtil.list(ex);
    _methods.assignAll(list);
    if (list.isNotEmpty) {
      _selectedMethod.value = list.first;
    }
  }

  Future<void> _goAddMethod() async {
    final result = await Get.toNamed(AppRoutes.withdrawMethodAdd);
    if (result == true) {
      _loadMethods();
    }
  }

  void _showMethodPicker() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            16.verticalSpace,
            Text(
              '选择提现方式',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF202633),
              ),
            ),
            12.verticalSpace,
            ..._methods.map(
              (m) => ListTile(
                title: Text(m.displayText),
                trailing: _selectedMethod.value?.id == m.id
                    ? const Icon(Icons.check, color: Color(0xFFE56B3E))
                    : null,
                onTap: () {
                  _selectedMethod.value = m;
                  Get.back();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: Color(0xFFE56B3E)),
              title: const Text(
                '添加新的提现方式',
                style: TextStyle(color: Color(0xFFE56B3E)),
              ),
              onTap: () {
                Get.back();
                _goAddMethod();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitWithdraw() async {
    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 100) {
      IMViews.showToast('请输入正确金额，最低提现金额为100元');
      return;
    }
    if (_methods.isEmpty) {
      IMViews.showToast('请先添加提现方式');
      _goAddMethod();
      return;
    }
    if (_selectedMethod.value == null) {
      IMViews.showToast('请选择提现方式');
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
    final remark = _selectedMethod.value?.toSubmitPayload() ?? '用户提现';
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
