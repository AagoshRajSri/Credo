import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

/// Hand-written Hive TypeAdapter for [Transaction]. typeId: 3.
class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 3;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      accountId: fields[1] as String,
      merchant: fields[2] as String,
      amount: fields[3] as double,
      isCredit: fields[4] as bool,
      category: TransactionCategory.values[fields[5] as int],
      date: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      note: fields[7] as String?,
      iconEmoji: fields[8] as String?,
      isFavorite: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeByte(10); // field count
    writer
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.merchant)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.isCredit)
      ..writeByte(5)
      ..write(obj.category.index)
      ..writeByte(6)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.iconEmoji)
      ..writeByte(9)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter && runtimeType == other.runtimeType;
}
