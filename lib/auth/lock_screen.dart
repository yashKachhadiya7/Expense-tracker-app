import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';
import 'pin_form_cubit.dart';

const _kAccent = Color(0xFF6A3BFF);
const _kPadBg = Color(0xFFE9DDFE); // light lavender for keypad zone

// ------------------------------- PUBLIC SCREEN -------------------------------

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, s) {
        final msg = s.error;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.loading:
            return _PurpleScaffold(
              title: '',
              content: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              // keypad: null  // no keypad on loading
            );

          case AuthStatus.needSetup:
            return _SetupPinScreen(); // this screen supplies its own keypad via _PurpleScaffold

          case AuthStatus.locked:
            return _UnlockPinScreen(
              showBiometric: state.hasBiometrics && state.biometricsEnabled,
            ); // also supplies keypad

          case AuthStatus.unlocked:
            return const SizedBox.shrink();

          case AuthStatus.error:
            return _PurpleScaffold(
              title: 'Security',
              content: const Center(
                child: Text('Something went wrong',
                    style: TextStyle(color: Colors.white)),
              ),
              // keypad: null
            );
        }
      },

    );
  }
}

// ------------------------------- SETUP (2 STEP) ------------------------------

enum _SetupStage { enter, confirm }

class _SetupState extends Equatable {
  final _SetupStage stage;
  final String input; // current 0..4
  const _SetupState({required this.stage, required this.input});
  _SetupState copyWith({_SetupStage? stage, String? input}) =>
      _SetupState(stage: stage ?? this.stage, input: input ?? this.input);
  @override
  List<Object?> get props => [stage, input];
}

class _SetupCubit extends Cubit<_SetupState> {
  final PinFormCubit form;
  final AuthCubit auth;
  _SetupCubit({required this.form, required this.auth})
      : super(const _SetupState(stage: _SetupStage.enter, input: ''));

  void tapDigit(String d) {
    if (state.input.length >= 4) return;
    final next = state.input + d;
    emit(state.copyWith(input: next));
    if (next.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (state.stage == _SetupStage.enter) {
          form.setPin(next);
          emit(state.copyWith(stage: _SetupStage.confirm, input: ''));
        } else {
          form.setConfirm(next);
          if (form.state.pin == form.state.confirm) {
            auth.setPin(pin: form.state.pin, enableBiometrics: false);
          } else {
            // mismatch -> keep confirm stage, clear input and show error via auth state
            auth.emit(auth.state.copyWith(error: 'PINs do not match'));
            emit(state.copyWith(input: ''));
          }
        }
      });
    }
  }

  void backspace() {
    if (state.input.isEmpty) return;
    emit(state.copyWith(input: state.input.substring(0, state.input.length - 1)));
  }
}

class _SetupPinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PinFormCubit(),
      child: Builder(
        builder: (context) {
          final form = context.read<PinFormCubit>();
          final auth = context.read<AuthCubit>();
          return BlocProvider(
            create: (_) => _SetupCubit(form: form, auth: auth),
            child: BlocBuilder<_SetupCubit, _SetupState>(
              builder: (context, s) {
                final title = s.stage == _SetupStage.enter
                    ? "Let's  setup your PIN"
                    : 'Ok. Re type your PIN again.';
                return _PurpleScaffold(
                  title: s.stage == _SetupStage.enter
                      ? "Let's  setup your PIN"
                      : 'Ok. Re type your PIN again.',
                  content: Column(
                    children: [
                      const SizedBox(height: 24),
                      _PinDots(count: s.input.length),   // ⟵ here are the dots
                      const Spacer(),
                    ],
                  ),
                  keypad: _PinKeypad(
                    onDigit: (d) => context.read<_SetupCubit>().tapDigit(d),
                    onBackspace: () => context.read<_SetupCubit>().backspace(),
                  ),
                );

              },
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------- UNLOCK ----------------------------------

class _UnlockState extends Equatable {
  final String input; // 0..4
  const _UnlockState(this.input);
  @override
  List<Object?> get props => [input];
}

class _UnlockCubit extends Cubit<_UnlockState> {
  final AuthCubit auth;
  _UnlockCubit(this.auth) : super(const _UnlockState(''));

  void tapDigit(String d) {
    if (state.input.length >= 4) return;
    final next = state.input + d;
    emit(_UnlockState(next));
    if (next.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () async {
        await auth.unlockWithPin(next);
        emit(const _UnlockState(''));
      });
    }
  }

  void backspace() {
    if (state.input.isEmpty) return;
    emit(_UnlockState(state.input.substring(0, state.input.length - 1)));
  }
}

class _UnlockPinScreen extends StatelessWidget {
  final bool showBiometric;
  const _UnlockPinScreen({required this.showBiometric});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _UnlockCubit(context.read<AuthCubit>()),
      child: BlocBuilder<_UnlockCubit, _UnlockState>(
        builder: (context, s) {
          return _PurpleScaffold(
            title: 'Enter PIN to unlock',
            trailing: showBiometric
                ? IconButton(
              onPressed: () => context.read<AuthCubit>().unlockWithBiometrics(),
              icon: const Icon(Icons.fingerprint, color: Colors.white),
            )
                : null,
            content: Column(
              children: [
                const SizedBox(height: 28),
                _PinDots(count: s.input.length),
                const Spacer(),
              ],
            ),
            keypad: _PinKeypad(
              onDigit: (d) => context.read<_UnlockCubit>().tapDigit(d),
              onBackspace: () => context.read<_UnlockCubit>().backspace(),
            ),
          );
        },
      ),
    );
  }
}


// --------------------------------- WIDGETS -----------------------------------

class _PurpleScaffold extends StatelessWidget {
  final String title;
  final Widget content;   // top content (title area, dots, etc.)
  final Widget? keypad;   // optional: show numeric keypad at bottom
  final Widget? trailing;

  const _PurpleScaffold({
    required this.title,
    required this.content,
    this.keypad,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAccent,
      appBar: AppBar(
        backgroundColor: _kAccent,
        elevation: 0,
        centerTitle: true,
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: trailing != null ? [trailing!] : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: content,
      ),
      bottomNavigationBar:
      keypad == null ? null : _KeypadContainer(child: keypad!),
    );
  }
}


/// Dot indicators (4): filled for entered digits, outlined for remaining.
class _PinDots extends StatelessWidget {
  final int count; // 0..4
  const _PinDots({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 22,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: filled ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
          ),
        );
      }),
    );
  }
}


/// Hosts the keypad; kept separate so _PurpleScaffold can add the gradient footer.
class _KeypadContainer extends StatelessWidget {
  final Widget child;
  const _KeypadContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // thin gradient seam like your mock
        Container(
          height: 12,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kAccent, _kPadBg],
            ),
          ),
        ),
        ColoredBox(
          color: _kPadBg,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}


/// iOS-like numeric keypad (white rounded keys).
class _PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _PinKeypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    // Map letter subtitles like iOS keypad
    const subs = {
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      'sym': '+*#',
    };

    final rows = <List<_KeySpec>>[
      [_KeySpec('1'), _KeySpec('2', sub: subs['2']), _KeySpec('3', sub: subs['3'])],
      [_KeySpec('4', sub: subs['4']), _KeySpec('5', sub: subs['5']), _KeySpec('6', sub: subs['6'])],
      [_KeySpec('7', sub: subs['7']), _KeySpec('8', sub: subs['8']), _KeySpec('9', sub: subs['9'])],
      [_KeySpec('sym', sub: subs['sym'], enabled: false), _KeySpec('0'), const _KeySpec.back()],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            children: row.map((k) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: _PadButton(
                    label: k.label,
                    sub: k.sub,
                    enabled: k.enabled,
                    isBack: k.isBack,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (k.isBack) {
                        onBackspace();
                      } else if (k.enabled) {
                        onDigit(k.label);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _KeySpec {
  final String label;
  final String? sub;
  final bool enabled;
  final bool isBack;
  const _KeySpec(this.label, {this.sub, this.enabled = true, this.isBack = false});
  const _KeySpec.back()
      : label = '⌫',
        sub = null,
        enabled = true,
        isBack = true;
}

class _PadButton extends StatelessWidget {
  final String label;
  final String? sub;
  final bool enabled;
  final bool isBack;
  final VoidCallback onTap;

  const _PadButton({
    required this.label,
    this.sub,
    required this.enabled,
    required this.isBack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: light
                ? [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: isBack
                ? const Icon(Icons.backspace_outlined)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: Colors.black.withOpacity(0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

