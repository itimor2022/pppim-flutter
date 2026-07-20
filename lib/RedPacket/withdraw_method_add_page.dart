import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../core/controller/im_controller.dart';
import 'Widgets/CompatibilityWidgets.dart';

class WithdrawMethodAddPage extends StatefulWidget {
  const WithdrawMethodAddPage({super.key});

  @override
  State<WithdrawMethodAddPage> createState() => _WithdrawMethodAddPageState();
}

class _WithdrawMethodAddPageState extends State<WithdrawMethodAddPage> {
  final imLogic = Get.find<IMController>();
  final _accountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _type = WithdrawMethodType.alipay.obs;
  final _submitting = false.obs;
  WithdrawMethod? _editingMethod;
  bool get _isEditing => _editingMethod != null;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is WithdrawMethod) {
      _editingMethod = arg;
      _type.value = arg.type;
      _accountCtrl.text = arg.account;
      _nameCtrl.text = arg.name;
      _bankNameCtrl.text = arg.bankName ?? "";
    }
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nameCtrl.dispose();
    _bankNameCtrl.dispose();
    _type.close();
    _submitting.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return cancelFocusEvent(
      context: context,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F1E8),
        appBar: AppBarNewWidget(title: _isEditing ? "编辑提现方式" : "添加提现方式"),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
          children: [
            _buildFormCard(),
            24.verticalSpace,
            Obx(
              () => Button(
                text: _submitting.value ? "保存中..." : "保存",
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
                onTap: _submit,
              ),
            ),
            if (_isEditing) ...[
              16.verticalSpace,
              GestureDetector(
                onTap: _delete,
                child: Container(
                  height: 46.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23.r),
                  ),
                  child: Text(
                    "删除该提现方式",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFFE24C4C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
          _buildLabel("提现方式类型"),
          14.verticalSpace,
          Obx(
            () => Row(
              children: [
                Expanded(child: _buildTypeOption(WithdrawMethodType.alipay)),
                12.horizontalSpace,
                Expanded(child: _buildTypeOption(WithdrawMethodType.bankCard)),
              ],
            ),
          ),
          20.verticalSpace,
          _buildLabel("真实姓名"),
          10.verticalSpace,
          _buildTextField(
            controller: _nameCtrl,
            hintText: "请输入收款人真实姓名",
          ),
          20.verticalSpace,
          Obx(
            () => _buildLabel(
              _type.value == WithdrawMethodType.alipay ? "支付宝账号" : "银行卡号",
            ),
          ),
          10.verticalSpace,
          Obx(
            () => _buildTextField(
              controller: _accountCtrl,
              hintText: _type.value == WithdrawMethodType.alipay
                  ? "请输入支付宝账号"
                  : "请输入银行卡号",
              keyboardType: _type.value == WithdrawMethodType.bankCard
                  ? TextInputType.number
                  : TextInputType.text,
            ),
          ),
          Obx(
            () => _type.value == WithdrawMethodType.bankCard
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.verticalSpace,
                      _buildLabel("开户银行"),
                      10.verticalSpace,
                      _buildTextField(
                        controller: _bankNameCtrl,
                        hintText: "请输入开户银行名称，如中国银行",
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 15.sp,
          color: const Color(0xFF202633),
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _buildTypeOption(WithdrawMethodType type) {
    final selected = _type.value == type;
    return GestureDetector(
      onTap: () => _type.value = type,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0E4) : const Color(0xFFF8F3EC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? const Color(0xFFE56B3E) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFFE56B3E) : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F3EC),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xff999999)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final account = _accountCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final bankName = _bankNameCtrl.text.trim();
    if (name.isEmpty) {
      IMViews.showToast("请输入真实姓名");
      return;
    }
    if (account.isEmpty) {
      IMViews.showToast(
        _type.value == WithdrawMethodType.alipay
            ? "请输入支付宝账号"
            : "请输入银行卡号",
      );
      return;
    }
    if (_type.value == WithdrawMethodType.bankCard && bankName.isEmpty) {
      IMViews.showToast("请输入开户银行名称");
      return;
    }
    final method = WithdrawMethod(
      id: _editingMethod?.id ?? WithdrawMethodUtil.generateId(),
      type: _type.value,
      account: account,
      name: name,
      bankName: _type.value == WithdrawMethodType.bankCard ? bankName : null,
    );
    _submitting.value = true;
    try {
      final currentEx = imLogic.userInfo.value.ex;
      final newEx = WithdrawMethodUtil.upsert(currentEx, method);
      await OpenIM.iMManager.userManager.setSelfInfo(
        ex: newEx,
      );
      imLogic.userInfo.update((val) {
        val?.ex = newEx;
      });
      IMViews.showToast(_isEditing ? "已保存修改" : "添加成功");
      Get.back(result: true);
    } catch (e) {
      IMViews.showToast("保存失败: " + e.toString());
    } finally {
      _submitting.value = false;
    }
  }

  Future<void> _delete() async {
    final method = _editingMethod;
    if (method == null) return;
    Get.defaultDialog(
      title: "提示",
      middleText: "确定删除这条提现方式吗？",
      textConfirm: "删除",
      textCancel: "取消",
      onConfirm: () async {
        Get.back();
        _submitting.value = true;
        try {
          final currentEx = imLogic.userInfo.value.ex;
          final newEx = WithdrawMethodUtil.remove(currentEx, method.id);
          await OpenIM.iMManager.userManager.setSelfInfo(
            ex: newEx,
          );
          imLogic.userInfo.update((val) {
            val?.ex = newEx;
          });
          IMViews.showToast("已删除");
          Get.back(result: true);
        } catch (e) {
          IMViews.showToast("删除失败: " + e.toString());
        } finally {
          _submitting.value = false;
        }
      },
    );
  }
}
