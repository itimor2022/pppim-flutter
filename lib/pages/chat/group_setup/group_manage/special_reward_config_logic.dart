import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:flutter/material.dart'; // Added for TextEditingController

class SpecialRewardConfigLogic extends GetxController {
  var configs = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  var grabCtrls = <TextEditingController>[].obs; // Changed to RxList
  var rewardCtrls = <TextEditingController>[].obs; // Changed to RxList

  @override
  void onReady() {
    super.onReady();
    loadData();
  }

  void loadData() async {
    isLoading.value = true;
    try {
      final res = await Apis.getSpecialRewardConfigs();
      if (res != null && res is List) {
        configs.assignAll(List<Map<String, dynamic>>.from(res));
        _initControllers();
      }
    } catch (e) {
      Logger.print('load special reward configs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _initControllers() {
    grabCtrls.clear();
    rewardCtrls.clear();
    for (var item in configs) {
      final amt = ((item['amount'] ?? 0) / 100).toStringAsFixed(2);
      final rAmt = ((item['reward_amount'] ?? 0) / 100).toStringAsFixed(2);
      grabCtrls.add(TextEditingController(text: amt == "0.00" ? "" : amt));
      rewardCtrls.add(TextEditingController(text: rAmt == "0.00" ? "" : rAmt));
    }
  }

  void addConfig() {
    configs.add({
      'amount': 0,
      'reward_amount': 0,
    });
    grabCtrls.add(TextEditingController());
    rewardCtrls.add(TextEditingController());
  }

  void removeConfig(int index) {
    configs.removeAt(index);
    grabCtrls[index].dispose(); // Dispose controller
    rewardCtrls[index].dispose(); // Dispose controller
    grabCtrls.removeAt(index);
    rewardCtrls.removeAt(index);
  }

  // Removed updateConfig as it's no longer needed with TextEditingControllers

  void saveConfigs() async {
    // Collect from controllers before saving
    var listToSave = <Map<String, dynamic>>[];
    for (var i = 0; i < configs.length; i++) {
      final grabVal = double.tryParse(grabCtrls[i].text) ?? 0.0;
      final rewardVal = double.tryParse(rewardCtrls[i].text) ?? 0.0;
      if (grabVal > 0 || rewardVal > 0) {
        listToSave.add({
          'amount': (grabVal * 100).toInt(),
          'reward_amount': (rewardVal * 100).toInt(),
        });
      }
    }

    try {
      await LoadingView.singleton.wrap(
        asyncFunction: () => Apis.setSpecialRewardConfigs(
          configs: listToSave,
        ),
      );
      IMViews.showToast('特殊奖励配置保存成功!');
      Get.back();
    } catch (e) {
      Logger.print('save error: $e');
      IMViews.showToast('保存失败');
    }
  }

  @override
  void onClose() {
    for (var ctrl in grabCtrls) {
      ctrl.dispose();
    }
    for (var ctrl in rewardCtrls) {
      ctrl.dispose();
    }
    super.onClose();
  }
}
