import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/cash_advance.dart';
import '../models/payroll.dart';
import '../models/spk.dart';
import '../models/user.dart';

/// Kumpulan service API. Path disesuaikan dengan role karena backend
/// memisahkan rute admin / owner / karyawan.
class ApiServices {
  ApiServices(this.client, {this.role = 'Admin'});

  final ApiClient client;
  String role;

  // ---------------------------------------------------------------- auth
  Future<({String token, AppUser user})> login(String username, String password) async {
    final data = await client.post('/api/login', body: {'username': username, 'password': password});

    if (data is! Map) throw ApiException('Respons login tidak dikenali.');

    return (
      token: '${data['access_token']}',
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<void> logout() async {
    try {
      await client.post('/api/logout');
    } catch (_) {
      // Token mungkin sudah dicabut; abaikan.
    }
  }

  Future<AppUser> profile() async {
    final data = await client.get('/api/profile');
    return AppUser.fromJson(Map<String, dynamic>.from((data as Map)['user'] as Map));
  }

  // ------------------------------------------------------------- payroll
  String get _payrollListPath => switch (role) {
        'Karyawan' => '/api/karyawan/payrolls',
        'Owner' => '/api/owner/payrolls',
        _ => '/api/payrolls',
      };

  String _payrollDetailPath(String id) => switch (role) {
        'Karyawan' => '/api/karyawan/payrolls/$id',
        'Owner' => '/api/owner/payrolls/$id',
        _ => '/api/payrolls/$id',
      };

  Future<List<Payroll>> payrolls({String? period, String? paymentStatus}) async {
    final query = <String, dynamic>{};
    if (period != null && period.isNotEmpty) query['period'] = period;
    if (paymentStatus != null && paymentStatus.isNotEmpty) query['payment_status'] = paymentStatus;

    final data = await client.get(_payrollListPath, query: query);

    return _listOf(data).map(Payroll.fromJson).toList();
  }

  Future<Payroll> payroll(String id) async {
    final data = await client.get(_payrollDetailPath(id));
    return Payroll.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<Uint8List> payrollPdf(String id) => client.download('/api/payrolls/$id/pdf');

  Future<Payroll> createPayroll(Map<String, dynamic> body) async {
    final data = await client.post('/api/payrolls', body: body);
    return Payroll.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  /// Pratinjau gaji satu karyawan pada satu periode (belum disimpan).
  Future<Map<String, dynamic>> previewPayroll(Map<String, dynamic> body) async {
    final data = await client.post('/api/payrolls/preview', body: body);
    return Map<String, dynamic>.from((data as Map)['data'] as Map);
  }

  /// Baca data SPK dari berkas PDF yang diunggah.
  Future<Map<String, dynamic>> parseSpkPdf(List<int> bytes, String filename) async {
    final data = await client.upload(
      '/api/spks/parse-pdf',
      field: 'file',
      bytes: bytes,
      filename: filename,
    );
    return Map<String, dynamic>.from((data as Map)['data'] as Map);
  }

  Future<Payroll> updatePayroll(String id, Map<String, dynamic> body) async {
    final data = await client.put('/api/payrolls/$id', body: body);
    return Payroll.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<Payroll> markPaid(String id, {String? paymentDate}) async {
    final body = <String, dynamic>{'payment_status': 'Sudah Dibayar'};
    if (paymentDate != null) body['payment_date'] = paymentDate;

    final data = await client.patch('/api/payrolls/$id/payment', body: body);
    return Payroll.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<void> deletePayroll(String id) => client.delete('/api/payrolls/$id');

  Future<Map<String, dynamic>> payrollPreview(Map<String, dynamic> body) async {
    final data = await client.post('/api/payrolls/preview', body: body);
    return Map<String, dynamic>.from((data as Map)['data'] as Map);
  }

  // ----------------------------------------------------------------- spk
  String get _spkPath => switch (role) {
        'Karyawan' => '/api/karyawan/spks',
        'Owner' => '/api/owner/spks',
        _ => '/api/spks',
      };

  Future<List<Spk>> spks({String? employeeId}) async {
    final query = <String, dynamic>{};
    if (employeeId != null && employeeId.isNotEmpty) query['employee_id'] = employeeId;

    final data = await client.get(_spkPath, query: query);
    return _listOf(data).map(Spk.fromJson).toList();
  }

  Future<Spk> spk(String id) async {
    final data = await client.get('/api/spks/$id');
    return Spk.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<Spk> createSpk(Map<String, dynamic> body) async {
    final data = await client.post('/api/spks', body: body);
    return Spk.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<Spk> updateSpk(String id, Map<String, dynamic> body) async {
    final data = await client.put('/api/spks/$id', body: body);
    return Spk.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<void> deleteSpk(String id) => client.delete('/api/spks/$id');

  // -------------------------------------------------------- cash advance
  Future<List<CashAdvance>> cashAdvances() async {
    final path = role == 'Karyawan' ? '/api/karyawan/cash-advances' : '/api/cash-advances';
    final data = await client.get(path);
    return _listOf(data).map(CashAdvance.fromJson).toList();
  }

  Future<double> cashAdvanceTotal(String employeeId) async {
    final data = await client.get('/api/employees/$employeeId/cash-advances-total');
    return double.tryParse('${(data as Map)['total_cash_advance']}') ?? 0;
  }

  Future<CashAdvance> createCashAdvance(Map<String, dynamic> body) async {
    final data = await client.post('/api/cash-advances', body: body);
    return CashAdvance.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<void> deleteCashAdvance(String id) => client.delete('/api/cash-advances/$id');

  // ------------------------------------------------------------- employee
  Future<List<Employee>> employees() async {
    final data = await client.get('/api/employees');
    return _listOf(data).map((json) => Employee.fromJson(json)).toList();
  }

  Future<Employee> createEmployee(Map<String, dynamic> body) async {
    final data = await client.post('/api/employees', body: body);
    return Employee.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<Employee> updateEmployee(String id, Map<String, dynamic> body) async {
    final data = await client.put('/api/employees/$id', body: body);
    return Employee.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<void> deleteEmployee(String id) => client.delete('/api/employees/$id');

  // ---------------------------------------------------------------- shop
  Future<List<Shop>> shops() async {
    final data = await client.get('/api/shops');
    return _listOf(data).map(Shop.fromJson).toList();
  }

  Future<Shop> createShop(Map<String, dynamic> body) async {
    final data = await client.post('/api/shops', body: body);
    return Shop.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<Shop> updateShop(String id, Map<String, dynamic> body) async {
    final data = await client.put('/api/shops/$id', body: body);
    return Shop.fromJson(Map<String, dynamic>.from((data as Map)['data'] as Map));
  }

  Future<void> deleteShop(String id) => client.delete('/api/shops/$id');

  // ----------------------------------------------------------- dashboard
  Future<Map<String, dynamic>> dashboard({String? period}) async {
    final path = switch (role) {
      'Karyawan' => '/api/karyawan/dashboard',
      'Owner' => '/api/owner/dashboard',
      _ => '/api/admin/dashboard',
    };

    final data = await client.get(path, query: {
      if (period != null && period.isNotEmpty) 'period': period,
    });

    return Map<String, dynamic>.from((data as Map)['data'] as Map);
  }

  // -------------------------------------------------------- notification
  Future<({List<AppNotification> items, int unread})> notifications() async {
    final data = await client.get('/api/notifications') as Map;
    final items = _listOf(data).map(AppNotification.fromJson).toList();

    return (items: items, unread: int.tryParse('${data['unread_count']}') ?? 0);
  }

  Future<int> markNotificationRead(String id) async {
    final data = await client.patch('/api/notifications/$id/read') as Map;
    return int.tryParse('${data['unread_count']}') ?? 0;
  }

  Future<void> markAllNotificationsRead() => client.post('/api/notifications/read-all');

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) =>
      client.post('/api/device-token', body: {'token': token, 'platform': platform});

  Future<void> removeDeviceToken(String token) =>
      client.delete('/api/device-token', body: {'token': token});

  // ---------------------------------------------------------------- util
  List<Map<String, dynamic>> _listOf(dynamic data) {
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is List) {
      return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return const [];
  }
}

class Shop {
  const Shop({
    required this.id,
    required this.code,
    required this.name,
    this.ownerName,
    this.phone,
    this.address,
    this.status = 'Aktif',
  });

  final String id;
  final String code;
  final String name;
  final String? ownerName;
  final String? phone;
  final String? address;
  final String status;

  bool get isActive => status == 'Aktif';

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: '${json['id']}',
      code: '${json['code'] ?? '-'}',
      name: '${json['name'] ?? '-'}',
      ownerName: json['owner_name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      status: '${json['status'] ?? 'Aktif'}',
    );
  }
}
