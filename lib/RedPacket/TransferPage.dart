import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pinput/pinput.dart';

import '../routes/app_pages.dart';
import 'Api/RedPacketApi.dart';
import 'Widgets/CompatibilityWidgets.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({
    super.key,
    required this.recvUserID,
    required this.recvNickname,
    required this.recvFaceURL,
  });

  final String recvUserID;
  final String recvNickname;
  final String recvFaceURL;

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _amountCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController(text: '转账');
  final _submitting = false.obs;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    _submitting.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return cancelFocusEvent(
      context: context,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F1E8),
        appBar: const AppBarNewWidget(title: '转账'),
        body: Stack(
          children: [
            Positioned(
              top: -30.h,
              right: -10.w,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0x33F6A95F), Color(0x00F6A95F)],
                  ),
                ),
              ),
            ),
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
              children: [
                _buildHeader(),
                18.verticalSpace,
                _buildAmountCard(),
                16.verticalSpace,
                _buildRemarkCard(),
                18.verticalSpace,
                _buildTipsCard(),
                28.verticalSpace,
                Obx(
                  () => Button(
                    text: _submitting.value ? '提交中...' : '确认转账',
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
                    onTap: _submitTransfer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8EC), Color(0xFFF7E2BF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x141F6A52),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Row(
        children: [
          AvatarView(
            url: widget.recvFaceURL,
            text: widget.recvNickname.isEmpty
                ? widget.recvUserID
                : widget.recvNickname,
            width: 52.w,
            height: 52.w,
            borderRadius: BorderRadius.circular(18.r),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (widget.recvNickname.isEmpty
                        ? widget.recvUserID
                        : widget.recvNickname)
                    .toText
                  ..style = TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C2417),
                  ),
                6.verticalSpace,
                '资金实时到账，支付密码沿用钱包设置'.toText
                  ..style = TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF7F6C4A),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          '转账金额'.toText
            ..style = TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF7C7A73),
            ),
          14.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1A17),
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
                    fontWeight: FontWeight.w700,
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
          Divider(height: 26.h, color: const Color(0xFFF0ECE2)),
          '最少转账 0.01 元'.toText
            ..style = TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFFB09256),
            ),
        ],
      ),
    );
  }

  Widget _buildRemarkCard() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          '转账说明'.toText
            ..style = TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF7C7A73),
            ),
          10.verticalSpace,
          TextField(
            controller: _remarkCtrl,
            maxLength: 20,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F4EE),
              hintText: '输入备注',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF0DFC0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: const Color(0xFFB6862A)),
          8.horizontalSpace,
          Expanded(
            child: '转账成功后会在聊天内发送一张转账卡片，便于双方查看金额和备注。'.toText
              ..style = TextStyle(
                fontSize: 12.sp,
                height: 1.5,
                color: const Color(0xFF8A6A2F),
              ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransfer() async {
    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 0.01) {
      IMViews.showToast('请输入正确金额');
      return;
    }
    _showPayDialog(amount);
  }

  void _showPayDialog(double totalAmount) {
    systemInputPopup(
      SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 24.w),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/221.png',
                    width: 28.w,
                    color: Colors.transparent,
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 12.w,
                          width: 159.w,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x00F8F8F8),
                                Color(0xffFFA89E),
                                Color(0x00ffffff),
                              ],
                            ),
                          ),
                        ),
                        DefaultText(
                          text: "确认转账",
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xff161616),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Image.asset('assets/images/221.png', width: 28.w),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultText(
                  text: NumberFormat("#0.00").format(totalAmount),
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
            DefaultContainer(
              color: const Color(0xffF3F3F3),
              borderRadius: 10,
              margin: EdgeInsets.only(top: 16.w, bottom: 18.w),
              padding: EdgeInsets.all(15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: "收款方",
                    textColor: const Color(0xff676767),
                    fontSize: 14.sp,
                  ),
                  Divider(
                    color: const Color(0xffcbcbcb),
                    height: 20.w,
                  ),
                  DefaultText(
                    text: widget.recvNickname.isEmpty
                        ? widget.recvUserID
                        : widget.recvNickname,
                    textColor: const Color(0xff161616),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            Pinput(
              autofocus: true,
              length: 6,
              obscureText: true,
              onCompleted: (pin) async {
                await _doTransfer(totalAmount, pin);
              },
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

  Future<void> _doTransfer(double totalAmount, String pin) async {
    final currentUserID = OpenIM.iMManager.userID;
    final amountInFen = (totalAmount * 100).round().toString();
    final remark =
        _remarkCtrl.text.trim().isEmpty ? '转账' : _remarkCtrl.text.trim();
    try {
      _submitting.value = true;
      final result = await RedPacketApi.transfer(
        userID: currentUserID,
        recvUserID: widget.recvUserID,
        amount: amountInFen,
        password: pin,
        remark: remark,
      );
      final message = await _sendCustomIMMessage(
        amount: amountInFen,
        remark: remark,
        transferID: result['transfer_id']?.toString() ?? '',
      );
      Get.back();
      Get.back(result: message);
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

  Future<Message> _sendCustomIMMessage({
    required String amount,
    required String remark,
    required String transferID,
  }) async {
    final customDataMap = {
      "type": "Transfer",
      "transfer_id": transferID,
      "amount": amount,
      "remark": remark,
      "text": remark,
      "recv_user_id": widget.recvUserID,
      "recv_nickname": widget.recvNickname,
    };
    final message = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: json.encode(customDataMap),
      extension: '',
      description: '[转账]',
    );
    return OpenIM.iMManager.messageManager.sendMessage(
      message: message,
      userID: widget.recvUserID,
      offlinePushInfo: OfflinePushInfo(
        title: "收到转账",
        desc: remark,
        iOSBadgeCount: true,
        iOSPushSound: '',
      ),
    );
  }

  void systemInputPopup(
    Widget content, {
    dynamic Function()? cancel,
    dynamic Function()? confirm,
    bool barrierDismissible = true,
    Future<bool> Function()? onWillPop,
    String cancelText = "取消",
    String confirmText = "确定",
  }) {
    Get.defaultDialog(
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0),
      contentPadding:
          EdgeInsets.only(left: 15.w, right: 15.w, bottom: 25.w, top: 25.w),
      radius: 10,
      barrierDismissible: barrierDismissible,
      onWillPop: onWillPop,
      backgroundColor: Colors.white,
      cancel: Offstage(
        offstage: cancel == null,
        child: DefaultContainer(
          margin: EdgeInsets.only(top: 15.w),
          width: 107.w,
          child: Defaultbutton(
            function: cancel ?? () {},
            text: cancelText,
            color: const Color(0xff939393),
          ),
        ),
      ),
      confirm: Offstage(
        offstage: confirm == null,
        child: DefaultContainer(
          margin: EdgeInsets.only(top: 15.w),
          width: 107.w,
          child: Defaultbutton(
            function: confirm ?? () {},
            text: confirmText,
            color: Colors.black,
          ),
        ),
      ),
      content: DefaultContainer(
        color: Colors.transparent,
        alignment: Alignment.center,
        width: 291.w,
        child: content,
      ),
    );
  }
}
