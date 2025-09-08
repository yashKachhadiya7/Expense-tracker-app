part of 'theme_cubit.dart';

class AppThemeState extends Equatable {
  final ThemeMode mode;
  const AppThemeState({required this.mode});

  @override
  List<Object?> get props => [mode];
}
