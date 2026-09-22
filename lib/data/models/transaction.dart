import 'package:hive/hive.dart';
import 'enums.dart';

/// A single financial transaction belonging to an [Account].
@HiveType(typeId: 3)
class Transaction extends HiveObject {
  Transaction({
    required this.id,
    required this.accountId,
    required this.merchant,
    required this.amount,
    required this.isCredit,
    required this.category,
    required this.date,
    this.note,
    this.iconEmoji,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String accountId;

  @HiveField(2)
  final String merchant;

  /// Always positive. Use [isCredit] to determine the direction.
  @HiveField(3)
  final double amount;

  /// `true` = money received; `false` = money spent.
  @HiveField(4)
  final bool isCredit;

  @HiveField(5)
  final TransactionCategory category;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  final String? iconEmoji;

  /// Signed amount: negative for debits, positive for credits.
  double get signedAmount => isCredit ? amount : -amount;

  Transaction copyWith({
    String? id,
    String? accountId,
    String? merchant,
    double? amount,
    bool? isCredit,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    String? iconEmoji,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      isCredit: isCredit ?? this.isCredit,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        merchant: json['merchant'] as String,
        amount: (json['amount'] as num).toDouble(),
        isCredit: json['is_credit'] as bool,
        category: TransactionCategory.fromString(json['category'] as String),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        iconEmoji: json['icon_emoji'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'merchant': merchant,
        'amount': amount,
        'is_credit': isCredit,
        'category': category.name,
        'date': date.toIso8601String(),
        'note': note,
        'icon_emoji': iconEmoji,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Transaction && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Transaction($id, $merchant, $amount)';
}
