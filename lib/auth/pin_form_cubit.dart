import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class PinFormState extends Equatable {
  final String pin;
  final String confirm;
  final bool enableBiometrics;

  const PinFormState({
    this.pin = '',
    this.confirm = '',
    this.enableBiometrics = false,
  });

  PinFormState copyWith({String? pin, String? confirm, bool? enableBiometrics}) =>
      PinFormState(
        pin: pin ?? this.pin,
        confirm: confirm ?? this.confirm,
        enableBiometrics: enableBiometrics ?? this.enableBiometrics,
      );

  @override
  List<Object?> get props => [pin, confirm, enableBiometrics];
}

class PinFormCubit extends Cubit<PinFormState> {
  PinFormCubit() : super(const PinFormState());

  void setPin(String v) => emit(state.copyWith(pin: v));
  void setConfirm(String v) => emit(state.copyWith(confirm: v));
  void toggleBiometrics(bool v) => emit(state.copyWith(enableBiometrics: v));
}
