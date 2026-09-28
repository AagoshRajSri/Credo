import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class SavingsGoal {
  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.colorValue,
    required this.iconCode,
    this.isCompleted = false,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final double savedAmount;

  @HiveField(4)
  final DateTime? deadline;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final int iconCode;

  @HiveField(7)
  final bool isCompleted;

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    int? colorValue,
    int? iconCode,
    bool? isCompleted,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    final progress = savedAmount / targetAmount;
    return progress.clamp(0.0, 1.0);
  }

  double get remainingAmount {
    return (targetAmount - savedAmount).clamp(0.0, double.infinity);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': deadline?.toIso8601String(),
      'colorValue': colorValue,
      'iconCode': iconCode,
      'isCompleted': isCompleted,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      colorValue: json['colorValue'] as int,
      iconCode: json['iconCode'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
