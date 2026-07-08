import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim/pages/conversation/conversation_logic.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../routes/app_navigator.dart';

class ExpandChatHistoryLogic extends GetxController {
  final logic = Get.find<ConversationLogic>();
  final refreshCtrl = RefreshController();
  final searchCtrl = TextEditingController();
  final focusNode = FocusNode();
  late Rx<SearchResultItems> searchResultItems;
  late String defaultSearchKey;
  var pageIndex = 1;
  var pageSize = 20;
  int? _joinAtMillis;
  bool _joinTimeResolved = false;

  @override
  void onInit() {
    SearchResultItems items = Get.arguments['searchResultItems'];
    searchResultItems = Rx(SearchResultItems.fromJson(items.toJson()));
    defaultSearchKey = Get.arguments['defaultSearchKey'];
    searchCtrl.text = defaultSearchKey;
    if (searchResultItems.value.messageCount! < pageSize) {
      refreshCtrl.loadNoData();
    } else {
      refreshCtrl.loadComplete();
    }
    searchCtrl.addListener(_clearInput);
    super.onInit();
  }

  @override
  void onClose() {
    focusNode.dispose();
    searchCtrl.dispose();
    super.onClose();
  }

  _clearInput() {
    if (searchKey.isEmpty) {
      searchResultItems.update((val) {
        val?.messageList?.clear();
      });
    }
  }

  String get searchKey => searchCtrl.text.trim();

  String calContent(Message message) => IMUtils.calContent(
        content: IMUtils.parseMsg(message, replaceIdToNickname: true),
        key: searchKey,
        style: Styles.ts_8E9AB0_14sp,
        usedWidth: 80.w + 26.w,
      );

  bool get _isGroupChat =>
      searchResultItems.value.conversationType == ConversationType.group ||
      searchResultItems.value.conversationType == ConversationType.superGroup;

  Future<int?> _queryJoinAtMillis() async {
    if (!_isGroupChat) return null;
    if (_joinTimeResolved) return _joinAtMillis;
    _joinTimeResolved = true;
    final groupID = searchResultItems.value.messageList?.firstOrNull?.groupID;
    if (groupID == null || groupID.trim().isEmpty) return null;
    try {
      final list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
        groupID: groupID,
        userIDList: [OpenIM.iMManager.userID],
      );
      final joinTime = list.isNotEmpty ? (list.first.joinTime ?? 0) : 0;
      if (joinTime > 0) {
        _joinAtMillis = joinTime * 1000;
      }
    } catch (_) {}
    return _joinAtMillis;
  }

  Future<List<Message>> _filterBeforeJoin(List<Message> list) async {
    final joinAtMillis = await _queryJoinAtMillis();
    if (joinAtMillis == null) return list;
    return list.where((msg) => (msg.sendTime ?? 0) >= joinAtMillis).toList();
  }

  Future<SearchResult> _request(int pageIndex) =>
      OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: searchResultItems.value.conversationID,
        keywordList: [searchKey],
        messageTypeList: [MessageType.text, MessageType.atText],
        pageIndex: pageIndex,
        count: pageSize,
      );

  void search() async {
    var result = await _request(pageIndex = 1);
    var list = result.searchResultItems;
    if (null != list && list.isNotEmpty) {
      final filtered =
          await _filterBeforeJoin(list.first.messageList ?? <Message>[]);
      list.first
        ..messageList = filtered
        ..messageCount = filtered.length;
      searchResultItems.value = list.first;
      if (searchResultItems.value.messageCount! < pageSize) {
        refreshCtrl.loadNoData();
      } else {
        refreshCtrl.loadComplete();
      }
    } else {
      refreshCtrl.loadNoData();
    }
  }

  void load() async {
    var result = await _request(++pageIndex);
    var list = result.searchResultItems;
    if (null != list && list.isNotEmpty) {
      var item = list.first;
      final filtered = await _filterBeforeJoin(item.messageList ?? <Message>[]);
      searchResultItems.update((val) {
        val?.messageList?.addAll(filtered);
      });
      if (filtered.length < pageSize) {
        refreshCtrl.loadNoData();
      } else {
        refreshCtrl.loadComplete();
      }
    } else {
      refreshCtrl.loadNoData();
    }
  }

  void previewMessageHistory(Message message) =>
      AppNavigator.startPreviewChatHistory(
        conversationInfo: ConversationInfo(
          conversationID: searchResultItems.value.conversationID!,
          showName: searchResultItems.value.showName,
          faceURL: searchResultItems.value.faceURL,
        ),
        message: message,
      );

  void toChat() async {
    final list = await LoadingView.singleton.wrap(
      asyncFunction: () =>
          OpenIM.iMManager.conversationManager.getMultipleConversation(
        conversationIDList: [searchResultItems.value.conversationID!],
      ),
    );
    final info = list.firstOrNull;
    if (null != info) {
      logic.toChat(conversationInfo: info);
    }
  }
}
