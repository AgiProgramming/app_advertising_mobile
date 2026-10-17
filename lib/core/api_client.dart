import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Kesalahan API yang sudah diterjemahkan ke pesan siap tampil.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidation => statusCode == 422;

  @override
  String toString() => message;
}

/// Pembungkus HTTP: menempelkan token, mengubah error jadi [ApiException],
/// dan memberi tahu aplikasi ketika sesi berakhir (401).
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  String? token;
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;

    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((key, value) => MapEntry(key, '$value')),
    });
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(
        () => http.post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        () => http.put(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  Future<dynamic> patch(String path, {Object? body}) => _send(
        () => http.patch(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  Future<dynamic> delete(String path, {Object? body}) => _send(
        () => http.delete(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)),
      );

  /// Unduh berkas biner (dipakai untuk PDF slip gaji).
  Future<Uint8List> download(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: {
            if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
          })
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }

      if (response.statusCode == 401) onUnauthorized?.call();

      throw ApiException(
        _messageFrom(response.body) ?? 'Gagal mengunduh berkas.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Server terlalu lama merespons. Coba lagi.');
    }
  }

  Future<dynamic> _send(Future<http.Response> Function() run) async {
    http.Response response;

    try {
      response = await run().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Server terlalu lama merespons. Coba lagi.');
    } on HandshakeException {
      throw ApiException('Koneksi aman ke server gagal.');
    }

    final status = response.statusCode;
    final body = _decode(response.body);

    if (status >= 200 && status < 300) return body;

    if (status == 401) {
      onUnauthorized?.call();
      throw ApiException(
        (body is Map && body['message'] is String) ? body['message'] as String : 'Sesi berakhir. Silakan masuk lagi.',
        statusCode: status,
      );
    }

    throw ApiException(
      _messageFrom(response.body) ?? 'Permintaan gagal (kode $status).',
      statusCode: status,
      errors: body is Map && body['errors'] is Map ? Map<String, dynamic>.from(body['errors'] as Map) : null,
    );
  }

  String? _messageFrom(String raw) {
    final decoded = _decode(raw);
    if (decoded is Map && decoded['message'] is String) {
      final message = decoded['message'] as String;
      final errors = decoded['errors'];

      // Tampilkan pesan validasi pertama agar lebih konkret daripada "The given data was invalid".
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }

      return message;
    }
    return null;
  }

  dynamic _decode(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }
}
