import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/spk.dart';
import '../../state/auth_state.dart';
import '../../widgets/ui.dart';

/// Buat slip gaji dari SPK: hitung dulu (preview), baru simpan.
class PayrollCreateScreen extends StatefulWidget {
  const PayrollCreateScreen({super.key, this.spkId});

  final String? spkId;

  @override
  State<PayrollCreateScreen> createState() => _PayrollCreateScreenState();
}

class _PayrollCreateScreenState extends State<PayrollCreateScreen> {
  List<Spk> _spks = const [];
  String? _spkId;
  DateTime _period = DateTime.now();

  final _percentage = TextEditingController();
  final _meal = TextEditingController();
  final _deduction = TextEditingController();

  Map<String, dynamic>? _preview;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _spkId = widget.spkId;
    _load();
  }

  @override
  void dispose() {
    _percentage.dispose();
    _meal.dispose();
    _deduction.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final spks = await context.read<AuthState>().services.spks();
      if (!mounted) return;
      setState(() {
        _spks = spks;
        _spkId ??= spks.isNotEmpty ? spks.first.id : null;
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

  Map<String, dynamic> get _body {
    final body = <String, dynamic>{
      'spk_id': _spkId,
      'period': DateFormat('yyyy-MM').format(_period),
    };

    if (_percentage.text.trim().isNotEmpty) {
      body['salary_percentage'] = double.tryParse(_percentage.text.trim());
    }
    if (_meal.text.trim().isNotEmpty) {
      body['meal_allowance'] = double.tryParse(_meal.text.trim());
    }
    if (_deduction.text.trim().isNotEmpty) {
      body['cash_advance_deduction'] = double.tryParse(_deduction.text.trim());
    }

    return body;
  }

  Future<void> _hitung() async {
    if (_spkId == null) return;

    setState(() {
      _error = null;
      _preview = null;
    });

    try {
      final data = await context.read<AuthState>().services.payrollPreview(_body);
      if (mounted) setState(() => _preview = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _simpan() async {
    if (_preview == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<AuthState>().services.createPayroll(_body);
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
      appBar: AppBar(title: const Text('Buat Slip Gaji')),
      body: _loading
          ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: appText(size: 12.5, color: AppColors.danger, height: 1.4)),
                  ),
                  const SizedBox(height: 14),
                ],
                Text('SPK', style: labelText(color: AppColors.inkMuted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _spkId,
                  isExpanded: true,
                  items: [
                    for (final spk in _spks)
                      DropdownMenuItem(
                        value: spk.id,
                        child: Text('${spk.spkNumber} · ${spk.jobName}', style: appText(size: 13), overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _spkId = value;
                    _preview = null;
                  }),
                  decoration: const InputDecoration(hintText: 'Pilih SPK'),
                ),
                const SizedBox(height: 14),
                Text('PERIODE GAJI', style: labelText(color: AppColors.inkMuted)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _period,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      helpText: 'Pilih bulan & tahun',
                    );
                    if (picked != null) {
                      setState(() {
                        _period = picked;
                        _preview = null;
                      });
                    }
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
                        Expanded(child: Text(Formats.period(DateFormat('yyyy-MM').format(_period)), style: appText(size: 14))),
                        const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KOMISI (%)', style: labelText(color: AppColors.inkMuted)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _percentage,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '22'),
                            onChanged: (_) => setState(() => _preview = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UANG MAKAN', style: labelText(color: AppColors.inkMuted)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _meal,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0'),
                            onChanged: (_) => setState(() => _preview = null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('POTONGAN KASBON (OPSIONAL)', style: labelText(color: AppColors.inkMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: _deduction,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Kosongkan untuk potong otomatis'),
                  onChanged: (_) => setState(() => _preview = null),
                ),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _hitung, child: const Text('Hitung')),
                if (_preview != null) ...[
                  const SizedBox(height: 18),
                  _PreviewCard(data: _preview!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _simpan,
                    child: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Slip'),
                  ),
                ],
              ],
            ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.data});

  final Map<String, dynamic> data;

  double _value(String key) => double.tryParse('${data[key] ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Perhitungan', style: appText(size: 14, weight: FontWeight.w700))),
              StatusBadge('${data['salary_percentage'] ?? 0}%', tone: StatusTone.neutral, dot: false),
            ],
          ),
          const SizedBox(height: 10),
          _row('Nilai SPK', _value('original_spk_value')),
          _row('PPN 3%', -_value('ppn_amount')),
          _row('Nilai bersih', _value('net_spk_value')),
          const Divider(height: 18),
          _row('Komisi', _value('gross_salary')),
          _row('Tunjangan makan', _value('meal_allowance')),
          _row('Potongan kasbon', -_value('cash_advance_deduction')),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Text('GAJI BERSIH',
                      style: appText(size: 10, weight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6)),
                ),
                Money(Formats.amount(_value('net_salary')), size: 17, weight: FontWeight.w800),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Sisa kasbon setelah potong: ${Formats.rupiah(_value('remaining_cash_advance'))}',
              style: appText(size: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: appText(size: 12.5, color: AppColors.inkMuted))),
          Text(
            Formats.amount(value.abs()),
            style: appText(size: 12.5, weight: FontWeight.w600, color: value < 0 ? AppColors.danger : AppColors.ink),
          ),
        ],
      ),
    );
  }
}
