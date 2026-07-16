import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FormatHelpers {
  FormatHelpers._();

  /// Format amount to Indonesian Rupiah (whole number, no decimals)
  static String rupiah(double amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Format date string (YYYY-MM-DD) to display format (dd MMMM yyyy)
  static String displayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date string (YYYY-MM-DD) and createdAt to display format (dd MMMM yyyy, HH:mm)
  static String displayDateWithTime(String dateStr, DateTime? createdAt) {
    try {
      final date = DateTime.parse(dateStr);
      final formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      if (createdAt != null) {
        final timeStr = DateFormat('HH:mm', 'id_ID').format(createdAt.toLocal());
        return '$formattedDate, $timeStr';
      }
      return formattedDate;
    } catch (_) {
      return dateStr;
    }
  }

  /// Format period string (YYYY-MM) to display format (MMMM yyyy)
  static String displayPeriod(String periodStr) {
    try {
      final date = DateTime.parse('$periodStr-01');
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return periodStr;
    }
  }

  /// Get number of days in a given month
  static int daysInMonth(int year, int month) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    return [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  }

  /// Strip thousand separators from rupiah-formatted string
  static double unformatRupiah(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }
}

/// Input formatter that displays number with thousand dots (Indonesian style).
/// Stores raw digits in the controller text after formatting.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(digits);
    final formatted = _formatWithDots(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
