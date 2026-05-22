import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../group_profile_panel/group_profile_panel_logic.dart';

class SendVerificationApplicationLogic extends GetxController {
  final inputCtrl = TextEditingController();
  String? userID;
  String? groupID;
  String? sourceGroupID;
  JoinGroupMethod? joinGroupMethod;

  bool get isEnterGroup => groupID != null;

  bool get isAddFriend => userID != null;

  @override
  void onInit() {
    userID = Get.arguments['userID'];
    groupID = Get.arguments['groupID'];
    sourceGroupID = Get.arguments['sourceGroupID'];
    joinGroupMethod = Get.arguments['joinGroupMethod'];
    super.onInit();
  }

  void send() async {
    if (isAddFriend) {
      _applyAddFriend();
    } else if (isEnterGroup) {
      _applyEnterGroup();
    }
  }

  _applyAddFriend() async {
    try {
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.friendshipManager.addFriend(
          userID: userID!,
          reason: inputCtrl.text.trim(),
          ex: sourceGroupID?.isNotEmpty == true
              ? jsonEncode({'sourceGroupID': sourceGroupID})
              : null,
        ),
      );
      Get.back();
      IMViews.showToast(StrRes.sendSuccessfully);
    } catch (e) {
      IMViews.showToast(_addFriendErrorText(e));
    }
  }

  String _addFriendErrorText(Object error) {
    if (error is PlatformException) {
      final code = int.tryParse(error.code);
      switch (code) {
        case SDKErrorCode.refuseToAddFriends:
          return StrRes.canNotAddFriends;
        case SDKErrorCode.notAddMyselfAsAFriend:
          return StrRes.canNotAddYourselfAsFriend;
        case SDKErrorCode.hasBeenBlocked:
          return StrRes.friendApplicationBlocked;
        case SDKErrorCode.alreadyAFriendRelationship:
          return StrRes.alreadyAFriendRelationship;
        case SDKErrorCode.insufficientPermissions:
          if (sourceGroupID?.isNotEmpty == true ||
              (error.message?.contains('group') ?? false)) {
            return StrRes.notAllAddMemberToBeFriend;
          }
          return StrRes.noPermissionToAddFriend;
      }
    }
    return StrRes.sendFailed;
  }

  /// By Invitation = 2 , Search = 3 , QRCode  = 4
  _applyEnterGroup() {
    LoadingView.singleton
        .wrap(
          asyncFunction: () => OpenIM.iMManager.groupManager.joinGroup(
            groupID: groupID!,
            reason: inputCtrl.text.trim(),
            joinSource: joinGroupMethod == JoinGroupMethod.qrcode ? 4 : 3,
          ),
        )
        .then((value) => IMViews.showToast(StrRes.sendSuccessfully))
        .then((value) => Get.back())
        .catchError((e) => IMViews.showToast(StrRes.sendFailed));
  }
}
