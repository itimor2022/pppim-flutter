import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../res/styles.dart';
import '../utils/user_ex_util.dart';

class UserIdentityBadges extends StatelessWidget {
  const UserIdentityBadges({
    super.key,
    this.ex,
    this.level,
    this.isPretty,
    this.compact = false,
  });

  final String? ex;
  final int? level;
  final bool? isPretty;
  final bool compact;

  static const Map<int, String> _levelTitleMap = {
    1: '数字新星',
    2: '数字精英',
    3: '数字典范',
    4: '数字卓越',
    5: '数字领军',
    6: '数字引领者',
    7: '数字开拓者',
  };

  @override
  Widget build(BuildContext context) {
    final pretty = isPretty ?? UserExUtil.isPretty(ex);
    final levelText = _levelTitleMap[UserExUtil.level(ex) ?? level];
    if (!pretty && levelText == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 6.w,
      runSpacing: 4.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (pretty)
          _IdentityBadge(
            compact: compact,
            text: '官方',
            icon: Icons.verified_rounded,
            textColor: const Color(0xFF0F3D70),
            borderColor: const Color(0xFF6AB8FF),
            colors: const [Color(0xFFEAF6FF), Color(0xFFB9E0FF)],
          ),
        if (levelText != null)
          _IdentityBadge(
            compact: compact,
            text: levelText,
            icon: Icons.workspace_premium_rounded,
            textColor: const Color(0xFF6B4E00),
            borderColor: const Color(0xFFD4AF37),
            colors: const [Color(0xFFFFF2BF), Color(0xFFF7D774)],
          ),
      ],
    );
  }
}

class _IdentityBadge extends StatelessWidget {
  const _IdentityBadge({
    required this.compact,
    required this.text,
    required this.icon,
    required this.textColor,
    required this.borderColor,
    required this.colors,
  });

  final bool compact;
  final String text;
  final IconData icon;
  final Color textColor;
  final Color borderColor;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final vertical = compact ? 1.h : 2.h;
    final horizontal = compact ? 5.w : 6.w;
    final radius = compact ? 8.r : 10.r;
    final iconSize = compact ? 10.sp : 12.sp;
    final style =
        (compact ? Styles.ts_0C1C33_10sp : Styles.ts_0C1C33_12sp_medium)
            .copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          2.horizontalSpace,
          Text(text, style: style),
        ],
      ),
    );
  }
}
