import 'package:hive/hive.dart';
import 'enums.dart';

/// A bank account held by the user.
///
/// [fromJson] / [toJson] are used for both Dio responses and JSON asset parsing.
/// The Hive [AccountAdapter] (typeId 2) serialises this for offline cache.
@HiveType(typeId: 2)
class Account extends HiveObject {
  Account({
    required this.id,
    required this.name,
    required this.bankName,
    required this.type,
    required this.balance,
    this.lastFourDigits,
    this.colorHex = '#7C3AED',
    required this.updatedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String bankName;

  @HiveField(3)
  final AccountType type;

  @HiveField(4)
  final double balance;

  @HiveField(5)
  final String? lastFourDigits;

  @HiveField(6)
  final String colorHex;

  @HiveField(7)
  final DateTime updatedAt;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        bankName: json['bank_name'] as String,
        type: AccountType.fromString(json['type'] as String),
        balance: (json['balance'] as num).toDouble(),
        lastFourDigits: json['last_four_digits'] as String?,
        colorHex: json['color_hex'] as String? ?? '#7C3AED',
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bank_name': bankName,
        'type': type.name,
        'balance': balance,
        'last_four_digits': lastFourDigits,
        'color_hex': colorHex,
        'updated_at': updatedAt.toIso8601String(),
      };

  Account copyWith({
    String? id,
    String? name,
    String? bankName,
    AccountType? type,
    double? balance,
    String? lastFourDigits,
    String? colorHex,
    DateTime? updatedAt,
  }) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        bankName: bankName ?? this.bankName,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        lastFourDigits: lastFourDigits ?? this.lastFourDigits,
        colorHex: colorHex ?? this.colorHex,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'Account($id, $name, $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Account && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
