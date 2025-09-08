import 'package:equatable/equatable.dart';
import '../core/usecase.dart';

enum TransactionType { income, expense }

/// Domain stays Flutter-free; we store a category key (string).
class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final TransactionType type;
  final String category; // e.g., 'salary', 'groceries'

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.type,
    required this.category,
  });

  @override
  List<Object?> get props => [id, amount, note, date, type, category];
}

/// Repository contract
abstract interface class TransactionRepository {
  Future<void> add(TransactionEntity tx);
  Future<List<TransactionEntity>> loadAll();
}

/// Use cases
class AddTransaction implements UseCase<void, TransactionEntity> {
  final TransactionRepository repo;
  AddTransaction(this.repo);
  @override
  Future<void> call(TransactionEntity params) => repo.add(params);
}

class LoadTransactions implements UseCase<List<TransactionEntity>, NoParams> {
  final TransactionRepository repo;
  LoadTransactions(this.repo);
  @override
  Future<List<TransactionEntity>> call(NoParams params) => repo.loadAll();
}
