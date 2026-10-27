import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user.dart';
import '../../state/auth_state.dart';

/// Buat slip gaji: pilih karyawan + periode, sistem menjumlahkan bagiannya
/// dari semua SPK pada periode itu lalu menampilkan rincian sebelum disimpan.
class PayrollCreateScreen extends StatefulWidget {
  const PayrollCreateScreen({super.key, this.employeeId});

  final String? employeeId;

  @override
  State<PayrollCreateScreen> createState() => _PayrollCreateScreenState();
}

class _PayrollCreateScreenState extends State<PayrollCreateScreen> {
  final _kasbon = TextEditingController();

  List<Employee> _employees = const [];
  String? _employeeId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  bool _hitung = false;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _preview;

  final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);

  String get _period => DateFormat('yyyy-MM').format(_month);
  String get _periodLabel => DateFormat('MMMM yyyy', 'id_ID').format(_month);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _kasbon.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await context.read<AuthState>().services.employees();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _employeeId = widget.employeeId ?? (list.isNotEmpty ? list.first.id : null);
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

  Future<void> _runPreview() async {
    if (_employeeId == null) {
      setState(() => _error = 'Pilih karyawan terlebih dahulu.');
      return;
    }

    setState(() {
      _hitung = true;
      _error = null;
      _preview = null;
    });

    try {
      final body = <String, dynamic>{
        'employee_id': _employeeId,
        'period': _period,
        if (_kasbon.text.trim().isNotEmpty)
          'cash_advance_deduction': double.tryParse(_kasbon.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
      };
      final data = await context.read<AuthState>().services.previewPayroll(body);
      if (!mounted) return;
      setState(() => _preview = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _hitung = false);
    }
  }

  Future<void> _save() async {
    if (_preview == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'employee_id': _employeeId,
        'period': _period,
        if (_kasbon.text.trim().isNotEmpty)
          'cash_advance_deduction': double.tryParse(_kasbon.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
      };
      await context.read<AuthState>().services.createPayroll(body);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _preview = null;
    });
  }

  double _num(dynamic v) => v == null ? 0 : (double.tryParse('$v') ?? 0);

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
                    child: Text(_error!, style: appText(size: 12.5, color: AppColors.danger)),
                  ),
                  const SizedBox(height: 14),
                ],
                _label('KARYAWAN'),
                DropdownButtonFormField<String>(
                  initialValue: _employeeId,
                  isExpanded: true,
                  items: [
                    for (final e in _employees)
                      DropdownMenuItem(
                        value: e.id,
                        child: Text('${e.name} · ${e.position}', style: appText(size: 14)),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _employeeId = v;
                    _preview = null;
                  }),
                ),
                const SizedBox(height: 14),
                _label('PERIODE GAJI'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          _periodLabel,
                          textAlign: TextAlign.center,
                          style: appText(size: 14, weight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _label('POTONGAN KASBON (OPSIONAL)'),
                TextFormField(
                  controller: _kasbon,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Kosongkan untuk potong otomatis'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Uang makan Rp100.000 per SPK dipotong otomatis.',
                  style: appText(size: 11.5, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _hitung ? null : _runPreview,
                  icon: _hitung
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.calculate_outlined, size: 18),
                  label: Text(_hitung ? 'Menghitung…' : 'Hitung'),
                ),
                if (_preview != null) ...[
                  const SizedBox(height: 22),
                  _previewCard(_preview!),
                ],
              ],
            ),
      bottomNavigationBar: _preview == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Menyimpan…' : 'Simpan Slip'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
    );
  }

  Widget _previewCard(Map<String, dynamic> p) {
    final items = (p['items'] as List? ?? const []).whereType<Map>().toList();
    final net = _num(p['net_salary']);
    final negative = net < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('RINCIAN SPK', style: labelText(color: AppColors.inkMuted))),
            Text('${items.length} pekerjaan', style: appText(size: 11.5, color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Karyawan ini tidak punya SPK pada ${_periodLabel.toLowerCase()}.',
              style: appText(size: 12.5, color: AppColors.warning),
            ),
          )
        else
          for (final item in items) _itemTile(item),
        const SizedBox(height: 18),
        Text('PERHITUNGAN GAJI', style: labelText(color: AppColors.inkMuted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  children: [
                    _row('Bagian kotor', _rp.format(_num(p['gross_share']))),
                    _row('PPN ${_pct(p['ppn_rate'])}%', '-${_rp.format(_num(p['ppn_amount']))}', danger: true),
                    _row('Komisi ${_pct(p['commission_rate'])}%', '-${_rp.format(_num(p['commission_amount']))}', danger: true),
                    _row('Uang makan (${p['meal_count'] ?? 0} SPK)', '-${_rp.format(_num(p['meal_deduction']))}', danger: true),
                    if (_num(p['cash_advance_deduction']) > 0)
                      _row('Potongan kasbon', '-${_rp.format(_num(p['cash_advance_deduction']))}', danger: true),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: negative ? AppColors.dangerSoft : AppColors.primarySoft,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('GAJI BERSIH', style: labelText(color: AppColors.ink)),
                    ),
                    Text(
                      _rp.format(net),
                      style: appText(
                        size: 19,
                        weight: FontWeight.w800,
                        color: negative ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (negative)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Hasil minus — potongan melebihi bagian karyawan pada periode ini.',
              style: appText(size: 11.5, color: AppColors.danger),
            ),
          ),
      ],
    );
  }

  Widget _itemTile(Map item) {
    final number = '${item['spk_number'] ?? '-'}';
    final short = number.split('/').last;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(short, style: appText(size: 13, weight: FontWeight.w700))),
              Text(
                _rp.format(_num(item['share_amount'])),
                style: appText(size: 13, weight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nilai ${_rp.format(_num(item['spk_value']))} · ${item['slot_count']} orang · '
            '${item['days_worked']}/${item['duration_days']} hari',
            style: appText(size: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _pct(dynamic value) {
    final v = _num(value);
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  Widget _row(String label, String value, {bool danger = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: appText(size: 12.5, color: AppColors.inkMuted))),
            Text(
              value,
              style: appText(
                size: 12.5,
                weight: FontWeight.w600,
                color: danger ? AppColors.danger : AppColors.ink,
              ),
            ),
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: labelText(color: AppColors.inkMuted)),
      );
}
