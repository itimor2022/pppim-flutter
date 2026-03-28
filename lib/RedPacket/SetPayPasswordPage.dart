import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../routes/app_pages.dart';
import 'Widgets/CompatibilityWidgets.dart';
import 'SetPayPasswordController.dart';

class SetPayPasswordPage extends GetView<SetPayPasswordController> {
  @override
  Widget build(BuildContext context) {
    return cancelFocusEvent(
        context: context,
        child: Scaffold(
            appBar: const AppBarNewWidget(title: '设置支付密码'),
            body: Container(
                color: const Color(0xffF8F8F8),
                padding: EdgeInsets.all(20.w),
                child: Column(children: [
                  Container(
                      margin: EdgeInsets.only(bottom: 10.w),
                      child: DefaultText(
                          text: "如首次设置，旧密码留空即可",
                          textColor: const Color(0xff999999),
                          fontSize: 12.sp)),
                  _buildInputItem(
                    label: "旧密码",
                    controller: controller.oldPasswordController,
                    hint: "请输入旧密码 (首次设置不填)",
                  ),
                  _buildInputItem(
                    label: "新密码",
                    controller: controller.newPasswordController,
                    hint: "请输入6位数字新密码",
                  ),
                  _buildInputItem(
                    label: "确认密码",
                    controller: controller.confirmPasswordController,
                    hint: "请再次输入新密码",
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(top: 10.w),
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.resetPayPassword),
                      child: DefaultText(
                        text: "忘记密码？",
                        textColor: const Color(0xff1B72EC),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 30.w),
                  Defaultbutton(
                    text: "确定",
                    function: controller.setPassword,
                    color: const Color(0xff1B72EC),
                    radius: 8.r,
                  )
                ]))));
  }

  Widget _buildInputItem({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.w),
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: DefaultText(
              text: label,
              fontSize: 14.sp,
              textColor: Colors.black,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: const Color(0xffCCCCCC),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
