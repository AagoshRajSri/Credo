import 'package:intl/intl.dart';

/// Centralised formatting utilities used across all screens.
abstract final class CredoFormatters {
  static final _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatterDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compact = NumberFormat.compact(locale: 'en_IN');

  // ── Currency ──────────────────────────────────────────────────────────
  /// ₹1,24,850  (Indian numbering, no decimals)
  static String rupees(double amount) =>
      _inrFormatter.format(amount.abs());

  /// ₹1,24,850.75  (with decimals, for detail screens)
  static String rupeesExact(double amount) =>
      _inrFormatterDecimal.format(amount.abs());

  /// ₹1.2L  (compact, for chart axis labels)
  static String rupeesCompact(double amount) =>
      '₹${_compact.format(amount.abs())}';

  /// +₹500 / −₹349  (signed, for transaction rows)
  static String signedRupees(double amount, {required bool isCredit}) {
    final formatted = _inrFormatter.format(amount.abs());
    return isCredit ? '+$formatted' : '−$formatted';
  }

  // ── Dates ─────────────────────────────────────────────────────────────
  /// "Today", "Yesterday", or "22 Sep"
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('dd MMM').format(date);
  }

  /// "22 Sep 2026, 7:30 PM"  (for detail screens)
  static String fullDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, h:mm a').format(date.toLocal());

  /// "Sep 2026"
  static String monthYear(DateTime date) =>
      DateFormat('MMM yyyy').format(date);

  // ── Greeting ──────────────────────────────────────────────────────────
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    if (hour < 21) return 'Good evening,';
    return 'Good night,';
  }
}
