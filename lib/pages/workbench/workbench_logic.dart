import 'dart:io';

// import 'package:flutter_openim_unimp/flutter_openim_unimp.dart';
import 'package:get/get.dart';
import 'package:openim/core/controller/app_controller.dart';
import 'package:openim_common/openim_common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class WorkbenchLogic extends GetxController {
  final refreshCtrl = RefreshController();
  final appLogic = Get.find<AppController>();
  final list = <Rx<UniMPInfo>>[].obs;
  final url = ''.obs;

  @override
  void onReady() {
    refreshList();
    super.onReady();
    /*
    final temp = appLogic.clientConfigMap['discoverPageURL'];

    if (temp == null) {
      appLogic.queryClientConfig().then((value) {
        if (value['discoverPageURL'] == null) {
          url.value = 'https://www.openim.io';
        } else {
          url.value = value['discoverPageURL'];
        }
      });
    } else {
      url.value = temp;
    }
    */
  }

  void refreshList() async {
    try {
      final list = await Apis.queryUniMPList();
      this.list.assignAll(list.map((e) => e.obs));
    } catch (e, s) {
      Logger.print('$e $s');
    }
    refreshCtrl.refreshCompleted();
  }

  void startUniMP(Rx<UniMPInfo> uniMPInfo) {
    final info = uniMPInfo.value;
    if (info.url != null &&
        (info.url!.startsWith('http://') || info.url!.startsWith('https://'))) {
      if (info.url!.endsWith('.wgt')) {
        _runWGT(uniMPInfo);
      } else {
        Get.to(() => H5Container(url: _appendUid(info.url!), title: info.name));
      }
    }
  }

  String _appendUid(String rawUrl) {
    final userID = DataSp.userID;
    if (userID == null || userID.isEmpty) return rawUrl;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    final queryParameters = Map<String, String>.from(uri.queryParameters);
    queryParameters['uid'] = userID;
    return uri.replace(queryParameters: queryParameters).toString();
  }

  void _runWGT(Rx<UniMPInfo> uniMPInfo) {
    Permissions.storage(() async {
      final info = uniMPInfo.value;
      if (info.url != null) {
        final dir = "${(await getTemporaryDirectory()).absolute.path}/unimp/";
        final url = info.url!;
        final size = info.size;
        final appID = info.appID;
        final wgtPath = '$dir$appID.wgt';
        final file = File(wgtPath);
        if ((await file.exists()) && ((await file.length()) == size)) {
          openMinMP(appID!, wgtPath);
        } else {
          if (info.progress == 0 || info.progress == null) {
            HttpUtil.download(
              url,
              cachePath: wgtPath,
              onProgress: (int count, int total) {
                final length = total < 0 ? size! : total;
                uniMPInfo.update((val) {
                  val?.progress = ((count / length) * 100).toInt();
                  if (count == length) {
                    openMinMP(appID!, wgtPath);
                  }
                });
              },
            ).catchError((_) {
              uniMPInfo.value.progress = 0;
              IMViews.showToast('下载失败！');
            });
          }
        }
      }
    });
  }

  void openMinMP(String appID, String wgtPath) async {
    // final success = await FlutterOpenimUnimp().releaseWgtToRunPath(
    //   appID: appID,
    //   wgtPath: wgtPath,
    // );
    // if (success == true) {
    //   FlutterOpenimUnimp().openUniMP(appID: appID);
    // }
  }
}
