import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../widgets/register_page_bg.dart';
import 'register_logic.dart';
import 'register_mode.dart';

class RegisterPage extends StatelessWidget {
  final logic = Get.find<RegisterLogic>();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => RegisterBgView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StrRes.newUserRegister.toText
              ..style = Styles.ts_0089FF_22sp_semibold,
            29.verticalSpace,
            Obx(
              () => kRegisterByAccount
                  ? InputBox.account(
                      label: StrRes.account,
                      code: '',
                      hintText: StrRes.plsEnterAccount,
                      controller: logic.phoneCtrl,
                    )
                  : InputBox.phone(
                      label: StrRes.phoneNumber,
                      hintText: StrRes.plsEnterPhoneNumber,
                      code: logic.areaCode.value,
                      onAreaCode: logic.openCountryCodePicker,
                      controller: logic.phoneCtrl,
                    ),
            ),
            16.verticalSpace,
            InputBox.invitationCode(
              label: '上级ID',
              hintText: '请输入上级ID',
              controller: logic.invitationCodeCtrl,
            ),
            130.verticalSpace,
            Obx(() => Button(
                  text: StrRes.nextStep,
                  enabled: logic.enabled.value,
                  onTap: logic.next,
                )),
          ],
        ),
      );
}
