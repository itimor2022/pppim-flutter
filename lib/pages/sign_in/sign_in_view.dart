import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'sign_in_logic.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key});

  final logic = Get.find<SignInLogic>();

  static const _weekTitles = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(title: '签到'),
      backgroundColor: const Color(0xFFF7F1E8),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: logic.refreshData,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              _buildHeroCard(),
              16.verticalSpace,
              _buildStatsRow(),
              16.verticalSpace,
              _buildCalendarCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final signedDays = logic.records.length;
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC978), Color(0xFFFF8C5D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26E08A4F),
            blurRadius: 30.r,
            offset: Offset(0, 16.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child:
                    Icon(Icons.auto_awesome, color: Colors.white, size: 22.sp),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月签到日历',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      logic.monthLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          22.verticalSpace,
          Text(
            '¥${logic.rewardText}',
            style: TextStyle(
              fontSize: 34.sp,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          8.verticalSpace,
          Text(
            logic.isTodaySigned.value ? '今天已完成签到' : '今天签到后奖励直达钱包',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          18.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric('已签到', '$signedDays天'),
              ),
              12.horizontalSpace,
              Expanded(
                child: _buildHeroMetric(
                  '今日状态',
                  logic.isTodaySigned.value ? '已完成' : '待签到',
                ),
              ),
            ],
          ),
          18.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: Button(
              text: logic.isTodaySigned.value
                  ? '今天已签到'
                  : (logic.signing.value ? '签到中...' : '立即签到'),
              height: 46.h,
              enabled: !logic.isTodaySigned.value && !logic.signing.value,
              enabledColor: Colors.white,
              disabledColor: Colors.white.withOpacity(0.45),
              textStyle: TextStyle(
                color: logic.isTodaySigned.value
                    ? const Color(0xFFB85E3C)
                    : const Color(0xFFE56B3E),
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
              onTap: logic.signIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          6.verticalSpace,
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final signedDays = logic.records.length;
    return Row(
      children: [
        Expanded(
          child: _buildPlainStatCard(
            title: '签到奖励',
            value: '¥${logic.rewardText}',
            accent: const Color(0xFF1F6A52),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: _buildPlainStatCard(
            title: '已签天数',
            value: '$signedDays',
            accent: const Color(0xFFC27927),
          ),
        ),
      ],
    );
  }

  Widget _buildPlainStatCard({
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF8A8F98),
            ),
          ),
          10.verticalSpace,
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final totalCells = logic.leadingEmptyCount + logic.daysInMonth;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '签到轨迹',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1B16),
            ),
          ),
          6.verticalSpace,
          Text(
            '已签到日期会用圆形高亮显示',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF96928B),
            ),
          ),
          18.verticalSpace,
          Row(
            children: _weekTitles
                .map(
                  (e) => Expanded(
                    child: Center(
                      child: Text(
                        e,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF9E907A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          14.verticalSpace,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              if (index < logic.leadingEmptyCount) {
                return const SizedBox.shrink();
              }
              final day = index - logic.leadingEmptyCount + 1;
              final signed = logic.isSignedDay(day);
              final today = logic.isToday(day);
              final borderColor = signed
                  ? const Color(0xFFFF9B63)
                  : (today ? const Color(0xFFC47D2A) : const Color(0xFFF0E8DB));
              final background = signed
                  ? const LinearGradient(
                      colors: [Color(0xFFFFC368), Color(0xFFFF8D58)],
                    )
                  : null;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: background,
                  color: background == null ? const Color(0xFFFFFBF6) : null,
                  border:
                      Border.all(color: borderColor, width: today ? 1.5 : 1),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: signed
                            ? Colors.white
                            : (today
                                ? const Color(0xFFC47D2A)
                                : const Color(0xFF362F25)),
                      ),
                    ),
                    if (signed)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Icon(
                          Icons.check_rounded,
                          size: 11.sp,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
