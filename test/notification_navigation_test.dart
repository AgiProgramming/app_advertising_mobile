import 'package:app_advertising_mobile/core/theme.dart';
import 'package:app_advertising_mobile/screens/notifications/notification_screen.dart';
import 'package:app_advertising_mobile/state/auth_state.dart';
import 'package:app_advertising_mobile/state/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Regresi: layar yang dibuka lewat Navigator.push (di luar subtree halaman)
/// harus tetap bisa membaca NotificationState. Dulu provider-nya diletakkan di
/// dalam MaterialApp sehingga muncul ProviderNotFoundException.
void main() {
  testWidgets('NotificationScreen bisa dibuka lewat Navigator.push', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthState()),
          ChangeNotifierProxyProvider<AuthState, NotificationState>(
            create: (context) => NotificationState(context.read<AuthState>().services),
            update: (context, auth, previous) => previous ?? NotificationState(auth.services),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ),
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pump(); // mulai transisi
    await tester.pump(const Duration(milliseconds: 400));

    // Tidak boleh ada ProviderNotFoundException.
    expect(tester.takeException(), isNull);
    expect(find.text('Notifikasi'), findsOneWidget);
  });
}
