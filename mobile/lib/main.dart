import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/finance_provider.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/home_shell.dart';

void main() {
  runApp(const PfmsApp());
}

class PfmsApp extends StatelessWidget {
  const PfmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FinanceProvider>(
          create: (ctx) => FinanceProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, previous) => previous ?? FinanceProvider(auth.api),
        ),
      ],
      child: MaterialApp(
        title: 'PFMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF6C5CE7), useMaterial3: true),
        home: const _StartupGate(),
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();
  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _checked = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryAutoLogin().then((ok) {
      if (mounted) setState(() { _checked = true; _loggedIn = ok; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const HomeShell() : const LoginScreen();
  }
}
