import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'state/auth_state.dart';
import 'state/notification_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data locale Indonesia wajib dimuat sebelum DateFormat dipakai.
  await initializeDateFormatting('id_ID');

  // Firebase dipakai untuk notifikasi slip gaji. Kalau konfigurasi belum ada,
  // aplikasi tetap berjalan (fitur lain tidak ikut mati).
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase belum siap: $error');
  }

  runApp(const MannPlusApp());
}

class MannPlusApp extends StatelessWidget {
  const MannPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState()..restore(),
      child: MaterialApp(
        title: 'Mann Plus Payroll',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.initializing) {
      return const Scaffold(
        backgroundColor: AppColors.shell,
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    if (!auth.isLoggedIn) return const LoginScreen();

    return ChangeNotifierProvider(
      key: ValueKey(auth.user?.id),
      create: (_) => NotificationState(auth.services)..refresh(),
      child: const ShellScreen(),
    );
  }
}
