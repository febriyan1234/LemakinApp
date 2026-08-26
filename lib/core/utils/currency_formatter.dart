import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatString(String value) {
    if (value.isEmpty) return '';
    final cleaned = value.replaceAll('.', '').replaceAll(RegExp(r'\D'), '');
    final numVal = int.tryParse(cleaned);
    if (numVal == null) return '';
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(numVal);
  }
}

class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cleaned = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final double? doubleValue = double.tryParse(cleaned);
    if (doubleValue == null) {
      return oldValue;
    }

    final formatter = NumberFormat.decimalPattern('id');
    final newText = formatter.format(doubleValue.toInt());

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
