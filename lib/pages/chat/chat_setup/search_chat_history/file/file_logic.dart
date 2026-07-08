import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ChatHistoryFileLogic extends GetxController {
  final refreshController = RefreshController();
  late ConversationInfo conversationInfo;
  final messageList = <Message>[].obs;
  var pageIndex = 1;
  var pageSize = 50;
  int? _myJoinAtMillis;
  bool _joinTimeResolved = false;

  @override
  void onInit() {
    conversationInfo = Get.arguments['conversationInfo'];
    super.onInit();
  }

  @override
  void onReady() {
    onRefresh();
    super.onReady();
  }

  bool get _isGroupChat => (conversationInfo.groupID ?? '').trim().isNotEmpty;

  Future<int?> _queryMyJoinAtMillis() async {
    if (!_isGroupChat) return null;
    if (_joinTimeResolved) return _myJoinAtMillis;
    _joinTimeResolved = true;
    try {
      final list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
        groupID: conversationInfo.groupID!,
        userIDList: [OpenIM.iMManager.userID],
      );
      final joinTime = list.isNotEmpty ? (list.first.joinTime ?? 0) : 0;
      if (joinTime > 0) {
        _myJoinAtMillis = joinTime * 1000;
      }
    } catch (_) {}
    return _myJoinAtMillis;
  }

  Future<List<Message>> _filterBeforeJoin(List<Message> list) async {
    final joinAtMillis = await _queryMyJoinAtMillis();
    if (joinAtMillis == null) return list;
    return list.where((msg) => (msg.sendTime ?? 0) >= joinAtMillis).toList();
  }

  onRefresh() async {
    try {
      final list = await search(pageIndex = 1);
      if (list.isEmpty) {
        messageList.clear();
      } else {
        messageList.assignAll(list);
      }
    } finally {
      refreshController.refreshCompleted();
      if (messageList.length < pageIndex * pageSize) {
        refreshController.loadNoData();
      }
    }
  }

  onLoad() async {
    try {
      final list = await search(++pageIndex);
      if (list.isNotEmpty) {
        messageList.addAll(list);
      }
    } finally {
      if (messageList.length < pageIndex * pageSize) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  Future<List<Message>> search(int pageIndex) async {
    final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
      conversationID: conversationInfo.conversationID,
      keywordList: [],
      messageTypeList: [MessageType.file],
      pageIndex: pageIndex,
      count: pageSize,
    );
    if ((result.totalCount ?? 0) == 0 ||
        result.searchResultItems == null ||
        result.searchResultItems!.isEmpty) {
      return [];
    }
    final list = result.searchResultItems!.first.messageList ?? <Message>[];
    return _filterBeforeJoin(list);
  }

  void viewFile(Message message) {
    IMUtils.previewFile(message);
  }
}
