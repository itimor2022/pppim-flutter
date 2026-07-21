import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import '../../pages/chat/group_setup/group_member_list/group_member_list_logic.dart';
import '../routes/app_pages.dart';
import 'PrecisionLimitFormatter.dart';
import 'RedPacketSendController.dart';
import 'Widgets/CompatibilityWidgets.dart';

class RedPacketSendPage extends GetView<RedPacketSendController> {
  @override
  Widget build(BuildContext context) {
    // 页面加载时默认选中拼手气红包（仅当是群聊时）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isSingle && controller.index.value != 1) {
        controller.index.value = 1;
        controller.onNo();
      }
    });

    return cancelFocusEvent(
      context: context,
      child: Scaffold(
        appBar: AppBarNewWidget(title: '发红包'),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                /// 如果是群组,才有分组
                if (!controller.isSingle)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.only(top: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () {
                            controller.index.value = 0;
                            controller.onNo();
                          },
                          child: Obx(() => Column(
                                children: [
                                  DefaultText(
                                    text: "普通",
                                    textColor: controller.index.value == 0
                                        ? Colors.black
                                        : const Color(0xff939393),
                                    fontSize: 16.sp,
                                  ),
                                  DefaultContainer(
                                    margin: EdgeInsets.only(top: 8.w),
                                    width: 44.w,
                                    height: 2.w,
                                    color: controller.index.value == 0
                                        ? Colors.black
                                        : Colors.transparent,
                                  ),
                                ],
                              )),
                        ),
                        InkWell(
                          onTap: () {
                            controller.index.value = 1;
                            controller.onNo();
                          },
                          child: Obx(() => Column(
                                children: [
                                  DefaultText(
                                    text: "拼手气",
                                    textColor: controller.index.value == 1
                                        ? Colors.black
                                        : const Color(0xff939393),
                                    fontSize: 16.sp,
                                  ),
                                  DefaultContainer(
                                    margin: EdgeInsets.only(top: 8.w),
                                    width: 44.w,
                                    height: 2.w,
                                    color: controller.index.value == 1
                                        ? Colors.black
                                        : Colors.transparent,
                                  ),
                                ],
                              )),
                        ),
                        InkWell(
                          onTap: () {
                            controller.index.value = 2;
                            controller.onNo();
                          },
                          child: Obx(() => Column(
                                children: [
                                  DefaultText(
                                    text: "专属",
                                    textColor: controller.index.value == 2
                                        ? Colors.black
                                        : const Color(0xff939393),
                                    fontSize: 16.sp,
                                  ),
                                  DefaultContainer(
                                    margin: EdgeInsets.only(top: 8.w),
                                    width: 44.w,
                                    height: 2.w,
                                    color: controller.index.value == 2
                                        ? Colors.black
                                        : Colors.transparent,
                                  ),
                                ],
                              )),
                        ),
                        InkWell(
                          onTap: () {
                            controller.index.value = 3;
                            controller.onNo();
                          },
                          child: Obx(() => Column(
                                children: [
                                  DefaultText(
                                    text: "扫雷",
                                    textColor: controller.index.value == 3
                                        ? Colors.black
                                        : const Color(0xff939393),
                                    fontSize: 16.sp,
                                  ),
                                  DefaultContainer(
                                    margin: EdgeInsets.only(top: 8.w),
                                    width: 44.w,
                                    height: 2.w,
                                    color: controller.index.value == 3
                                        ? Colors.black
                                        : Colors.transparent,
                                  ),
                                ],
                              )),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Obx(
                    () => Column(
                      children: [
                        /// 如果是群聊 并且 (普通红包 或者 拼手气）
                        /// 红包数量 (最大500个)
                        if ((controller.index.value == 0 ||
                                controller.index.value == 1) &&
                            !controller.isSingle)
                          item(
                            '红包数量',
                            '0',
                            textInputType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              // 限制整数，最大500
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*$')),
                              LengthLimitingTextInputFormatter(3),
                            ],
                            textController: controller.packetQuantity,
                            onChanged: (p0) {
                              // 如果输入为空或者为0，清空
                              if (p0.isEmpty || p0 == "0") {
                                controller.packetQuantity.text = '';
                                controller.priceObs.value = '0.00';
                                return;
                              }

                              int count = int.tryParse(p0) ?? 0;
                              // 最大500个
                              if (count > 500) {
                                controller.packetQuantity.text = '500';
                                count = 500;
                              }

                              /// 普通红包：根据总金额和数量计算单个金额
                              if (controller.index.value == 0 &&
                                  !controller.isSingle) {
                                if (controller.singlePrice.text.isNotEmpty &&
                                    controller.singlePrice.text != "") {
                                  double totalAmt = double.tryParse(
                                          controller.singlePrice.text) ??
                                      0;
                                  controller.priceObs.value =
                                      totalAmt.toStringAsFixed(2);
                                }
                                return;
                              }

                              /// 拼手气红包：总金额不变，只更新数量
                              if (controller.index.value == 1 &&
                                  !controller.isSingle) {
                                // 保持总金额不变
                                return;
                              }
                            },
                          ),

                        /// 扫雷 Tab 的专属表单项：包数，雷号与赔率
                        if (controller.index.value == 3 && !controller.isSingle)
                          Column(
                            children: [
                              pickerItem(
                                '红包数量',
                                controller.selectedPacketCount.value == 0
                                    ? '群主暂未配置'
                                    : '${controller.selectedPacketCount.value} 包',
                                onTap: () {
                                  if (controller.mineConfigs.isEmpty) return;
                                  Get.bottomSheet(
                                    Container(
                                      color: Colors.white,
                                      child: Wrap(
                                        children:
                                            controller.mineConfigs.map((cfg) {
                                          return ListTile(
                                            title: Text(
                                                '${cfg['packet_count']} 包',
                                                textAlign: TextAlign.center),
                                            onTap: () {
                                              controller.selectedPacketCount
                                                  .value = cfg['packet_count'];
                                              controller.packetQuantity.text =
                                                  '${cfg['packet_count']}';
                                              controller.selectedMineNums
                                                  .clear();
                                              controller.mineNum.text = '';
                                              controller.updateOdds();
                                              Get.back();
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              pickerItem(
                                '雷号',
                                controller.selectedMineNums.isEmpty
                                    ? '请选择'
                                    : controller.selectedMineNums.join('/'),
                                onTap: () {
                                  if (controller.mineConfigs.isEmpty) return;
                                  final config = controller.mineConfigs
                                      .firstWhere(
                                          (e) =>
                                              e['packet_count'] ==
                                              controller
                                                  .selectedPacketCount.value,
                                          orElse: () => <String, dynamic>{});
                                  if (config.isEmpty) return;
                                  final int multiLimit =
                                      config['multi_count_limit'] ?? 1;

                                  Get.bottomSheet(
                                    Container(
                                      color: Colors.white,
                                      padding: EdgeInsets.all(16.w),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('请选择雷号 (最多可选 $multiLimit 个)',
                                              style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 16.w),
                                          Obx(() => Wrap(
                                                spacing: 12.w,
                                                runSpacing: 12.w,
                                                children:
                                                    List.generate(10, (index) {
                                                  final isSelected = controller
                                                      .selectedMineNums
                                                      .contains(index);
                                                  return InkWell(
                                                    onTap: () {
                                                      if (isSelected) {
                                                        controller
                                                            .selectedMineNums
                                                            .remove(index);
                                                      } else {
                                                        if (controller
                                                                .selectedMineNums
                                                                .length <
                                                            multiLimit) {
                                                          controller
                                                              .selectedMineNums
                                                              .add(index);
                                                          controller
                                                              .selectedMineNums
                                                              .sort();
                                                        } else {
                                                          EasyLoading.showToast(
                                                              '最多只能选择 $multiLimit 个雷号');
                                                        }
                                                      }
                                                      controller.mineNum.text =
                                                          controller
                                                              .selectedMineNums
                                                              .join('/');
                                                      controller.updateOdds();
                                                    },
                                                    child: Container(
                                                      width: 50.w,
                                                      height: 50.w,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? const Color(
                                                                0xffFF563F)
                                                            : const Color(
                                                                0xffF3F3F3),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                      ),
                                                      child: Text('$index',
                                                          style: TextStyle(
                                                              fontSize: 18.sp,
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                  );
                                                }),
                                              )),
                                          SizedBox(height: 20.w),
                                          Defaultbutton(
                                            text: '确定',
                                            function: () => Get.back(),
                                            color: const Color(0xffFF563F),
                                          ),
                                          SizedBox(height: 20.w),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              item(
                                '赔率',
                                '1.5',
                                enabled: false,
                                textController: TextEditingController(
                                    text: "${controller.odds.value} 倍"),
                              ),

                              /// 扫雷单个金额
                              item(
                                '单个金额',
                                textController: controller.singlePrice,
                                '0.00',
                                textInputType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  PrecisionLimitFormatter(2, 200000),
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'))
                                ],
                                onChanged: (p0) {
                                  if (p0.isEmpty) {
                                    controller.priceObs.value = '0.00';
                                    controller.updateSweepMineRemark();
                                    return;
                                  }
                                  controller.priceObs.value = p0;
                                  controller.singlePrice.text = p0;
                                  controller.updateSweepMineRemark();
                                },
                                isIcon: true,
                              ),
                            ],
                          ),

                        /// 普通红包（群聊）：显示"总金额"，用户输入总金额
                        if (controller.index.value == 0 && !controller.isSingle)
                          item(
                            '总金额',
                            textController: controller.singlePrice,
                            '100.00',
                            textInputType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              PrecisionLimitFormatter(2, 200000),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ],
                            onChanged: (p0) {
                              if (p0.isEmpty) {
                                controller.priceObs.value = '0.00';
                                return;
                              }

                              double totalAmt = double.tryParse(p0) ?? 0;
                              controller.priceObs.value = p0;
                              controller.singlePrice.text = p0;
                            },
                            isIcon: true,
                          ),

                        /// 单聊：显示"单个金额"
                        if (controller.isSingle)
                          item(
                            '单个金额',
                            textController: controller.singlePrice,
                            '0.00',
                            textInputType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              PrecisionLimitFormatter(2, 200000),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ],
                            onChanged: (p0) {
                              if (p0.isEmpty) {
                                controller.priceObs.value = '0.00';
                                return;
                              }
                              controller.priceObs.value = p0;
                              controller.singlePrice.text = p0;
                            },
                            isIcon: true,
                          ),

                        /// 拼手气红包（群聊）：显示"总金额"，最低100元
                        if (controller.index.value == 1 && !controller.isSingle)
                          item(
                            '总金额',
                            textController: controller.singlePrice,
                            '100.00',
                            textInputType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              PrecisionLimitFormatter(2, 200000),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ],
                            onChanged: (p0) {
                              if (p0.isEmpty) {
                                controller.priceObs.value = '0.00';
                                return;
                              }

                              double totalAmt = double.tryParse(p0) ?? 0;
                              controller.priceObs.value = p0;
                              controller.singlePrice.text = p0;
                            },
                            isIcon: true,
                          ),

                        /// 如果是专属红包，
                        if (controller.index.value == 2 && !controller.isSingle)
                          item(
                            '发给谁',
                            '请选择群员',
                            textController: controller.groupInfo,
                            onTap: () async {
                              var info = await Get.toNamed(
                                AppRoutes.groupMemberList,
                                arguments: {
                                  'groupInfo': GroupInfo(
                                    groupID: controller.id!,
                                    memberCount: 999999,
                                  ),
                                  'opType': GroupMemberOpType.simpleSelect,
                                },
                              );
                              if (info != null) {
                                String? uid;
                                String? nickname;
                                String? faceURL;

                                if (info is GroupMembersInfo) {
                                  uid = info.userID;
                                  nickname = info.nickname;
                                  faceURL = info.faceURL;
                                } else if (info is UserInfo) {
                                  uid = info.userID;
                                  nickname = info.nickname;
                                  faceURL = info.faceURL;
                                } else if (info is Map) {
                                  uid = info['userID'];
                                  nickname = info['nickname'];
                                  faceURL = info['faceURL'];
                                }

                                if (uid != null) {
                                  controller.userList.value = UserInfo(
                                    userID: uid,
                                    nickname: nickname,
                                    faceURL: faceURL,
                                  );
                                  controller.groupInfo.text = nickname ?? '';
                                }
                              }
                            },
                            enabled: false,
                          ),

                        /// 专属红包的金额（群聊）
                        if (controller.index.value == 2 && !controller.isSingle)
                          item(
                            '单个金额',
                            textController: controller.singlePrice,
                            '0.00',
                            textInputType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              PrecisionLimitFormatter(2, 200000),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ],
                            onChanged: (p0) {
                              if (p0.isEmpty) {
                                controller.priceObs.value = '0.00';
                                return;
                              }
                              controller.priceObs.value = p0;
                              controller.singlePrice.text = p0;
                            },
                            isIcon: true,
                          ),

                        Obx(() {
                          bool isSweepMine = controller.index.value == 3 &&
                              !controller.isSingle;
                          return Container(
                            margin: EdgeInsets.only(
                              top: 10.w,
                              bottom: 55.w,
                            ),
                            child: item(
                              '留言',
                              isSweepMine ? '' : '恭喜发财，大吉大利',
                              textController: controller.productDescription,
                              enabled: !isSweepMine,
                            ),
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            DefaultText(
                              text: controller.priceObs.value,
                              textColor: const Color(0xff161616),
                              fontSize: 44.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 4.w, top: 12.w),
                              child: DefaultText(
                                text: "元",
                                textColor: const Color(0xff161616),
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25.w),
                        Builder(builder: (context) {
                          bool isSweepMineMissingConfig =
                              controller.index.value == 3 &&
                                  !controller.isSingle &&
                                  controller.mineConfigs.isEmpty;
                          return Defaultbutton(
                            function: () {
                              if (isSweepMineMissingConfig) return;

                              /// 群聊普通红包校验
                              if (controller.index.value == 0 &&
                                  !controller.isSingle) {
                                if (controller.packetQuantity.text.isEmpty ||
                                    controller.packetQuantity.text == "0") {
                                  EasyLoading.showToast("红包数量不能为空");
                                  return;
                                }
                                int count = int.tryParse(
                                        controller.packetQuantity.text) ??
                                    0;
                                if (count > 500) {
                                  EasyLoading.showToast("红包数量不能超过500个");
                                  return;
                                }
                                if (controller.singlePrice.text.isEmpty ||
                                    controller.singlePrice.text == "0") {
                                  EasyLoading.showToast("请填写总金额");
                                  return;
                                }
                                double totalAmt = double.tryParse(
                                        controller.singlePrice.text) ??
                                    0;
                                if (totalAmt < 100) {
                                  EasyLoading.showToast("红包总金额不能低于100元");
                                  return;
                                }
                                // 确保每个红包至少有0.01元
                                if (totalAmt / count < 0.01) {
                                  EasyLoading.showToast(
                                      "每个红包金额不能低于0.01元，请减少红包数量或增加总金额");
                                  return;
                                }
                              }

                              /// 拼手气红包校验（群聊）
                              if (controller.index.value == 1 &&
                                  !controller.isSingle) {
                                if (controller.packetQuantity.text.isEmpty ||
                                    controller.packetQuantity.text == "0") {
                                  EasyLoading.showToast("红包数量不能为空");
                                  return;
                                }
                                int count = int.tryParse(
                                        controller.packetQuantity.text) ??
                                    0;
                                if (count > 500) {
                                  EasyLoading.showToast("红包数量不能超过500个");
                                  return;
                                }
                                if (controller.singlePrice.text.isEmpty ||
                                    controller.singlePrice.text == "0") {
                                  EasyLoading.showToast("请填写总金额");
                                  return;
                                }
                                double totalAmt = double.tryParse(
                                        controller.singlePrice.text) ??
                                    0;
                                if (totalAmt < 100) {
                                  EasyLoading.showToast("红包总金额不能低于100元");
                                  return;
                                }
                                // 确保每个红包至少有0.01元
                                if (totalAmt / count < 0.01) {
                                  EasyLoading.showToast(
                                      "每个红包金额不能低于0.01元，请减少红包数量或增加总金额");
                                  return;
                                }
                              }

                              /// 专属红包校验（群聊）
                              if (controller.index.value == 2 &&
                                  !controller.isSingle) {
                                if (controller.groupInfo.text.isEmpty) {
                                  EasyLoading.showToast("请选择发送对象");
                                  return;
                                }
                                if (controller.singlePrice.text.isEmpty ||
                                    controller.singlePrice.text == "0") {
                                  EasyLoading.showToast("金额不能为0");
                                  return;
                                }
                              }

                              /// 单聊校验
                              if (controller.isSingle) {
                                if (controller.singlePrice.text.isEmpty ||
                                    controller.singlePrice.text == "0") {
                                  EasyLoading.showToast("红包金额不能为空");
                                  return;
                                }
                                controller.sendRedPacketMessage(
                                  redPacketRemarks:
                                      controller.productDescription.text,
                                  exclusiveRemarks:
                                      controller.productDescription.text,
                                  packetType: '3',
                                  totalAmount:
                                      double.parse(controller.singlePrice.text),
                                  totalPacket: 1,
                                  sendUserId: controller.id,
                                  userImIdOrGroupId: controller.id,
                                );
                              }

                              /// 群聊普通红包
                              if (controller.index.value == 0 &&
                                  !controller.isSingle) {
                                int count = int.tryParse(
                                        controller.packetQuantity.text) ??
                                    1;
                                double totalAmt = double.tryParse(
                                        controller.singlePrice.text) ??
                                    0;
                                double singleAmt = totalAmt / count;
                                controller.sendRedPacketMessage(
                                  redPacketRemarks:
                                      controller.productDescription.text,
                                  exclusiveRemarks:
                                      controller.productDescription.text,
                                  packetType: '1',
                                  totalAmount: totalAmt,
                                  singleAmount: singleAmt,
                                  totalPacket: count,
                                  sendUserId: null,
                                  userImIdOrGroupId: controller.id,
                                );
                              }

                              /// 群聊拼手气红包
                              if (controller.index.value == 1 &&
                                  !controller.isSingle) {
                                controller.sendRedPacketMessage(
                                  redPacketRemarks:
                                      controller.productDescription.text,
                                  exclusiveRemarks:
                                      controller.productDescription.text,
                                  packetType: '2',
                                  totalAmount:
                                      double.parse(controller.priceObs.value),
                                  totalPacket:
                                      int.parse(controller.packetQuantity.text),
                                  sendUserId: null,
                                  userImIdOrGroupId: controller.id,
                                );
                              }

                              /// 群聊专属红包
                              if (controller.index.value == 2 &&
                                  !controller.isSingle) {
                                controller.sendRedPacketMessage(
                                  redPacketRemarks:
                                      controller.productDescription.text,
                                  exclusiveRemarks:
                                      controller.productDescription.text,
                                  packetType: '3',
                                  totalAmount:
                                      double.parse(controller.singlePrice.text),
                                  totalPacket: 1,
                                  sendUserId: controller.userList.value.userID,
                                  userImIdOrGroupId: controller.id,
                                  recvNickname:
                                      controller.userList.value.nickname,
                                );
                              }

                              /// 扫雷红包
                              if (controller.index.value == 3 &&
                                  !controller.isSingle) {
                                if (controller.packetQuantity.text.isEmpty ||
                                    int.parse(controller.packetQuantity.text) <
                                        4 ||
                                    int.parse(controller.packetQuantity.text) >
                                        12) {
                                  EasyLoading.showToast("扫雷包数限制为 4-12 包");
                                  return;
                                }
                                if (controller.mineNum.text.isEmpty) {
                                  EasyLoading.showToast("请选择雷号");
                                  return;
                                }
                                if (controller.singlePrice.text.isEmpty ||
                                    double.parse(controller.singlePrice.text) <=
                                        0) {
                                  EasyLoading.showToast("请输入有效金额");
                                  return;
                                }

                                if (controller.mineConfigs.isNotEmpty) {
                                  final config = controller.mineConfigs
                                      .firstWhere(
                                          (e) =>
                                              e['packet_count'] ==
                                                  controller.selectedPacketCount
                                                      .value ||
                                              e['packetCount'] ==
                                                  controller.selectedPacketCount
                                                      .value,
                                          orElse: () => <String, dynamic>{});
                                  if (config.isNotEmpty) {
                                    double minAmt = (config['min_amount'] ??
                                            config['minAmount'] ??
                                            0) /
                                        100.0;
                                    double maxAmt = (config['max_amount'] ??
                                            config['maxAmount'] ??
                                            0) /
                                        100.0;
                                    double inputAmt = double.parse(
                                        controller.singlePrice.text);
                                    if (inputAmt < minAmt ||
                                        inputAmt > maxAmt) {
                                      EasyLoading.showToast(
                                          "扫雷金额需在 ${minAmt.toStringAsFixed(0)} ~ ${maxAmt.toStringAsFixed(0)} 元之间");
                                      return;
                                    }
                                  }
                                }

                                int autoMineCount = 1;
                                if (controller.mineNum.text.contains('/')) {
                                  autoMineCount =
                                      controller.mineNum.text.split('/').length;
                                }

                                controller.sendRedPacketMessage(
                                  redPacketRemarks:
                                      controller.productDescription.text == ""
                                          ? "恭喜发财"
                                          : controller.productDescription.text,
                                  exclusiveRemarks: "",
                                  packetType: '6',
                                  totalAmount:
                                      double.parse(controller.priceObs.value),
                                  totalPacket:
                                      int.parse(controller.packetQuantity.text),
                                  sendUserId: null,
                                  userImIdOrGroupId: controller.id,
                                  mineNums: controller.mineNum.text,
                                  odds: controller.odds.value,
                                  isMulti:
                                      controller.mineNum.text.contains('/'),
                                  mineCount: autoMineCount,
                                );
                              }
                            },
                            text: isSweepMineMissingConfig
                                ? '群主暂未配置扫雷选项'
                                : '塞钱进红包',
                            radius: 8,
                            color: isSweepMineMissingConfig
                                ? Colors.grey
                                : const Color(0xffFF563F),
                          );
                        }),
                        SizedBox(height: 20.w),
                        Text(
                          "未领取的红包，将在 24 小时后过期退回",
                          style: TextStyle(
                              color: const Color(0xff999999), fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double getNuber() {
    return 200000;
  }

  /// 输入框封装样式
  Widget item(
    String title,
    String hintText, {
    TextInputType textInputType = TextInputType.text,
    Function(String)? onSubmitted,
    FocusNode? focusNode,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    bool isIcon = false,
    bool enabled = true,
    TextEditingController? textController,
    Function()? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            padding: EdgeInsets.only(
                left: 15.w, right: 15.w, top: 10.w, bottom: 10.w),
            margin: EdgeInsets.only(top: 8.w),
            child: Row(
              children: [
                DefaultText(
                  text: title,
                  fontSize: 14.sp,
                  textColor: Colors.black,
                ),
                SizedBox(
                  width: 15.w,
                ),
                Expanded(
                  child: TextField(
                    keyboardType: textInputType,
                    controller: textController,
                    textAlign: TextAlign.end,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: appTopicData.textTheme.headlineLarge,
                    ),
                    autofocus: false,
                    inputFormatters: inputFormatters,
                    style: appTopicData.textTheme.displayLarge,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    enabled: enabled,
                  ),
                ),
                if (!enabled)
                  Icon(
                    Icons.chevron_right_outlined,
                    color: const Color(0xff939393),
                    size: 20.sp,
                  ),
                if (isIcon)
                  Container(
                    margin: EdgeInsets.only(left: 4.w),
                    child: DefaultText(
                      text: "元",
                      textColor: const Color(0xff161616),
                      fontSize: 14.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget pickerItem(
    String title,
    String hintText, {
    bool isIcon = false,
    Function()? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            padding: EdgeInsets.only(
                left: 15.w, right: 15.w, top: 10.w, bottom: 10.w),
            margin: EdgeInsets.only(top: 8.w),
            child: Row(
              children: [
                DefaultText(
                  text: title,
                  fontSize: 14.sp,
                  textColor: Colors.black,
                ),
                SizedBox(
                  width: 15.w,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.w),
                    alignment: Alignment.centerRight,
                    child: Text(
                      hintText,
                      style: appTopicData.textTheme.displayLarge
                          .copyWith(color: const Color(0xff939393)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_outlined,
                  color: const Color(0xff939393),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
