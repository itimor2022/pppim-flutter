import 'package:get/get.dart';

import 'storage_manage_logic.dart';

class StorageManageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StorageManageLogic());
  }
}