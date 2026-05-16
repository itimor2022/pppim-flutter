import 'dart:async';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../core/controller/im_controller.dart';

class GroupReadListLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  late StreamSubscription recvGroupReadReceiptSubject;
  late String conversationID;
  late String clientMsgID;
  String groupID = '';
  List<String> hasReadIDList = [];
  int needReadCount = 0;
  int initialUnreadCount = 0;
  int initialHasReadCount = 0;
  final hasReadMemberList = <GroupMembersInfo>[].obs;
  final unreadMemberList = <GroupMembersInfo>[].obs;
  final hasReadRefreshController = RefreshController();
  final unreadRefreshController = RefreshController();
  final index = 0.obs;
  final _pageSize = 50;

  @override
  void onInit() {
    conversationID = Get.arguments['conversationID'];
    clientMsgID = Get.arguments['clientMsgID'];
    initialUnreadCount = Get.arguments['unreadCount'] ?? 0;
    initialHasReadCount = Get.arguments['hasReadCount'] ?? 0;
    queryUnreadMemberList();
    recvGroupReadReceiptSubject = imLogic.recvGroupReadReceiptSubject
        .listen((GroupMessageReceipt receipt) {
      if (receipt.conversationID == conversationID) {
        final msg = receipt.groupMessageReadInfo
            .firstWhereOrNull((element) => element.clientMsgID == clientMsgID);
        if (msg != null) {
          initialUnreadCount = msg.unreadCount;
          initialHasReadCount = msg.hasReadCount;
          if (index.value == 0) {
            queryUnreadMemberList();
          } else {
            queryHasReadMembersList();
          }
        }
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
    recvGroupReadReceiptSubject.cancel();
  }

  void queryHasReadMembersList() async {
    hasReadMemberList.clear();
    final list = await OpenIM.iMManager.messageManager
        .getGroupMessageReaderList(conversationID, clientMsgID,
            count: _pageSize);
    hasReadMemberList.assignAll(list);
    if (list.length < _pageSize) {
      hasReadRefreshController.loadNoData();
    } else {
      hasReadRefreshController.loadComplete();
    }
  }

  void loadMoreHasRead() async {
    final list = await OpenIM.iMManager.messageManager
        .getGroupMessageReaderList(conversationID, clientMsgID,
            count: _pageSize, offset: hasReadMemberList.length);
    hasReadMemberList.addAll(list);
    if (list.length < _pageSize) {
      hasReadRefreshController.loadNoData();
    } else {
      hasReadRefreshController.loadComplete();
    }
  }

  void queryUnreadMemberList() async {
    unreadMemberList.clear();
    final list = await OpenIM.iMManager.messageManager
        .getGroupMessageReaderList(conversationID, clientMsgID,
            filter: 1, count: _pageSize);
    unreadMemberList.assignAll(list);
    if (list.length < _pageSize) {
      unreadRefreshController.loadNoData();
    } else {
      unreadRefreshController.loadComplete();
    }
  }

  void loadMoreUnread() async {
    final list = await OpenIM.iMManager.messageManager
        .getGroupMessageReaderList(conversationID, clientMsgID,
            filter: 1, count: _pageSize, offset: unreadMemberList.length);
    unreadMemberList.addAll(list);
    if (list.length < _pageSize) {
      unreadRefreshController.loadNoData();
    } else {
      unreadRefreshController.loadComplete();
    }
  }

  void switchTab(i) {
    if (i == 0) {
      queryUnreadMemberList();
    } else {
      queryHasReadMembersList();
    }
    index.value = i;
  }

  int get unreadCount => initialUnreadCount > unreadMemberList.length
      ? initialUnreadCount
      : unreadMemberList.length;

  int get hasReadCount => initialHasReadCount > hasReadMemberList.length
      ? initialHasReadCount
      : hasReadMemberList.length;
}
