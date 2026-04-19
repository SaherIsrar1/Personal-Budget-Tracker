import 'package:intl/intl.dart';

class Formatter {
  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _currencyCompact = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);
  static final _dateShort = DateFormat('MMM d');
  static final _dateLong = DateFormat('MMM d, yyyy');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _time = DateFormat('h:mm a');

  static String currency(double amount) => _currency.format(amount);

  static String currencyCompact(double amount) => _currencyCompact.format(amount);

  /// Shows + for income, - for expense with color logic
  static String signedCurrency(double amount, {bool isIncome = false}) {
    final formatted = _currency.format(amount.abs());
    return isIncome ? '+$formatted' : '-$formatted';
  }

  static String dateShort(DateTime date) => _dateShort.format(date);
  static String dateLong(DateTime date) => _dateLong.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String time(DateTime date) => _time.format(date);

  static String percentage(double value) => '${(value * 100).toStringAsFixed(0)}%';
}
