/// Domain enums used across models.
/// Kept in one file so Hive adapter IDs are easy to audit centrally.
library;

// ── AccountType ───────────────────────────────────────────────────────────
enum AccountType {
  savings,
  checking,
  credit,
  investment;

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccountType.savings,
    );
  }

  String get displayName => switch (this) {
        AccountType.savings => 'Savings',
        AccountType.checking => 'Checking',
        AccountType.credit => 'Credit Card',
        AccountType.investment => 'Investment',
      };
}

// ── TransactionCategory ───────────────────────────────────────────────────
enum TransactionCategory {
  food,
  shopping,
  entertainment,
  transport,
  utilities,
  health,
  travel,
  other;

  static TransactionCategory fromString(String value) {
    return TransactionCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionCategory.other,
    );
  }

  String get displayName => switch (this) {
        TransactionCategory.food => 'Food & Dining',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.entertainment => 'Entertainment',
        TransactionCategory.transport => 'Transport',
        TransactionCategory.utilities => 'Utilities',
        TransactionCategory.health => 'Health',
        TransactionCategory.travel => 'Travel',
        TransactionCategory.other => 'Other',
      };

  String get emoji => switch (this) {
        TransactionCategory.food => '🍔',
        TransactionCategory.shopping => '🛍️',
        TransactionCategory.entertainment => '🎬',
        TransactionCategory.transport => '🚗',
        TransactionCategory.utilities => '📡',
        TransactionCategory.health => '💊',
        TransactionCategory.travel => '✈️',
        TransactionCategory.other => '💳',
      };
}
