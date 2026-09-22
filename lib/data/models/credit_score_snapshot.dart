import 'package:hive/hive.dart';

/// A point-in-time snapshot of the user's credit score.
/// Six of these form the sparkline under the gauge (Phase 4).
@HiveType(typeId: 4)
class CreditScoreSnapshot extends HiveObject {
  CreditScoreSnapshot({
    required this.score,
    required this.date,
    this.note,
  });

  @HiveField(0)
  final int score;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String? note;

  factory CreditScoreSnapshot.fromJson(Map<String, dynamic> json) =>
      CreditScoreSnapshot(
        score: json['score'] as int,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'date': date.toIso8601String(),
        'note': note,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditScoreSnapshot && other.date == date);

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'CreditScoreSnapshot($score, $date)';
}
