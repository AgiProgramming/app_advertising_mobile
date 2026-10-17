import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/api_services.dart';
import '../../state/auth_state.dart';

/// Form tambah/ubah toko (Admin).
class ShopFormScreen extends StatefulWidget {
  const ShopFormScreen({super.key, this.shop});

  final Shop? shop;

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _owner;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  String _status = 'Aktif';
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.shop != null;

  @override
  void initState() {
    super.initState();
    final shop = widget.shop;

    _code = TextEditingController(text: shop?.code ?? '');
    _name = TextEditingController(text: shop?.name ?? '');
    _owner = TextEditingController(text: shop?.ownerName ?? '');
    _phone = TextEditingController(text: shop?.phone ?? '');
    _address = TextEditingController(text: shop?.address ?? '');
    _status = shop?.status ?? 'Aktif';
  }

  @override
  void dispose() {
    for (final controller in [_code, _name, _owner, _phone, _address]) {
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
      'code': _code.text.trim(),
      'name': _name.text.trim(),
      'owner_name': _owner.text.trim().isEmpty ? null : _owner.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'status': _status,
    };

    try {
      if (_isEdit) {
        await services.updateShop(widget.shop!.id, body);
      } else {
        await services.createShop(body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Toko' : 'Tambah Toko')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: appText(size: 12.5, color: AppColors.danger)),
              ),
              const SizedBox(height: 14),
            ],
            Text('KODE TOKO', style: labelText(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(hintText: 'TKO-001'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Text('NAMA TOKO', style: labelText(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'Toko Sinar Jaya'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Text('NAMA PEMILIK', style: labelText(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            TextFormField(controller: _owner, decoration: const InputDecoration(hintText: 'Nama pemilik')),
            const SizedBox(height: 14),
            Text('NO. TELEPON', style: labelText(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
            ),
            const SizedBox(height: 14),
            Text('ALAMAT', style: labelText(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Alamat toko'),
            ),
            const SizedBox(height: 14),
            Text('STATUS', style: labelText(color: AppColors.inkMuted)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final status in ['Aktif', 'Nonaktif']) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _status = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _status == status ? AppColors.primarySoft : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _status == status ? const Color(0xFFC7D2FE) : AppColors.border,
                          ),
                        ),
                        child: Text(
                          status,
                          style: appText(
                            size: 13,
                            weight: FontWeight.w600,
                            color: _status == status ? AppColors.primary : AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (status == 'Aktif') const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Toko'),
            ),
          ],
        ),
      ),
    );
  }
}
