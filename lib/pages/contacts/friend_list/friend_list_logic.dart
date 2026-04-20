import 'dart:async';
import 'package:flutter/foundation.dart';


import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';

import '../../../core/controller/im_controller.dart';

List<ISUserInfo> _computeAZList(List<ISUserInfo> list) {
  return IMUtils.convertToAZList(list).cast<ISUserInfo>();
}


class FriendListLogic extends GetxController {
  final imLoic = Get.find<IMController>();
  final friendList = <ISUserInfo>[].obs;
  final userIDList = <String>[];
  late StreamSubscription delSub;
  late StreamSubscription addSub;
  late StreamSubscription infoChangedSub;

  @override
  void onInit() {
    delSub = imLoic.friendDelSubject.listen(_delFriend);
    addSub = imLoic.friendAddSubject.listen(_addFriend);
    infoChangedSub = imLoic.friendInfoChangedSubject.listen(_friendInfoChanged);
    imLoic.onBlacklistAdd = _delFriend;
    imLoic.onBlacklistDeleted = _addFriend;
    super.onInit();
  }

  @override
  void onReady() {
    _getFriendList();
    super.onReady();
  }

  @override
  void onClose() {
    delSub.cancel();
    addSub.cancel();
    infoChangedSub.cancel();
    super.onClose();
  }

  _getFriendList() async {
    final list = await OpenIM.iMManager.friendshipManager
        .getFriendListMap()
        .then((list) => list.where(_filterBlacklist))
        .then((list) => list.map((e) {
              final fullUser = FullUserInfo.fromJson(e);
              final user = fullUser.friendInfo != null
                  ? ISUserInfo.fromJson(fullUser.friendInfo!.toJson())
                  : ISUserInfo.fromJson(fullUser.publicInfo!.toJson());
              return user;
            }).toList());

    final sortedList = await compute(_computeAZList, list);
    onUserIDList(userIDList);
    friendList.assignAll(sortedList);
  }

  void onUserIDList(List<String> userIDList) {}

  bool _filterBlacklist(e) {
    final user = FullUserInfo.fromJson(e);
    final isBlack = user.blackInfo != null;

    if (isBlack) {
      return false;
    } else {
      userIDList.add(user.userID);
      return true;
    }
  }

  _addFriend(dynamic user) {
    if (user is FriendInfo || user is BlacklistInfo) {
      _addUser(user.toJson());
    }
  }

  _delFriend(dynamic user) {
    if (user is FriendInfo || user is BlacklistInfo) {
      friendList.removeWhere((e) => e.userID == user.userID);
    }
  }

  _friendInfoChanged(FriendInfo user) {
    friendList.removeWhere((e) => e.userID == user.userID);
    _addUser(user.toJson());
  }

  void _addUser(Map<String, dynamic> json) async {
    final info = ISUserInfo.fromJson(json);
    var list = friendList.toList();
    list.add(info);
    final sortedList = await compute(_computeAZList, list);
    friendList.assignAll(sortedList);
  }

  void viewFriendInfo(ISUserInfo info) => AppNavigator.startUserProfilePane(
        userID: info.userID!,
      );

  void searchFriend() => AppNavigator.startSearchFriend();
}
