import 'package:hive/hive.dart';
import '../models/account.dart';
import '../models/enums.dart';

/// Hand-written Hive TypeAdapter for [Account].
/// typeId: 2 — must match @HiveType(typeId: 2) on the model.
///
/// We write this by hand instead of using hive_generator to:
/// 1. Avoid a build_runner step in every CI pass.
/// 2. Keep the adapter stable across model field reorderings
///    (we control exactly which [HiveField] index maps to what).
class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 2;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      name: fields[1] as String,
      bankName: fields[2] as String,
      type: AccountType.values[fields[3] as int],
      balance: fields[4] as double,
      lastFourDigits: fields[5] as String?,
      colorHex: fields[6] as String? ?? '#7C3AED',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer.writeByte(8); // field count
    writer
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bankName)
      ..writeByte(3)
      ..write(obj.type.index)
      ..writeByte(4)
      ..write(obj.balance)
      ..writeByte(5)
      ..write(obj.lastFourDigits)
      ..writeByte(6)
      ..write(obj.colorHex)
      ..writeByte(7)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter && runtimeType == other.runtimeType;
}
