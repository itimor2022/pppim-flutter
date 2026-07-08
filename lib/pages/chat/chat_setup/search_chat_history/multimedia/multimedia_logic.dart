import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

enum MultimediaType { picture, video }

class ChatHistoryMultimediaLogic extends GetxController {
  final refreshController = RefreshController();
  late ConversationInfo conversationInfo;
  late MultimediaType multimediaType;
  final messageList = <Message>[];
  final groupMessage = <String, List<Message>>{}.obs;
  int pageIndex = 1;
  int pageSize = 50;
  int? _myJoinAtMillis;
  bool _joinTimeResolved = false;

  @override
  void onInit() {
    conversationInfo = Get.arguments['conversationInfo'];
    multimediaType = Get.arguments['multimediaType'];
    super.onInit();
  }

  bool get isPicture => multimediaType == MultimediaType.picture;

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

  @override
  void onReady() {
    onRefresh();
    super.onReady();
  }

  void onRefresh() async {
    try {
      final list = await _search(pageIndex = 1);
      if (list.isEmpty) {
        messageList.clear();
        groupMessage.clear();
      } else {
        messageList.assignAll(list);
        groupMessage.assignAll(IMUtils.groupingMessage(list.reversed.toList()));
      }
    } finally {
      refreshController.refreshCompleted();
      if (messageList.length < pageIndex * pageSize) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  void onLoad() async {
    try {
      final list = await _search(++pageIndex);
      if (list.isNotEmpty) {
        messageList.addAll(list);
        groupMessage.addAll(IMUtils.groupingMessage(list.reversed.toList()));
      }
    } finally {
      if (messageList.length < pageIndex * pageSize) {
        refreshController.loadNoData();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  Future<List<Message>> _search(int pageIndex) async {
    final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
      conversationID: conversationInfo.conversationID,
      keywordList: [],
      messageTypeList: [isPicture ? MessageType.picture : MessageType.video],
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

  void viewMultimedia(Message message) {
    if (isPicture) {
      IMUtils.previewPicture(message, allList: messageList);
    } else {
      IMUtils.previewVideo(message);
    }
  }

  String getSnapshotUrl(Message message) {
    return isPicture
        ? message.pictureElem!.sourcePicture!.url!.thumbnailAbsoluteString
        : message.videoElem!.snapshotUrl!.thumbnailAbsoluteString;
  }
}
