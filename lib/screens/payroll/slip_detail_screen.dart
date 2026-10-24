import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/payroll.dart';
import '../../state/auth_state.dart';

/// Detail slip gaji: rincian bagian dari setiap SPK, potongan, dan gaji bersih.
class SlipDetailScreen extends StatefulWidget {
  const SlipDetailScreen({super.key, required this.payrollId});

  final String payrollId;

  @override
  State<SlipDetailScreen> createState() => _SlipDetailScreenState();
}

class _SlipDetailScreenState extends State<SlipDetailScreen> {
  Payroll? _payroll;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final payroll = await context.read<AuthState>().services.payroll(widget.payrollId);
      if (!mounted) return;
      setState(() {
        _payroll = payroll;
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

  Future<void> _markPaid() async {
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().services.markPaid(widget.payrollId);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await context.read<AuthState>().services.payrollPdf(widget.payrollId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF slip siap (${(bytes.lengthInBytes / 1024).toStringAsFixed(0)} KB).')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _period(String period) {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(DateTime.parse('$period-01'));
    } catch (_) {
      return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Slip')),
      body: _loading
          ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : _content(_payroll!),
    );
  }

  Widget _content(Payroll p) {
    final negative = p.netSalary < 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SLIP GAJI', style: labelText(color: AppColors.muted)),
                        const SizedBox(height: 3),
                        Text(_period(p.period), style: appText(size: 16, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.isPaid ? AppColors.successSoft : AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.paymentStatus,
                      style: appText(
                        size: 11,
                        weight: FontWeight.w600,
                        color: p.isPaid ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _row('No. Slip', p.slipNumber, mono: true),
              _row('Nama', p.employeeName ?? '-'),
              _row('NIK', p.employeeNik ?? '-'),
              _row('Jumlah SPK', '${p.spkCount} pekerjaan'),
              if (p.paymentDate != null) _row('Dibayar', p.paymentDate!),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('RINCIAN SPK', style: labelText(color: AppColors.inkMuted)),
        const SizedBox(height: 8),
        if (p.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('Slip lama tanpa rincian per SPK.', style: appText(size: 12.5, color: AppColors.muted)),
          )
        else
          for (final item in p.items) _itemCard(item),
        const SizedBox(height: 16),
        Text('PERHITUNGAN', style: labelText(color: AppColors.inkMuted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _row('Bagian kotor', _rp.format(p.grossShare)),
              _row('PPN ${_pct(p.ppnRate)}%', '-${_rp.format(p.ppnAmount)}', danger: true),
              _row('Komisi ${_pct(p.commissionRate)}%', '-${_rp.format(p.commissionAmount)}', danger: true),
              _row('Uang makan (${p.mealCount} SPK)', '-${_rp.format(p.mealDeduction)}', danger: true),
              if (p.cashAdvanceDeduction > 0)
                _row('Potongan kasbon', '-${_rp.format(p.cashAdvanceDeduction)}', danger: true),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(child: Text('GAJI BERSIH', style: labelText(color: AppColors.ink))),
                  Text(
                    _rp.format(p.netSalary),
                    style: appText(
                      size: 19,
                      weight: FontWeight.w800,
                      color: negative ? AppColors.danger : AppColors.ink,
                    ),
                  ),
                ],
              ),
              if (negative) ...[
                const SizedBox(height: 8),
                Text(
                  'Hasil minus: potongan melebihi bagian karyawan pada periode ini.',
                  style: appText(size: 11.5, color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _downloadPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: (_busy || p.isPaid) ? null : _markPaid,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(p.isPaid ? 'Sudah Dibayar' : 'Tandai Dibayar'),
              ),
            ),
          ],
        ),
        if (p.verifyUrl != null) ...[
          const SizedBox(height: 12),
          Text(
            'Verifikasi: ${p.verifyUrl}',
            style: appText(size: 10.5, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  String _pct(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  Widget _itemCard(PayrollItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.shortNumber,
                  style: appText(size: 13, weight: FontWeight.w700),
                ),
              ),
              Text(_rp.format(item.shareAmount), style: appText(size: 13.5, weight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          if (item.jobName != null) ...[
            const SizedBox(height: 2),
            Text(item.jobName!, style: appText(size: 11.5, color: AppColors.muted)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _chip('Nilai SPK', _rp.format(item.spkValue)),
              _chip('Orang', '${item.slotCount}'),
              _chip('Hari', '${item.daysWorked}/${item.durationDays}'),
              _chip('Per hari', _rp.format(item.dailyRate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: appText(size: 9, color: AppColors.muted, weight: FontWeight.w600)),
          Text(value, style: appText(size: 11.5, weight: FontWeight.w600)),
        ],
      );

  Widget _row(String label, String value, {bool mono = false, bool danger = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: appText(size: 12.5, color: AppColors.inkMuted))),
            Text(
              value,
              style: appText(
                size: mono ? 11.5 : 12.5,
                weight: FontWeight.w600,
                color: danger ? AppColors.danger : AppColors.ink,
              ),
            ),
          ],
        ),
      );
}
