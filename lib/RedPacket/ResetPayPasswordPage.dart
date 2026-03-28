import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'ResetPayPasswordController.dart';

class ResetPayPasswordPage extends GetView<ResetPayPasswordController> {
  const ResetPayPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(
        title: "重置支付密码",
      ),
      backgroundColor: const Color(0xffF8F8F8),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(22.w),
        child: Column(
          children: [
            _buildMethodSelection(),
            SizedBox(height: 12.h),
            _buildVerifyCodeItem(),
            SizedBox(height: 12.h),
            _buildInputItem(
              label: "新密码",
              controller: controller.newPasswordController,
              hint: "请输入6位数字新密码",
              isPassword: true,
              maxLength: 6,
              isDigit: true,
            ),
            SizedBox(height: 12.h),
            _buildInputItem(
              label: "确认密码",
              controller: controller.confirmPasswordController,
              hint: "请再次输入新密码",
              isPassword: true,
              maxLength: 6,
              isDigit: true,
            ),
            SizedBox(height: 48.h),
            Button(
              text: "确定",
              height: 44.h,
              enabled: true, // simplified
              onTap: controller.submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputItem({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    int? maxLength,
    bool isDigit = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF333333)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: isDigit ? TextInputType.number : TextInputType.text,
              inputFormatters: isDigit
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      if (maxLength != null)
                        LengthLimitingTextInputFormatter(maxLength),
                    ]
                  : null,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 14.sp, color: const Color(0xFF999999)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCodeItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              "验证码",
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF333333)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.verifyCodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "请输入验证码",
                hintStyle:
                    TextStyle(fontSize: 14.sp, color: const Color(0xFF999999)),
                border: InputBorder.none,
              ),
            ),
          ),
          Obx(() => GestureDetector(
                onTap: controller.isCodeSent.value ? null : controller.sendCode,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: controller.isCodeSent.value
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xff1B72EC),
                    ),
                  ),
                  child: Text(
                    controller.isCodeSent.value
                        ? "${controller.timer.value}s"
                        : "获取验证码",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: controller.isCodeSent.value
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xff1B72EC),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Obx(() {
        final phone = controller.userInfo.value.phoneNumber ?? "";
        final email = controller.userInfo.value.email ?? "";
        final hasPhone = phone.isNotEmpty;
        final hasEmail = email.isNotEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (hasPhone)
              InkWell(
                onTap: () => controller.verificationMethod.value = 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Icon(
                        controller.verificationMethod.value == 0
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: controller.verificationMethod.value == 0
                            ? const Color(0xff1B72EC)
                            : const Color(0xFF999999),
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text("手机号验证",
                          style: TextStyle(
                              fontSize: 14.sp, color: const Color(0xFF333333))),
                    ],
                  ),
                ),
              ),
            if (hasEmail)
              InkWell(
                onTap: () => controller.verificationMethod.value = 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Icon(
                        controller.verificationMethod.value == 1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: controller.verificationMethod.value == 1
                            ? const Color(0xff1B72EC)
                            : const Color(0xFF999999),
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text("邮箱验证",
                          style: TextStyle(
                              fontSize: 14.sp, color: const Color(0xFF333333))),
                    ],
                  ),
                ),
              ),
            if (!hasPhone && !hasEmail)
              Text("未绑定手机号或邮箱，无法重置密码", style: TextStyle(color: Colors.red)),
          ],
        );
      }),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length > 7) {
      return phone.replaceRange(3, phone.length - 4, "****");
    }
    return phone;
  }

  String _maskEmail(String email) {
    if (email.contains("@")) {
      var parts = email.split("@");
      var name = parts[0];
      if (name.length > 3) {
        name = name.substring(0, 3) + "***";
      } else {
        name = name + "***";
      }
      return "$name@${parts[1]}";
    }
    return email;
  }
}
