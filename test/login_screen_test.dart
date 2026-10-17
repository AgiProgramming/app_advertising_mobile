import 'package:app_advertising_mobile/core/theme.dart';
import 'package:app_advertising_mobile/screens/login_screen.dart';
import 'package:app_advertising_mobile/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('layar login tampil penuh di ukuran HP tanpa overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Elemen kunci harus ada.
    expect(find.text('Slip gaji\ndi tangan lo.'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    // Tidak boleh ada RenderFlex overflow / error layout.
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol masuk menampilkan pesan bila field kosong', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });
}
