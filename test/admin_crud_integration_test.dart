import 'package:app_advertising_mobile/core/api_client.dart';
import 'package:app_advertising_mobile/services/api_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Uji CRUD Admin end-to-end terhadap API nyata (toko → karyawan → SPK → slip).
/// Data uji dibuat lalu dihapus lagi di akhir.
///
///   php artisan serve --host=127.0.0.1 --port=8000
///   flutter test test/admin_crud_integration_test.dart --run-skipped
void main() {
  const baseUrl = 'http://127.0.0.1:8000';

  test('admin bisa CRUD lengkap: toko, karyawan, SPK, slip', () async {
    final client = ApiClient(baseUrl: baseUrl);
    final services = ApiServices(client);

    final session = await services.login('admin_utama', 'password123');
    client.token = session.token;
    services.role = session.user.role;

    final stamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    String? shopId, employeeId, spkId, payrollId;

    try {
      // 1. Toko
      final shop = await services.createShop({
        'code': 'UJI-$stamp',
        'name': 'Toko Uji $stamp',
        'owner_name': 'Pemilik Uji',
        'status': 'Aktif',
      });
      shopId = shop.id;
      expect(shop.code, 'UJI-$stamp');

      // 2. Karyawan (sekaligus akun login)
      final employee = await services.createEmployee({
        'nik': 'UJI-$stamp',
        'name': 'Karyawan Uji $stamp',
        'position': 'Teknisi Uji',
        'username': 'uji_$stamp',
        'password': 'rahasia123',
        'is_active': true,
      });
      employeeId = employee.id;
      expect(employee.name, contains('Karyawan Uji'));

      // 3. SPK
      final spk = await services.createSpk({
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'shop_id': shopId,
        'employee_id': employeeId,
        'job_name': 'Neon Box Uji $stamp',
        'spk_value': 1000000,
        'job_status': 'Belum Dikerjakan',
        'payment_status': 'Belum Dibayar',
      });
      spkId = spk.id;
      expect(spk.spkNumber, startsWith('SPK-'));

      // 4. Preview gaji: 1.000.000 - 3% = 970.000, komisi 22% = 213.400
      final preview = await services.payrollPreview({'spk_id': spkId, 'period': '2026-10'});
      expect(double.parse('${preview['gross_salary']}'), closeTo(213400, 0.01));
      expect(double.parse('${preview['net_salary']}'), closeTo(213400, 0.01));

      // 5. Simpan slip
      final payroll = await services.createPayroll({'spk_id': spkId, 'period': '2026-10'});
      payrollId = payroll.id;
      expect(payroll.slipNumber, startsWith('SLIP-'));
      expect(payroll.netSalary, closeTo(213400, 0.01));

      // 6. Tandai dibayar → SPK ikut berubah
      final paid = await services.markPaid(payrollId, paymentDate: '2026-10-17');
      expect(paid.paymentStatus, 'Sudah Dibayar');

      final spkAfterPaid = await services.spk(spkId);
      expect(spkAfterPaid.paymentStatus, 'Sudah Dibayar');
      expect(spkAfterPaid.jobStatus, 'Selesai');

      // 7. Notifikasi slip terbit untuk karyawan uji (bukan admin)
      //    Cek lewat akun karyawan tersebut.
      final karyawanClient = ApiClient(baseUrl: baseUrl);
      final karyawanServices = ApiServices(karyawanClient);
      final karyawanSession = await karyawanServices.login('uji_$stamp', 'rahasia123');
      karyawanClient.token = karyawanSession.token;
      karyawanServices.role = karyawanSession.user.role;

      final slips = await karyawanServices.payrolls();
      expect(slips.length, 1);
      expect(slips.first.id, payrollId);

      // 8. Bersihkan: hapus slip → SPK kembali, lalu hapus SPK, karyawan, toko
      await services.deletePayroll(payrollId);
      payrollId = null;

      final spkAfterDelete = await services.spk(spkId);
      expect(spkAfterDelete.jobStatus, 'Belum Dikerjakan');
      expect(spkAfterDelete.paymentStatus, 'Belum Dibayar');

      await services.deleteSpk(spkId);
      spkId = null;

      await services.deleteEmployee(employeeId);
      employeeId = null;

      await services.deleteShop(shopId);
      shopId = null;
    } finally {
      // Pastikan data uji tidak tertinggal bila ada langkah yang gagal.
      if (payrollId != null) {
        try {
          await services.deletePayroll(payrollId);
        } catch (_) {}
      }
      if (spkId != null) {
        try {
          await services.deleteSpk(spkId);
        } catch (_) {}
      }
      if (employeeId != null) {
        try {
          await services.deleteEmployee(employeeId);
        } catch (_) {}
      }
      if (shopId != null) {
        try {
          await services.deleteShop(shopId);
        } catch (_) {}
      }
    }
  }, skip: 'Butuh API lokal: jalankan dengan --run-skipped');
}
