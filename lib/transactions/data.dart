import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.note,
    required super.date,
    required super.type,
    required super.category,
  });

  factory TransactionModel.fromEntity(TransactionEntity e) => TransactionModel(
    id: e.id,
    amount: e.amount,
    note: e.note,
    date: e.date,
    type: e.type,
    category: e.category,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'note': note,
    'date': date.toIso8601String(),
    'type': type.name,
    'category': category,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'] as String,
    amount: (map['amount'] as num).toDouble(),
    note: (map['note'] as String?) ?? '',
    date: DateTime.parse(map['date'] as String),
    type: (map['type'] as String) == 'income' ? TransactionType.income : TransactionType.expense,
    // backward compat if old records had no category
    category: (map['category'] as String?) ??
        ((map['type'] as String) == 'income' ? 'salary' : 'uncategorized'),
  );
}

abstract interface class LocalTransactionDataSource {
  Future<void> add(TransactionModel model);
  Future<List<TransactionModel>> loadAll();
}

class LocalTransactionDataSourceImpl implements LocalTransactionDataSource {
  static const _storageKey = 'transactions_v1';

  @override
  Future<void> add(TransactionModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null) {
      final decoded = json.decode(raw) as List;
      for (final e in decoded) {
        list.add(Map<String, dynamic>.from(e as Map));
      }
    }
    list.add(model.toMap());
    await prefs.setString(_storageKey, json.encode(list));
  }

  @override
  Future<List<TransactionModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final decoded = json.decode(raw) as List;
    final items = decoded
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
    return items;
  }
}

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalTransactionDataSource local;
  TransactionRepositoryImpl(this.local);

  @override
  Future<void> add(TransactionEntity tx) => local.add(TransactionModel.fromEntity(tx));

  @override
  Future<List<TransactionEntity>> loadAll() => local.loadAll();
}
