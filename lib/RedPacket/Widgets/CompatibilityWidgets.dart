import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// 引用 openim_common 中的组件
import 'package:openim_common/openim_common.dart';

/// 兼容原 DefaultText
class DefaultText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? textColor;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const DefaultText({
    Key? key,
    required this.text,
    this.fontSize,
    this.textColor,
    this.fontWeight,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize ?? 14.sp,
        color: textColor ?? Colors.black,
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
    );
  }
}

/// 兼容原 Defaultbutton (注意大小写)
class Defaultbutton extends StatelessWidget {
  final String text;
  final Function() function;
  final Color? color;
  final double? radius;
  final double? width;
  final double? height;

  const Defaultbutton({
    Key? key,
    required this.text,
    required this.function,
    this.color,
    this.radius,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: function,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 44.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? Colors.blue,
          borderRadius: BorderRadius.circular(radius ?? 4.r),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
      ),
    );
  }
}

/// 兼容原 DefaultContainer
class DefaultContainer extends StatelessWidget {
  final Widget? child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double? borderRadius; // 简化处理，原项目可能是 Custom 类型
  final String? assetSrc;
  final AlignmentGeometry? alignment;
  final Function()? onTap;

  const DefaultContainer({
    Key? key,
    this.child,
    this.color,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.assetSrc,
    this.alignment,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!.r)
            : null,
        image: assetSrc != null
            ? DecorationImage(
                image: AssetImage(assetSrc!),
                fit: BoxFit.contain,
                alignment: Alignment.topCenter)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }
}

/// 兼容原 AppBarNewWidget
class AppBarNewWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final Color? titleColor;
  final List<Widget>? actions;

  const AppBarNewWidget({
    Key? key,
    required this.title,
    this.backgroundColor,
    this.titleColor,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.black)),
      backgroundColor: backgroundColor ?? Colors.white,
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: titleColor ?? Colors.black),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(44.h);
}

class appTopicData {
  static _AppTopicTheme get textTheme => _AppTopicTheme();
}

class _AppTopicTheme {
  TextStyle get headlineLarge =>
      TextStyle(color: const Color(0xff999999), fontSize: 14.sp);
  TextStyle get displayLarge => TextStyle(color: Colors.black, fontSize: 14.sp);
}

/// 兼容 ImageCacheBuild
class ImageCacheBuild extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double? radius;

  const ImageCacheBuild({
    Key? key,
    required this.url,
    this.width,
    this.height,
    this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AvatarView(
      url: url,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(radius ?? 0),
    );
  }
}

/// 辅助方法：取消焦点
Widget cancelFocusEvent(
    {required BuildContext context, required Widget child}) {
  return GestureDetector(
    onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
    child: child,
  );
}
