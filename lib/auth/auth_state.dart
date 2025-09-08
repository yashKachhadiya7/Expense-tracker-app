part of 'auth_cubit.dart';

enum AuthStatus { loading, needSetup, locked, unlocked, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final bool hasBiometrics;
  final bool biometricsEnabled;
  final String? error;

  const AuthState({
    required this.status,
    required this.hasBiometrics,
    required this.biometricsEnabled,
    this.error,
  });

  const AuthState.loading()
      : status = AuthStatus.loading,
        hasBiometrics = false,
        biometricsEnabled = false,
        error = null;

  const AuthState._(
      this.status, this.hasBiometrics, this.biometricsEnabled, this.error);

  factory AuthState.needSetup({required bool hasBiometrics}) =>
      AuthState._(AuthStatus.needSetup, hasBiometrics, false, null);

  factory AuthState.locked({
    required bool hasBiometrics,
    required bool biometricsEnabled,
  }) =>
      AuthState._(AuthStatus.locked, hasBiometrics, biometricsEnabled, null);

  factory AuthState.unlocked({
    required bool hasBiometrics,
    required bool biometricsEnabled,
  }) =>
      AuthState._(AuthStatus.unlocked, hasBiometrics, biometricsEnabled, null);

  factory AuthState.error(String message) =>
      AuthState._(AuthStatus.error, false, false, message);

  AuthState copyWith({
    AuthStatus? status,
    bool? hasBiometrics,
    bool? biometricsEnabled,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        hasBiometrics: hasBiometrics ?? this.hasBiometrics,
        biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
        error: error,
      );

  @override
  List<Object?> get props => [status, hasBiometrics, biometricsEnabled, error];
}
