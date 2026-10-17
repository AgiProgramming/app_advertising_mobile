import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_advertising_mobile/core/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Formats', () {
    test('rupiah memakai format Indonesia tanpa desimal', () {
      expect(Formats.rupiah(212367), 'Rp 212.367');
    });

    test('rupiahExact menampilkan dua desimal seperti slip', () {
      expect(Formats.rupiahExact(212367.02), contains('212.367,02'));
    });

    test('period mengubah 2026-10 menjadi nama bulan', () {
      expect(Formats.period('2026-10'), 'Oktober 2026');
    });

    test('periodParts memberi nomor dan singkatan bulan', () {
      final (month, name) = Formats.periodParts('2026-08');
      expect(month, '08');
      expect(name.toLowerCase(), startsWith('agu'));
    });

    test('period aman untuk nilai kosong', () {
      expect(Formats.period(null), '-');
      expect(Formats.period(''), '-');
    });
  });
}
