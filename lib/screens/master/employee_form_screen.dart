import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user.dart';
import '../../state/auth_state.dart';

/// Form tambah/ubah karyawan (Admin). Password hanya wajib saat menambah.
class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, this.employee});

  final Employee? employee;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nik;
  late final TextEditingController _name;
  late final TextEditingController _position;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _username;
  final _password = TextEditingController();

  bool _active = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;

    _nik = TextEditingController(text: employee?.nik ?? '');
    _name = TextEditingController(text: employee?.name ?? '');
    _position = TextEditingController(text: employee?.position ?? '');
    _phone = TextEditingController(text: employee?.phone ?? '');
    _address = TextEditingController(text: employee?.address ?? '');
    _username = TextEditingController(text: employee?.username ?? '');
    _active = employee?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final controller in [_nik, _name, _position, _phone, _address, _username, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final services = context.read<AuthState>().services;
    final body = <String, dynamic>{
      'nik': _nik.text.trim(),
      'name': _name.text.trim(),
      'position': _position.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'is_active': _active,
      'username': _username.text.trim(),
    };

    if (_password.text.isNotEmpty) {
      body['password'] = _password.text;
    } else if (!_isEdit) {
      body['password'] = '';
    }

    try {
      if (_isEdit) {
        await services.updateEmployee(widget.employee!.id, body);
      } else {
        await services.createEmployee(body);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Karyawan' : 'Tambah Karyawan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: appText(size: 12.5, color: AppColors.danger)),
              ),
              const SizedBox(height: 14),
            ],
            _label('NIK'),
            TextFormField(
              controller: _nik,
              decoration: const InputDecoration(hintText: 'EMP-003'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'NIK wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            _label('NAMA LENGKAP'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'Nama karyawan'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            _label('JABATAN'),
            TextFormField(
              controller: _position,
              decoration: const InputDecoration(hintText: 'Teknisi Advertising'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Jabatan wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            _label('NO. TELEPON'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
            ),
            const SizedBox(height: 14),
            _label('ALAMAT'),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Alamat karyawan'),
            ),
            const SizedBox(height: 20),
            Text('AKUN LOGIN', style: labelText()),
            const SizedBox(height: 8),
            _label('USERNAME'),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(hintText: 'username_karyawan'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            _label(_isEdit ? 'PASSWORD BARU (OPSIONAL)' : 'PASSWORD'),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: _isEdit ? 'Kosongkan bila tidak diganti' : 'Minimal 6 karakter',
              ),
              validator: (v) {
                if (!_isEdit && (v == null || v.length < 6)) return 'Password minimal 6 karakter';
                if (v != null && v.isNotEmpty && v.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: Text('Akun aktif', style: appText(size: 14, weight: FontWeight.w600)),
              subtitle: Text('Karyawan nonaktif tidak bisa login',
                  style: appText(size: 11.5, color: AppColors.muted)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Karyawan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: labelText(color: AppColors.inkMuted)),
      );
}
