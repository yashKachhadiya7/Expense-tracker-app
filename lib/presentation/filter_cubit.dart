import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class FilterState extends Equatable {
  /// month: 1..12 or null (All months)
  final int? month;
  /// year: e.g., 2024 or null (All years)
  final int? year;

  const FilterState({this.month, this.year});

  bool get isAll => month == null && year == null;

  FilterState copyWith({int? month, int? year}) =>
      FilterState(month: month, year: year);

  @override
  List<Object?> get props => [month, year];
}

class FilterCubit extends Cubit<FilterState> {
  /// Defaults to "All time" (month/year null).
  FilterCubit() : super(const FilterState());

  void setMonth(int? m) => emit(state.copyWith(month: m, year: state.year));
  void setYear(int? y) => emit(state.copyWith(month: state.month, year: y));
  void clear() => emit(const FilterState());
}
