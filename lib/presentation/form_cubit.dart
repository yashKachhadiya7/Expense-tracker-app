import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../transactions/domain.dart';


class TransactionFormState extends Equatable {
  final TransactionType type;
  final DateTime date;
  final String category; // key

  const TransactionFormState({
    required this.type,
    required this.date,
    required this.category,
  });

  TransactionFormState copyWith({
    TransactionType? type,
    DateTime? date,
    String? category,
  }) =>
      TransactionFormState(
        type: type ?? this.type,
        date: date ?? this.date,
        category: category ?? this.category,
      );

  @override
  List<Object?> get props => [type, date, category];
}

class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit({required TransactionType initialType})
      : super(TransactionFormState(
    type: initialType,
    date: DateTime.now(),
    category: initialType == TransactionType.income ? 'salary' : 'uncategorized',
  ));

  void setType(TransactionType t) {
    final defaultCat = t == TransactionType.income ? 'salary' : 'uncategorized';
    emit(state.copyWith(type: t, category: defaultCat));
  }

  void setDate(DateTime d) => emit(state.copyWith(date: d));
  void setCategory(String key) => emit(state.copyWith(category: key));
}
