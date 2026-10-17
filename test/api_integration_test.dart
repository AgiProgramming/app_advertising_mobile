import 'package:app_advertising_mobile/core/api_client.dart';
import 'package:app_advertising_mobile/services/api_services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uji integrasi terhadap API Laravel yang benar-benar berjalan.
///
/// Sengaja di-skip pada `flutter test` biasa karena butuh server lokal:
///   php artisan serve --host=127.0.0.1 --port=8000
///   flutter test test/api_integration_test.dart --run-skipped
void main() {
  const baseUrl = 'http://127.0.0.1:8000';

  test('login + ambil data nyata dari API', () async {
    final client = ApiClient(baseUrl: baseUrl);
    final services = ApiServices(client);

    // 1. Login admin
    final session = await services.login('admin_utama', 'password123');
    expect(session.token, isNotEmpty);
    expect(session.user.role, 'Admin');

    client.token = session.token;
    services.role = session.user.role;

    // 2. Profil
    final profile = await services.profile();
    expect(profile.username, 'admin_utama');

    // 3. Dashboard admin
    final dashboard = await services.dashboard();
    expect(dashboard.containsKey('overview'), isTrue);
    expect(dashboard.containsKey('payroll'), isTrue);

    // 4. Daftar slip + parsing resource
    final payrolls = await services.payrolls();
    expect(payrolls, isNotEmpty);

    final slip = payrolls.first;
    expect(slip.slipNumber, startsWith('SLIP-'));
    expect(slip.netSalary, greaterThan(0));
    expect(slip.verifyUrl, isNotNull);
    expect(slip.employeeName, isNotNull);

    // 5. Detail slip
    final detail = await services.payroll(slip.id);
    expect(detail.id, slip.id);
    expect(detail.originalSpkValue, greaterThan(0));

    // 6. SPK
    final spks = await services.spks();
    expect(spks, isNotEmpty);
    expect(spks.first.spkNumber, startsWith('SPK-'));

    // 7. Kasbon & karyawan & toko
    final cashAdvances = await services.cashAdvances();
    expect(cashAdvances, isA<List>());

    final employees = await services.employees();
    expect(employees, isNotEmpty);

    final shops = await services.shops();
    expect(shops, isNotEmpty);

    // 8. Notifikasi
    final notifications = await services.notifications();
    expect(notifications.unread, greaterThanOrEqualTo(0));

    // 9. PDF slip benar-benar terunduh
    final pdf = await services.payrollPdf(slip.id);
    expect(pdf.length, greaterThan(1000));
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');

    // 10. Logout
    await services.logout();
  }, skip: 'Butuh API lokal: jalankan dengan --run-skipped');
}
