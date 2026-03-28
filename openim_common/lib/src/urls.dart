import 'config.dart';

class Urls {
  static final onlineStatus =
      "${Config.imApiUrl}/manager/get_users_online_status";
  static final userOnlineStatus =
      "${Config.imApiUrl}/user/get_users_online_status";
  static final queryAllUsers = "${Config.imApiUrl}/manager/get_all_users_uid";
  static final updateUserInfo = "${Config.appAuthUrl}/user/update";
  static final searchFriendInfo = "${Config.appAuthUrl}/friend/search";
  static final getUsersFullInfo = "${Config.appAuthUrl}/user/find/full";
  static final searchUserFullInfo = "${Config.appAuthUrl}/user/search/full";

  static final getVerificationCode = "${Config.appAuthUrl}/account/code/send";
  static final checkVerificationCode =
      "${Config.appAuthUrl}/account/code/verify";
  static final register = "${Config.appAuthUrl}/account/register";

  static final resetPwd = "${Config.appAuthUrl}/account/password/reset";
  static final changePwd = "${Config.appAuthUrl}/account/password/change";
  static final login = "${Config.appAuthUrl}/account/login";

  static final upgrade = "${Config.appAuthUrl}/app/check";

  /// office
  static final tag = "${Config.appAuthUrl}/office/tag";
  static final getUserTags = "$tag/find/user";
  static final createTag = "$tag/add";
  static final deleteTag = "$tag/del";
  static final updateTag = "$tag/set";
  static final sendTagNotification = "$tag/send";
  static final getTagNotificationLog = "$tag/send/log";
  static final delTagNotificationLog = "$tag/send/log/del";

  /// 全局配置
  static final getClientConfig = '${Config.appAuthUrl}/client_config/get';

  /// 小程序
  static final uniMPUrl = '${Config.appAuthUrl}/applet/list';

  /// 红包 (Port 10008)
  static final sendRedPacket =
      "${Config.appAuthUrl}/RedPacketService/SendRedPacket";
  static final grabRedPacket =
      "${Config.appAuthUrl}/RedPacketService/GrabRedPacket";
  static final getRedPacketDetail =
      "${Config.appAuthUrl}/RedPacketService/GetRedPacketDetail";
  static final getWalletBalance =
      "${Config.appAuthUrl}/RedPacketService/GetWalletBalance";
  static final setPayPassword =
      "${Config.appAuthUrl}/RedPacketService/SetPayPassword";
  static final verifyPayPassword =
      "${Config.appAuthUrl}/RedPacketService/VerifyPayPassword";
  static final resetPayPassword =
      "${Config.appAuthUrl}/RedPacketService/ResetPayPassword";
  static final getSendRedPacketList =
      "${Config.appAuthUrl}/RedPacketService/GetSendRedPacketList";
  static final getRecvRedPacketList =
      "${Config.appAuthUrl}/RedPacketService/GetRecvRedPacketList";
  static final getWalletRecords =
      "${Config.appAuthUrl}/RedPacketService/GetWalletRecords";
      
  /// 群管理 & 扫雷专用接口
  static final getGroupMineConfigs =
      "${Config.appAuthUrl}/RedPacketService/GetGroupMineConfigs";
  static final setGroupMineConfigs =
      "${Config.appAuthUrl}/RedPacketService/SetGroupMineConfigs";
  static final getGroupBills =
      "${Config.appAuthUrl}/RedPacketService/GetGroupBills";
  static final toggleRobot =
      "${Config.appAuthUrl}/RedPacketService/ToggleRobot";
  static final getRobotStatus =
      "${Config.appAuthUrl}/RedPacketService/GetRobotStatus";
      
  // New Settings endpoints
  static final getGroupMineSetting = "${Config.appAuthUrl}/RedPacketService/GetGroupMineSetting";
  static final setGroupMineSetting = "${Config.appAuthUrl}/RedPacketService/SetGroupMineSetting";
  static final getGroupRobotConfig = "${Config.appAuthUrl}/RedPacketService/GetGroupRobotConfig";
  static final setGroupRobotConfig = "${Config.appAuthUrl}/RedPacketService/SetGroupRobotConfig";
  static final getSpecialRewardConfigs = "${Config.appAuthUrl}/RedPacketService/GetSpecialRewardConfigs";
  static final setSpecialRewardConfigs = "${Config.appAuthUrl}/RedPacketService/SetSpecialRewardConfigs";
}
