import 'dart:convert';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_state.dart';


class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.loading());

  static const _kHash = 'secure_pin_hash_v1';
  static const _kSalt = 'secure_pin_salt_v1';
  static const _kBioEnabled = 'secure_bio_enabled_v1';

  final _auth = LocalAuthentication();

  Future<void> init() async {
    try {
      emit(const AuthState.loading());
      final prefs = await SharedPreferences.getInstance();

      final has = prefs.getString(_kHash);
      final salt = prefs.getString(_kSalt);
      final bioEnabled = prefs.getBool(_kBioEnabled) ?? false;

      final canCheckBio = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();

      if (has == null || salt == null) {
        emit(AuthState.needSetup(
          hasBiometrics: canCheckBio && available.isNotEmpty,
        ));
        return;
      }

      emit(AuthState.locked(
        hasBiometrics: canCheckBio && available.isNotEmpty,
        biometricsEnabled: bioEnabled,
      ));
    } catch (e) {
      emit(AuthState.error('Auth init failed: $e'));
    }
  }

  Future<void> setPin({
    required String pin,
    required bool enableBiometrics,
  }) async {
    if (pin.length < 4) {
      emit(state.copyWith(error: 'PIN must be at least 4 digits'));
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saltBytes = _randomBytes(16);
      final hashBytes = _hash(pin, saltBytes);

      await prefs.setString(_kSalt, base64Encode(saltBytes));
      await prefs.setString(_kHash, base64Encode(hashBytes));
      await prefs.setBool(_kBioEnabled, enableBiometrics);

      final canCheckBio = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();

      emit(AuthState.locked(
        hasBiometrics: canCheckBio && available.isNotEmpty,
        biometricsEnabled: enableBiometrics,
      ));
    } catch (e) {
      emit(AuthState.error('Failed to set PIN: $e'));
    }
  }

  Future<void> unlockWithPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saltB64 = prefs.getString(_kSalt);
      final hashB64 = prefs.getString(_kHash);
      if (saltB64 == null || hashB64 == null) {
        emit(AuthState.error('PIN not set.'));
        return;
      }

      final salt = base64Decode(saltB64);
      final expected = base64Decode(hashB64);
      final candidate = _hash(pin, salt);

      final match = _constTimeEquals(expected, candidate);
      if (match) {
        emit(AuthState.unlocked(
          hasBiometrics: state.hasBiometrics,
          biometricsEnabled: state.biometricsEnabled,
        ));
      } else {
        emit(state.copyWith(error: 'Incorrect PIN'));
      }
    } catch (e) {
      emit(AuthState.error('Unlock failed: $e'));
    }
  }

  Future<void> unlockWithBiometrics() async {
    try {
      if (!state.biometricsEnabled) {
        emit(state.copyWith(error: 'Biometrics not enabled'));
        return;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok) {
        emit(AuthState.unlocked(
          hasBiometrics: state.hasBiometrics,
          biometricsEnabled: state.biometricsEnabled,
        ));
      } else {
        emit(state.copyWith(error: 'Biometric auth canceled'));
      }
    } catch (e) {
      emit(AuthState.error('Biometric auth failed: $e'));
    }
  }

  Future<void> lock() async {
    emit(AuthState.locked(
      hasBiometrics: state.hasBiometrics,
      biometricsEnabled: state.biometricsEnabled,
    ));
  }

  // Utils
  List<int> _randomBytes(int len) {
    final r = Random.secure();
    return List<int>.generate(len, (_) => r.nextInt(256));
  }

  List<int> _hash(String pin, List<int> salt) {
    final bytes = <int>[];
    bytes.addAll(salt);
    bytes.addAll(utf8.encode(pin));
    return sha256.convert(bytes).bytes;
  }

  bool _constTimeEquals(List<int> a, List<int> b) {
    var diff = 0;
    for (var i = 0; i < a.length || i < b.length; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      diff |= ai ^ bi;
    }
    return diff == 0;
  }
}
