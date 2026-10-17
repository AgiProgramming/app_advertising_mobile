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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..restore()),
        // NotificationState harus berada DI ATAS MaterialApp, bukan di dalam
        // halaman, supaya layar yang dibuka lewat Navigator.push (Notifikasi,
        // Kasbon, detail slip) tetap bisa membacanya.
        ChangeNotifierProxyProvider<AuthState, NotificationState>(
          create: (context) => NotificationState(context.read<AuthState>().services),
          update: (context, auth, previous) => previous ?? NotificationState(auth.services),
        ),
      ],
      child: MaterialApp(
        title: 'Mann Plus Payroll',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _lastUserId;

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

    if (!auth.isLoggedIn) {
      _lastUserId = null;
      return const LoginScreen();
    }

    // Muat notifikasi sekali setiap kali pengguna (re)login.
    if (_lastUserId != auth.user!.id) {
      _lastUserId = auth.user!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<NotificationState>().refresh();
      });
    }

    return const ShellScreen();
  }
}
