import 'package:intl/intl.dart';

class FormatHelpers {
  FormatHelpers._();

  /// Format amount to Indonesian Rupiah (whole number, no decimals)
  static String rupiah(double amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Format amount with 2 decimal places
  static String rupiahDecimal(double amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format date string (YYYY-MM-DD) to display format (dd MMM yyyy)
  static String displayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
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
}
