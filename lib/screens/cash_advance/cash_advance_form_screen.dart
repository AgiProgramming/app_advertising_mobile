import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user.dart';
import '../../state/auth_state.dart';

/// Form catat kasbon karyawan (Admin).
class CashAdvanceFormScreen extends StatefulWidget {
  const CashAdvanceFormScreen({super.key});

  @override
  State<CashAdvanceFormScreen> createState() => _CashAdvanceFormScreenState();
}

class _CashAdvanceFormScreenState extends State<CashAdvanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  DateTime _date = DateTime.now();
  String? _employeeId;
  List<Employee> _employees = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final employees = await context.read<AuthState>().services.employees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _employeeId = employees.isNotEmpty ? employees.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_employeeId == null) {
      setState(() => _error = 'Pilih karyawan terlebih dahulu.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<AuthState>().services.createCashAdvance({
        'employee_id': _employeeId,
        'amount': double.tryParse(_amount.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      });

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
      appBar: AppBar(title: const Text('Catat Kasbon')),
      body: _loading
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
                  Text('KARYAWAN', style: labelText(color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _employeeId,
                    isExpanded: true,
                    items: [
                      for (final employee in _employees)
                        DropdownMenuItem(
                          value: employee.id,
                          child: Text('${employee.name} · ${employee.position}',
                              style: appText(size: 13), overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) => setState(() => _employeeId = value),
                  ),
                  const SizedBox(height: 14),
                  Text('NOMINAL (Rp)', style: labelText(color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '100000'),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Nominal harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('TANGGAL', style: labelText(color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
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
                            child: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date), style: appText(size: 14)),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('KETERANGAN (OPSIONAL)', style: labelText(color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _description,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Keperluan kasbon'),
                  ),
                  const SizedBox(height: 12),
                  Text('Kasbon akan dipotong otomatis dari slip gaji berikutnya, maksimal sebesar sisa utang.',
                      style: appText(size: 11, color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Kasbon'),
                  ),
                ],
              ),
            ),
    );
  }
}
