import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../services/api_services.dart';
import 'push_service.dart';

/// Menyimpan sesi login (token + profil) dan menjadi sumber kebenaran
/// untuk routing berdasarkan role.
class AuthState extends ChangeNotifier {
  AuthState() {
    client = ApiClient();
    client.onUnauthorized = _forceLogout;
    services = ApiServices(client);
  }

  static const _tokenKey = 'auth_token';

  late final ApiClient client;
  late final ApiServices services;

  AppUser? user;
  String? token;
  bool initializing = true;
  bool submitting = false;
  String? error;

  bool get isLoggedIn => token != null && user != null;
  String get role => user?.role ?? '';

  /// Dipanggil sekali saat aplikasi dibuka.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);

    if (saved == null || saved.isEmpty) {
      initializing = false;
      notifyListeners();
      return;
    }

    token = saved;
    client.token = saved;

    try {
      user = await services.profile();
      services.role = user!.role;
      await PushService.instance.attach(services);
    } catch (_) {
      token = null;
      client.token = null;
      await prefs.remove(_tokenKey);
    }

    initializing = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    submitting = true;
    error = null;
    notifyListeners();

    try {
      final result = await services.login(username.trim(), password);

      token = result.token;
      user = result.user;
      services.role = result.user.role;
      client.token = result.token;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result.token);

      await PushService.instance.attach(services);

      submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      submitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Terjadi kesalahan. Coba lagi.';
      submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await PushService.instance.detach(services);
    await services.logout();

    token = null;
    user = null;
    client.token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    notifyListeners();
  }

  /// Sesi berakhir (401) — bersihkan tanpa memanggil API lagi.
  void _forceLogout() {
    if (token == null) return;

    token = null;
    user = null;
    client.token = null;
    error = 'Sesi Anda berakhir. Silakan masuk kembali.';

    SharedPreferences.getInstance().then((prefs) => prefs.remove(_tokenKey));
    notifyListeners();
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }
}
