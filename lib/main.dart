import 'package:expense_tracker/presentation/pages/home_page.dart';
import 'package:expense_tracker/presentation/transaction_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'transactions/domain.dart';
import 'transactions/data.dart';
import 'auth/auth_cubit.dart';
import 'auth/lock_screen.dart';
import 'theme/theme_cubit.dart'; // <— new

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final local = LocalTransactionDataSourceImpl();
  final repo = TransactionRepositoryImpl(local);

  final addTx = AddTransaction(repo);
  final loadTx = LoadTransactions(repo);

  runApp(App(addTx: addTx, loadTx: loadTx));
}

class App extends StatelessWidget {
  final AddTransaction addTx;
  final LoadTransactions loadTx;
  const App({super.key, required this.addTx, required this.loadTx});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TransactionBloc(addTx: addTx, loadTx: loadTx)..add(const TransactionStarted())),
        BlocProvider(create: (_) => AuthCubit()..init()),
        BlocProvider(create: (_) => ThemeCubit()..load()), // <— new
      ],
      child: BlocBuilder<ThemeCubit, AppThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3C7795)),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3C7795), brightness: Brightness.dark),
            ),
            themeMode: themeState.mode, // <— drives light/dark
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, s) {
        switch (s.status) {
          case AuthStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.needSetup:
          case AuthStatus.locked:
          case AuthStatus.error:
            return const LockScreen();
          case AuthStatus.unlocked:
            return const HomePage();
        }
      },
    );
  }
}
