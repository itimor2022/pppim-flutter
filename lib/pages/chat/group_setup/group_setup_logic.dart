import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/pages/chat/group_setup/edit_name/edit_name_logic.dart';
import 'package:openim/utils/group_invite_permission_util.dart';
import 'package:openim/utils/group_member_count_util.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sprintf/sprintf.dart';
import 'package:synchronized/synchronized.dart';

import '../../../core/controller/app_controller.dart';
import '../../../core/controller/im_controller.dart';
import '../../../routes/app_navigator.dart';
import '../../contacts/select_contacts/select_contacts_logic.dart';
import '../../conversation/conversation_logic.dart';
import '../chat_logic.dart';
import '../chat_setup/search_chat_history/multimedia/multimedia_logic.dart';
import 'group_member_list/group_member_list_logic.dart';

class GroupSetupLogic extends GetxController {
  final imLogic = Get.find<IMController>();

  // final chatLogic = Get.find<ChatLogic>();
  final chatLogic = Get.find<ChatLogic>(tag: GetTags.chat);
  final appLogic = Get.find<AppController>();
  final conversationLogic = Get.find<ConversationLogic>();
  final memberList = <GroupMembersInfo>[].obs;
  late Rx<ConversationInfo> conversationInfo;
  late Rx<GroupInfo> groupInfo;
  late Rx<GroupMembersInfo> myGroupMembersInfo;
  late StreamSubscription _guSub;
  late StreamSubscription _mASub;
  late StreamSubscription _mISub;
  late StreamSubscription _mDSub;
  late StreamSubscription _ccSub;
  late StreamSubscription _jasSub;
  late StreamSubscription _jdsSub;
  final lock = Lock();
  final isJoinedGroup = false.obs;

  @override
  void onInit() {
    conversationInfo = Rx(Get.arguments['conversationInfo']);
    groupInfo = Rx(_defaultGroupInfo);
    myGroupMembersInfo = Rx(_defaultMemberInfo);

    _ccSub = imLogic.conversationChangedSubject.listen((newList) {
      for (var newValue in newList) {
        if (newValue.conversationID == conversationInfo.value.conversationID) {
          conversationInfo.update((val) {
            val?.isPinned = newValue.isPinned;
            // 免打扰 0：正常；1：不接受消息；2：接受在线消息不接受离线消息；
            val?.recvMsgOpt = newValue.recvMsgOpt;
            val?.isMsgDestruct = newValue.isMsgDestruct;
            val?.msgDestructTime = newValue.msgDestructTime;
          });
          break;
        }
      }
    });

    _guSub = imLogic.groupInfoUpdatedSubject.listen((value) {
      if (value.groupID == groupInfo.value.groupID) {
        _updateGroupInfo(value);
      }
    });

    _jasSub = imLogic.joinedGroupAddedSubject.listen((value) async {
      if (value.groupID == groupInfo.value.groupID) {
        isJoinedGroup.value = true;
        await lock.synchronized(() async => _queryAllInfo());
      }
    });

    _jdsSub = imLogic.joinedGroupDeletedSubject.listen((value) {
      if (value.groupID == groupInfo.value.groupID) {
        isJoinedGroup.value = false;
      }
    });

    _mISub = imLogic.memberInfoChangedSubject.listen((e) {
      if (e.groupID == groupInfo.value.groupID &&
          e.userID == myGroupMembersInfo.value.userID) {
        myGroupMembersInfo.update((val) {
          val?.nickname = e.nickname;
          val?.roleLevel = e.roleLevel;
        });
      }
      if (e.groupID == groupInfo.value.groupID &&
          e.userID == groupInfo.value.ownerUserID) {
        var index = memberList.indexWhere(
            (element) => element.userID == groupInfo.value.ownerUserID);
        if (index == -1) {
          memberList.insert(0, e);
        } else if (index != 0) {
          memberList.insert(0, memberList.removeAt(index));
        }
      }
    });
    _mASub = imLogic.memberAddedSubject.listen((e) async {
      if (e.groupID == groupInfo.value.groupID) {
        if (e.userID == OpenIM.iMManager.userID) {
          isJoinedGroup.value = true;
          await lock.synchronized(() async => _queryAllInfo());
        } else {
          memberList.add(e);
        }
      }
    });
    _mDSub = imLogic.memberDeletedSubject.listen((e) {
      if (e.groupID == groupInfo.value.groupID) {
        if (e.userID == OpenIM.iMManager.userID) {
          isJoinedGroup.value = false;
        } else {
          memberList.removeWhere((element) => element.userID == e.userID);
          // memberList.refresh();
        }
      }
    });
    super.onInit();
  }

  @override
  void onReady() {
    // getGroupInfo();
    // getGroupMembers();
    // getMyGroupMemberInfo();
    _checkIsJoinedGroup();
    super.onReady();
  }

  @override
  void onClose() {
    _guSub.cancel();
    _mASub.cancel();
    _mDSub.cancel();
    _ccSub.cancel();
    _mISub.cancel();
    _jdsSub.cancel();
    _jasSub.cancel();
    super.onClose();
  }

  get _defaultGroupInfo => GroupInfo(
        groupID: conversationInfo.value.groupID!,
        groupName: conversationInfo.value.showName,
        faceURL: conversationInfo.value.faceURL,
        memberCount: 0,
      );

  get _defaultMemberInfo => GroupMembersInfo(
        userID: OpenIM.iMManager.userID,
        nickname: OpenIM.iMManager.userInfo.nickname,
      );

  bool get isOwnerOrAdmin => isOwner || isAdmin;

  bool get canViewAllMembers => isOwnerOrAdmin || appLogic.showGroupAllMembers;

  bool get isAdmin =>
      myGroupMembersInfo.value.roleLevel == GroupRoleLevel.admin;

  bool get isOwner => groupInfo.value.ownerUserID == OpenIM.iMManager.userID;

  bool get allowOrdinaryMemberInvite =>
      GroupInvitePermissionUtil.allowOrdinaryMemberInvite(groupInfo.value);

  bool get canInviteMember => isOwnerOrAdmin || allowOrdinaryMemberInvite;

  bool get isPinned => conversationInfo.value.isPinned == true;

  bool get isNotDisturb => conversationInfo.value.recvMsgOpt != 0;

  String get conversationID => conversationInfo.value.conversationID;

  bool get isMsgDestruct => conversationInfo.value.isMsgDestruct == true;

  int get destructDuration =>
      conversationInfo.value.msgDestructTime ?? 7 * 24 * 60 * 60;

  int _getDisplayMemberCount(GroupInfo value) => value.memberCount == null
      ? memberList.length
      : GroupMemberCountUtil.getDisplayMemberCount(value);

  List<GroupMembersInfo> get visibleMemberList => !isOwnerOrAdmin
      ? memberList
          .where((member) =>
              member.roleLevel == GroupRoleLevel.owner ||
              member.roleLevel == GroupRoleLevel.admin)
          .toList()
      : memberList.toList();

  int get visibleMemberCount => !canViewAllMembers
      ? visibleMemberList.length
      : _getDisplayMemberCount(groupInfo.value);

  void _checkIsJoinedGroup() async {
    isJoinedGroup.value = await OpenIM.iMManager.groupManager.isJoinedGroup(
      groupID: groupInfo.value.groupID,
    );
    _queryAllInfo();
  }

  void _queryAllInfo() {
    if (isJoinedGroup.value) {
      getGroupInfo();
      getGroupMembers();
      getMyGroupMemberInfo();
    }
  }

  getGroupMembers() async {
    var list = await OpenIM.iMManager.groupManager.getGroupMemberList(
      groupID: groupInfo.value.groupID,
      count: 10,
    );
    memberList.assignAll(list);
  }

  getGroupInfo() async {
    var list = await OpenIM.iMManager.groupManager.getGroupsInfo(
      groupIDList: [groupInfo.value.groupID],
    );
    var value = list.firstOrNull;
    if (null != value) {
      _updateGroupInfo(value);
    }
  }

  getMyGroupMemberInfo() async {
    final list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
      groupID: groupInfo.value.groupID,
      userIDList: [OpenIM.iMManager.userID],
    );
    final info = list.firstOrNull;
    if (null != info) {
      myGroupMembersInfo.update((val) {
        val?.nickname = info.nickname;
        val?.roleLevel = info.roleLevel;
      });
    }
  }

  void _updateGroupInfo(GroupInfo value) {
    groupInfo.update((val) {
      val?.groupName = value.groupName;
      val?.faceURL = value.faceURL;
      val?.notification = value.notification;
      val?.introduction = value.introduction;
      val?.memberCount = value.memberCount;
      val?.ownerUserID = value.ownerUserID;
      val?.status = value.status;
      val?.needVerification = value.needVerification;
      val?.groupType = value.groupType;
      val?.lookMemberInfo = value.lookMemberInfo;
      val?.applyMemberFriend = value.applyMemberFriend;
      val?.notificationUserID = value.notificationUserID;
      val?.notificationUpdateTime = value.notificationUpdateTime;
      val?.ex = value.ex;
    });
  }

  void modifyGroupAvatar() {
    IMViews.openPhotoSheet(
      onData: (path, url) async {
        if (url != null) {
          await _modifyGroupInfo(faceUrl: url);
          groupInfo.update((val) {
            val?.faceURL = url;
          });
        }
      },
    );
  }

  void modifyGroupName() => AppNavigator.startEditGroupName(
        type: EditNameType.groupNickname,
      );

  _modifyGroupInfo({
    String? groupName,
    String? notification,
    String? introduction,
    String? faceUrl,
  }) =>
      OpenIM.iMManager.groupManager.setGroupInfo(GroupInfo(
        groupID: groupInfo.value.groupID,
        groupName: groupName,
        notification: notification,
        introduction: introduction,
        faceURL: faceUrl,
      ));

  void modifyMyGroupNickname() => AppNavigator.startEditGroupName(
        type: EditNameType.myGroupMemberNickname,
      );

  void viewGroupQrcode() => AppNavigator.startGroupQrcode();

  void viewGroupMembers() => AppNavigator.startGroupMemberList(
        groupInfo: groupInfo.value,
      );

  void editGroupAnnouncement() => AppNavigator.startEditGroupAnnouncement(
        groupID: groupInfo.value.groupID,
      );

  void groupManage() => AppNavigator.startGroupManage(
        groupInfo: groupInfo.value,
      );

  void searchChatHistory() => AppNavigator.startSearchChatHistory(
        conversationInfo: conversationInfo.value,
      );

  void searchChatHistoryPicture() =>
      AppNavigator.startSearchChatHistoryMultimedia(
        conversationInfo: conversationInfo.value,
      );

  void searchChatHistoryVideo() =>
      AppNavigator.startSearchChatHistoryMultimedia(
        conversationInfo: conversationInfo.value,
        multimediaType: MultimediaType.video,
      );

  void searchChatHistoryFile() => AppNavigator.startSearchChatHistoryFile(
        conversationInfo: conversationInfo.value,
      );

  void _removeConversation() async {
    // 删除群会话
    await OpenIM.iMManager.conversationManager
        .deleteConversationAndDeleteAllMsg(
      conversationID: conversationInfo.value.conversationID,
    );

    conversationLogic.removeConversation(conversationInfo.value.conversationID);
  }

  void quitGroup() async {
    if (isJoinedGroup.value) {
      if (isOwner) {
        var confirm = await Get.dialog(CustomDialog(
          title: StrRes.dismissGroupHint,
        ));
        if (confirm == true) {
          // transferGroup();
          await OpenIM.iMManager.groupManager.dismissGroup(
            groupID: groupInfo.value.groupID,
          );
          // 删除群会话
          // _removeConversation();
        } else {
          return;
        }
      } else {
        var confirm = await Get.dialog(CustomDialog(
          title: StrRes.quitGroupHint,
        ));
        if (confirm == true) {
          // 退群
          await OpenIM.iMManager.groupManager.quitGroup(
            groupID: groupInfo.value.groupID,
          );
          // 删除群会话
          // _removeConversation();
        } else {
          return;
        }
      }
    } else {
      // 删除群会话
      _removeConversation();
    }

    AppNavigator.startBackMain();
  }

  void copyGroupID() {
    IMUtils.copy(text: groupInfo.value.groupID);
  }

  int length() {
    int buttons = (canInviteMember ? 1 : 0) + (isOwnerOrAdmin ? 1 : 0);
    return (visibleMemberList.length + buttons) > 10
        ? 10
        : (visibleMemberList.length + buttons);
  }

  Widget itemBuilder({
    required int index,
    required Widget Function(GroupMembersInfo info) builder,
    required Widget Function() addButton,
    required Widget Function() delButton,
  }) {
    final list = visibleMemberList;
    final showAddButton = canInviteMember;
    final showDelButton = isOwnerOrAdmin;
    final buttonCount = (showAddButton ? 1 : 0) + (showDelButton ? 1 : 0);
    final memberLength = 10 - buttonCount;
    if (list.length > memberLength) {
      if (index < memberLength) {
        var info = list.elementAt(index);
        return builder(info);
      } else if (showAddButton && index == memberLength) {
        return addButton();
      } else if (showDelButton &&
          index == memberLength + (showAddButton ? 1 : 0)) {
        return delButton();
      }
    } else {
      if (index < list.length) {
        var info = list.elementAt(index);
        return builder(info);
      } else if (showAddButton && index == list.length) {
        return addButton();
      } else if (showDelButton &&
          index == list.length + (showAddButton ? 1 : 0)) {
        return delButton();
      }
    }
    return const SizedBox();
  }

  void toggleTopChat() async {
    await LoadingView.singleton.wrap(
      asyncFunction: () => OpenIM.iMManager.conversationManager.pinConversation(
        conversationID: conversationID,
        isPinned: !isPinned,
      ),
    );
  }

  void toggleNotDisturb() {
    LoadingView.singleton.wrap(
        asyncFunction: () =>
            OpenIM.iMManager.conversationManager.setConversationRecvMessageOpt(
              conversationID: conversationID,
              status: !isNotDisturb ? 2 : 0,
            ));
  }

  void clearChatHistory() async {
    var confirm = await Get.dialog(CustomDialog(
      title: StrRes.confirmClearChatHistory,
      rightText: StrRes.clearAll,
    ));
    if (confirm == true) {
      // 先清空本地UI，让用户立即看到清空效果
      chatLogic.clearAllMessage();
      IMViews.showToast(StrRes.clearSuccessfully);
      
      // 在后台异步删除服务器消息，不阻塞UI
      OpenIM.iMManager.conversationManager
          .clearConversationAndDeleteAllMsg(
        conversationID: conversationID,
      ).catchError((error) {
        // 如果删除失败，记录错误但不影响用户体验
        print('清空服务器消息失败: $error');
      });
    }
  }

  void addMember() async {
    if (!canInviteMember) {
      IMViews.showToast(StrRes.ordinaryMemberInviteNotAllowed);
      return;
    }
    final result = await AppNavigator.startSelectContacts(
      action: SelAction.addMember,
      groupID: groupInfo.value.groupID,
    );

    final list = IMUtils.convertSelectContactsResultToUserID(result);
    if (list is List<String>) {
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.groupManager.inviteUserToGroup(
          groupID: groupInfo.value.groupID,
          userIDList: list,
          reason: 'Come on baby',
        ),
      );
      getGroupMembers();
    }
  }

  void removeMember() async {
    final list = await AppNavigator.startGroupMemberList(
      groupInfo: groupInfo.value,
      opType: GroupMemberOpType.del,
    );
    if (list is List<GroupMembersInfo>) {
      var removeUidList = list.map((e) => e.userID!).toList();
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.groupManager.kickGroupMember(
          groupID: groupInfo.value.groupID,
          userIDList: removeUidList,
          reason: 'Get out baby',
        ),
      );
      getGroupMembers();
    }
  }

  void viewMemberInfo(GroupMembersInfo membersInfo) =>
      AppNavigator.startUserProfilePane(
        userID: membersInfo.userID!,
        nickname: membersInfo.nickname,
        faceURL: membersInfo.faceURL,
        groupID: membersInfo.groupID,
      );

  String get getDestructDurationStr {
    int day = 1 * 24 * 60 * 60;
    int week = 7 * day;
    int month = 1 * 30 * day;
    if (destructDuration % month == 0) {
      return sprintf(StrRes.nMonth, [destructDuration ~/ month]);
    } else if (destructDuration % week == 0) {
      return sprintf(StrRes.nWeek, [destructDuration ~/ week]);
    } else {
      return sprintf(StrRes.nDay, [destructDuration ~/ day]);
    }
  }

  void toggleDestructMessage() {
    LoadingView.singleton.wrap(asyncFunction: () async {
      await OpenIM.iMManager.conversationManager.setConversationIsMsgDestruct(
        conversationID: conversationID,
        isMsgDestruct: !isMsgDestruct,
      );
    });
  }

  void setDestructMessageDuration() async {
    IMViews.showSinglePicker(
      title: StrRes.periodicallyDeleteMessage,
      description: StrRes.periodicallyDeleteMessageDescription,
      pickerData: [
        [1, 2, 3, 4, 5, 6],
        [
          sprintf(StrRes.nDay, ['']).trim(),
          sprintf(StrRes.nWeek, ['']).trim(),
          sprintf(StrRes.nMonth, ['']).trim(),
        ]
      ],
      isArray: true,
      // selected: [2, 2],
      onConfirm: (indexList, valueList) {
        int day = 1 * 24 * 60 * 60;
        int week = 7 * day;
        int month = 1 * 30 * day;
        int valueIndex = indexList.firstOrNull ?? 0;
        int unitIndex = indexList.lastOrNull ?? 0;
        if (unitIndex == 0) {
          setConversationMsgDestructTime((valueIndex + 1) * day);
        } else if (unitIndex == 1) {
          setConversationMsgDestructTime((valueIndex + 1) * week);
        } else if (unitIndex == 2) {
          setConversationMsgDestructTime((valueIndex + 1) * month);
        }
      },
    );
  }

  void setConversationMsgDestructTime(int duration) {
    LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.conversationManager
            .setConversationMsgDestructTime(
                conversationID: conversationID, duration: duration));
  }
}
