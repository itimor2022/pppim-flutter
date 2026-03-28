import 'package:flutter/services.dart';

class PrecisionLimitFormatter extends TextInputFormatter {
  int _scale;

  /// 总金额
  double _totalAmount;

  PrecisionLimitFormatter(this._scale, this._totalAmount);

  RegExp exp = RegExp(r"[0-9]");
  static const String POINTER = ".";
  static const String DOUBLE_ZERO = "00";
  static const String ZERO = "0";

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.startsWith('.')) {
      return TextEditingValue(
          text: '0.', selection: TextSelection.collapsed(offset: 2));
    }

    // if (newValue.text.startsWith(POINTER) && newValue.text.length == 1) {
    //   //第一个不能输入小数点
    //   return oldValue;
    // }

    ///输入完全删除
    if (newValue.text.isEmpty) {
      return TextEditingValue();
    }

    ///只允许输入小数
    if (!exp.hasMatch(newValue.text)) {
      return oldValue;
    }

    if (newValue.text.startsWith(ZERO) &&
        newValue.text.split("0")[1].startsWith(RegExp(r'[0-9]'))) {
      return TextEditingValue(
          text: '0', selection: TextSelection.collapsed(offset: 1));

      // return newValue;
    }

    ///包含小数点的情况
    if (newValue.text.contains(POINTER)) {
      ///包含多个小数
      if (newValue.text.indexOf(POINTER) !=
          newValue.text.lastIndexOf(POINTER)) {
        return oldValue;
      }
      String input = newValue.text;
      int index = input.indexOf(POINTER);

      ///小数点后位数
      int lengthAfterPointer = input.substring(index, input.length).length - 1;

      ///小数位大于精度
      if (lengthAfterPointer > _scale) {
        return oldValue;
      }
    } else if (newValue.text.startsWith(POINTER) ||
        newValue.text.startsWith(DOUBLE_ZERO)) {
      ///不包含小数点,不能以“00”开头
      return oldValue;
    }

    // 判断输入的值是否超过200
    double value = double.tryParse(newValue.text) ?? 0;
    if (value > _totalAmount) {
      return TextEditingValue(
          text: _totalAmount.toString(),
          selection: TextSelection.collapsed(offset: 3));
    }

    return newValue;
  }
}

class PrecisionLimitFormatter1 extends TextInputFormatter {
  final int _scale;
  final int _totalAmount;

  PrecisionLimitFormatter1(this._scale, this._totalAmount);

  static const String POINTER = ".";
  static const String ZERO = "0";
  static final RegExp digitRegExp = RegExp(r"^\d+(\.\d*)?$");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String text = newValue.text;

    // 不允许以 '.' 开头
    if (text.startsWith(POINTER)) {
      return TextEditingValue(
          text: '0.', selection: TextSelection.collapsed(offset: 2));
    }

    // 不允许以单独的 '0' 开头，除非后面紧跟小数点
    if (text.startsWith(ZERO) && text.length > 1 && !text.startsWith('0.')) {
      return oldValue;
    }

    // 输入完全删除
    if (text.isEmpty) {
      return TextEditingValue();
    }

    // 非合法数字输入
    if (!digitRegExp.hasMatch(text)) {
      return oldValue;
    }

    // 检查小数点的数量
    if (text.indexOf(POINTER) != text.lastIndexOf(POINTER)) {
      return oldValue;
    }

    // 限制小数点后精度
    if (text.contains(POINTER)) {
      int index = text.indexOf(POINTER);
      if (text.length - index - 1 > _scale) {
        return oldValue;
      }
    }

    // 输入值超过总金额限制
    double value = double.tryParse(text) ?? 0;
    if (value > _totalAmount) {
      return TextEditingValue(
        text: _totalAmount.toString(),
        selection:
            TextSelection.collapsed(offset: _totalAmount.toString().length),
      );
    }

    return newValue;
  }
}
