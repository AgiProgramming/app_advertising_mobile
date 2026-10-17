import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/spk.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../../state/auth_state.dart';

/// Form tambah/ubah SPK (Admin).
class SpkFormScreen extends StatefulWidget {
  const SpkFormScreen({super.key, this.spk});

  final Spk? spk;

  @override
  State<SpkFormScreen> createState() => _SpkFormScreenState();
}

class _SpkFormScreenState extends State<SpkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jobName;
  late final TextEditingController _value;
  late final TextEditingController _description;

  DateTime _date = DateTime.now();
  String? _shopId;
  String? _employeeId;
  String _jobStatus = 'Belum Dikerjakan';
  String _paymentStatus = 'Belum Dibayar';

  List<Shop> _shops = const [];
  List<Employee> _employees = const [];
  bool _loadingRefs = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.spk != null;

  @override
  void initState() {
    super.initState();
    final spk = widget.spk;

    _jobName = TextEditingController(text: spk?.jobName ?? '');
    _value = TextEditingController(text: spk == null ? '' : spk.spkValue.toStringAsFixed(0));
    _description = TextEditingController(text: spk?.description ?? '');

    if (spk != null) {
      _date = DateTime.tryParse(spk.date) ?? DateTime.now();
      _shopId = spk.shopId;
      _employeeId = spk.employeeId;
      _jobStatus = spk.jobStatus;
      _paymentStatus = spk.paymentStatus;
    }

    _loadReferences();
  }

  @override
  void dispose() {
    _jobName.dispose();
    _value.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final services = context.read<AuthState>().services;
      final shops = await services.shops();
      final employees = await services.employees();

      if (!mounted) return;
      setState(() {
        _shops = shops;
        _employees = employees;
        _shopId ??= shops.isNotEmpty ? shops.first.id : null;
        _loadingRefs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar toko/karyawan: $e';
        _loadingRefs = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shopId == null) {
      setState(() => _error = 'Pilih toko terlebih dahulu.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final services = context.read<AuthState>().services;
    final body = <String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'shop_id': _shopId,
      'employee_id': _employeeId,
      'job_name': _jobName.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'spk_value': double.tryParse(_value.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
      'job_status': _jobStatus,
      'payment_status': _paymentStatus,
    };

    try {
      if (_isEdit) {
        await services.updateSpk(widget.spk!.id, body);
      } else {
        await services.createSpk(body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Ubah SPK' : 'Tambah SPK')),
      body: _loadingRefs
          ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          : Form(
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
                  _label('TANGGAL'),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                                style: appText(size: 14)),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('TOKO'),
                  DropdownButtonFormField<String>(
                    initialValue: _shopId,
                    items: [
                      for (final shop in _shops)
                        DropdownMenuItem(value: shop.id, child: Text(shop.name, style: appText(size: 14))),
                    ],
                    onChanged: (value) => setState(() => _shopId = value),
                    decoration: const InputDecoration(hintText: 'Pilih toko'),
                  ),
                  const SizedBox(height: 14),
                  _label('KARYAWAN PELAKSANA'),
                  DropdownButtonFormField<String?>(
                    initialValue: _employeeId,
                    items: [
                      DropdownMenuItem(value: null, child: Text('Belum ditugaskan', style: appText(size: 14, color: AppColors.muted))),
                      for (final employee in _employees)
                        DropdownMenuItem(
                          value: employee.id,
                          child: Text('${employee.name} · ${employee.position}', style: appText(size: 14)),
                        ),
                    ],
                    onChanged: (value) => setState(() => _employeeId = value),
                  ),
                  const SizedBox(height: 14),
                  _label('NAMA PEKERJAAN'),
                  TextFormField(
                    controller: _jobName,
                    decoration: const InputDecoration(hintText: 'Neon Box — Toko Sinar Jaya'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pekerjaan wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  _label('NILAI SPK (Rp)'),
                  TextFormField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '1463763'),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Nilai SPK harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _label('DESKRIPSI (OPSIONAL)'),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Catatan pekerjaan'),
                  ),
                  const SizedBox(height: 14),
                  _label('STATUS PEKERJAAN'),
                  DropdownButtonFormField<String>(
                    initialValue: _jobStatus,
                    items: const ['Belum Dikerjakan', 'Sedang Dikerjakan', 'Selesai']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value, style: appText(size: 14))))
                        .toList(),
                    onChanged: (value) => setState(() => _jobStatus = value ?? _jobStatus),
                  ),
                  const SizedBox(height: 14),
                  _label('STATUS PEMBAYARAN'),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    items: const ['Belum Dibayar', 'Sudah Dibayar']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value, style: appText(size: 14))))
                        .toList(),
                    onChanged: (value) => setState(() => _paymentStatus = value ?? _paymentStatus),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah SPK'),
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
