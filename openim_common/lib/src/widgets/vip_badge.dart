import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../res/styles.dart';

class VipBadge extends StatelessWidget {
  const VipBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vertical = compact ? 1.h : 2.h;
    final horizontal = compact ? 5.w : 6.w;
    final radius = compact ? 8.r : 10.r;
    final style =
        (compact ? Styles.ts_0C1C33_10sp : Styles.ts_0C1C33_12sp_medium)
            .copyWith(
      color: const Color(0xFF6B4E00),
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF2BF), Color(0xFFF7D774)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 0.8,
        ),
      ),
      child: Text('VIP', style: style),
    );
  }
}
