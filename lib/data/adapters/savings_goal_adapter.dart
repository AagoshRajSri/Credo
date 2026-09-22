import 'package:hive/hive.dart';
import '../models/savings_goal.dart';

/// typeId: 5 — must match @HiveType(typeId: 5) on the model.
class SavingsGoalAdapter extends TypeAdapter<SavingsGoal> {
  @override
  final int typeId = 5;

  @override
  SavingsGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      savedAmount: fields[3] as double,
      deadline: fields[4] as DateTime?,
      colorValue: fields[5] as int,
      iconCode: fields[6] as int,
      isCompleted: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsGoal obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.savedAmount)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.iconCode)
      ..writeByte(7)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
