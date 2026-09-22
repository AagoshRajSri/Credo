import 'package:hive/hive.dart';
import '../models/credit_score_snapshot.dart';

/// Hand-written Hive TypeAdapter for [CreditScoreSnapshot]. typeId: 4.
class CreditScoreSnapshotAdapter extends TypeAdapter<CreditScoreSnapshot> {
  @override
  final int typeId = 4;

  @override
  CreditScoreSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditScoreSnapshot(
      score: fields[0] as int,
      date: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CreditScoreSnapshot obj) {
    writer.writeByte(3); // field count
    writer
      ..writeByte(0)
      ..write(obj.score)
      ..writeByte(1)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditScoreSnapshotAdapter && runtimeType == other.runtimeType;
}
