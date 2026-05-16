import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

enum AnnouncementType { text, image }

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({
    super.key,
    required this.type,
    required this.content,
  });

  final AnnouncementType type;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 312.w,
          constraints: BoxConstraints(maxHeight: 0.72.sh),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '公告',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0C1C33),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Get.back(),
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: const Color(0xFF8A94A6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 20.h),
                  child: type == AnnouncementType.image
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.network(
                            content,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 160.h,
                              child: Center(
                                child: Text(
                                  '图片加载失败',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF8A94A6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Text(
                            content,
                            style: TextStyle(
                              fontSize: 15.sp,
                              height: 1.6,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
