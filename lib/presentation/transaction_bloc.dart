import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/usecase.dart';
import '../transactions/domain.dart';


enum TransactionStatus { initial, loading, ready, failure }

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<TransactionEntity> items;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final String? error;

  const TransactionState({
    required this.status,
    required this.items,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.error,
  });

  const TransactionState.initial()
      : status = TransactionStatus.initial,
        items = const [],
        totalIncome = 0,
        totalExpense = 0,
        balance = 0,
        error = null;

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionEntity>? items,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    String? error,
  }) =>
      TransactionState(
        status: status ?? this.status,
        items: items ?? this.items,
        totalIncome: totalIncome ?? this.totalIncome,
        totalExpense: totalExpense ?? this.totalExpense,
        balance: balance ?? this.balance,
        error: error,
      );

  @override
  List<Object?> get props => [status, items, totalIncome, totalExpense, balance, error];
}

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class TransactionStarted extends TransactionEvent {
  const TransactionStarted();
}

class TransactionAdded extends TransactionEvent {
  final TransactionEntity item;
  const TransactionAdded(this.item);
  @override
  List<Object?> get props => [item];
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final AddTransaction addTx;
  final LoadTransactions loadTx;

  TransactionBloc({required this.addTx, required this.loadTx})
      : super(const TransactionState.initial()) {
    on<TransactionStarted>(_onStarted);
    on<TransactionAdded>(_onAdded);
  }

  Future<void> _onStarted(
      TransactionStarted event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    try {
      final items = await loadTx(const NoParams());
      emit(_withTotals(state.copyWith(status: TransactionStatus.ready, items: items)));
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure, error: '$e'));
    }
  }

  Future<void> _onAdded(
      TransactionAdded event, Emitter<TransactionState> emit) async {
    try {
      await addTx(event.item);
      final items = await loadTx(const NoParams());
      emit(_withTotals(state.copyWith(status: TransactionStatus.ready, items: items)));
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure, error: '$e'));
    }
  }

  TransactionState _withTotals(TransactionState s) {
    double inc = 0, exp = 0;
    for (final t in s.items) {
      if (t.type == TransactionType.income) {
        inc += t.amount;
      } else {
        exp += t.amount;
      }
    }
    return s.copyWith(
      totalIncome: inc,
      totalExpense: exp,
      balance: inc - exp,
    );
  }
}
