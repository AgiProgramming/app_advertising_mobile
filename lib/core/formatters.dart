import 'package:intl/intl.dart';

class Formats {
  static final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _currencyDecimal = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);
  static final _decimal = NumberFormat('#,##0.00', 'id_ID');
  static final _date = DateFormat('dd MMM yyyy', 'id_ID');

  /// Rp 212.367 (dipakai di kartu ringkas).
  static String rupiah(num? value) => _currency.format(value ?? 0);

  /// Rp 212.367,02 (dipakai di slip).
  static String rupiahExact(num? value) => _currencyDecimal.format(value ?? 0);

  /// 212.367,02 tanpa simbol (untuk baris rincian slip).
  static String amount(num? value) => _decimal.format(value ?? 0);

  static String date(DateTime? value) => value == null ? '-' : _date.format(value);

  static String dateFromIso(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? '-' : _date.format(parsed.toLocal());
  }

  /// "2026-10" -> "Oktober 2026"
  static String period(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse('$value-01');
    if (parsed == null) return value;
    return DateFormat('MMMM yyyy', 'id_ID').format(parsed);
  }

  /// "2026-10" -> ("10", "Okt") untuk blok tanggal di daftar slip.
  static (String, String) periodParts(String? value) {
    final parsed = DateTime.tryParse('${value ?? ''}-01');
    if (parsed == null) return ('-', '-');
    return (
      DateFormat('MM').format(parsed),
      DateFormat('MMM', 'id_ID').format(parsed),
    );
  }

  /// 2.367 -> "2,4 rb" (untuk label kecil, bila diperlukan).
  static String compact(num value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)} M';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} rb';
    return value.toStringAsFixed(0);
  }

  /// Waktu relatif singkat untuk notifikasi.
  static String timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
    if (diff.inHours < 24) return '${diff.inHours} jam';
    if (diff.inDays == 1) return 'kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari';
    return _date.format(time);
  }
}
