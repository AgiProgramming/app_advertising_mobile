import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payroll.dart';
import '../../state/auth_state.dart';
import '../../widgets/ui.dart';

/// Detail slip (surface: inspect) — dibuat seperti struk: mono, garis
/// putus-putus, total bergaris ganda, dan QR verifikasi.
class SlipDetailScreen extends StatefulWidget {
  const SlipDetailScreen({super.key, required this.payrollId});

  final String payrollId;

  @override
  State<SlipDetailScreen> createState() => _SlipDetailScreenState();
}

class _SlipDetailScreenState extends State<SlipDetailScreen> {
  Payroll? _payroll;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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

  String get _shareText {
    final payroll = _payroll;
    if (payroll == null) return '';

    return '''
SLIP GAJI - MANN PLUS ADVERTISING
${payroll.slipNumber} · ${Formats.period(payroll.period)}
Nama: ${payroll.employeeName ?? '-'} (${payroll.employeeNik ?? '-'})
Pekerjaan: ${payroll.jobName ?? '-'}

Nilai SPK: ${Formats.rupiahExact(payroll.originalSpkValue)}
PPN 3%: -${Formats.rupiahExact(payroll.ppnAmount)}
Nilai bersih: ${Formats.rupiahExact(payroll.netSpkValue)}
Komisi ${payroll.salaryPercentage.toStringAsFixed(0)}%: ${Formats.rupiahExact(payroll.grossSalary)}
Tunjangan makan: ${Formats.rupiahExact(payroll.mealAllowance)}
Potongan kasbon: -${Formats.rupiahExact(payroll.cashAdvanceDeduction)}

GAJI BERSIH: ${Formats.rupiahExact(payroll.netSalary)}
Status: ${payroll.paymentStatus}
${payroll.verifyUrl != null ? '\nVerifikasi: ${payroll.verifyUrl}' : ''}
''';
  }

  Future<void> _shareText_() async {
    final payroll = _payroll;
    if (payroll == null) return;

    await SharePlus.instance.share(ShareParams(
      text: _shareText,
      subject: 'Slip ${payroll.slipNumber}',
    ));
  }

  Future<void> _downloadPdf() async {
    final payroll = _payroll;
    if (payroll == null || _downloading) return;

    setState(() => _downloading = true);

    try {
      final bytes = await context.read<AuthState>().services.payrollPdf(payroll.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/slip-${payroll.slipNumber}.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Slip ${payroll.slipNumber}',
        text: 'Slip gaji ${Formats.period(payroll.period)}',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunduh slip: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payroll = _payroll;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slip Gaji'),
        actions: [
          if (payroll != null)
            IconButton(onPressed: _shareText_, icon: const Icon(Icons.ios_share_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    children: [
                      _SlipPaper(payroll: payroll!),
                      const SizedBox(height: 10),
                      Text(
                        'Pindai QR untuk memverifikasi keaslian slip · ${payroll.slipNumber}',
                        textAlign: TextAlign.center,
                        style: appText(size: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: payroll == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareText_,
                        icon: const Icon(Icons.ios_share_rounded, size: 16),
                        label: const Text('Bagikan'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _downloading ? null : _downloadPdf,
                        icon: _downloading
                            ? const SizedBox(
                                width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download_rounded, size: 16),
                        label: Text(_downloading ? 'Menyiapkan…' : 'Unduh PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SlipPaper extends StatelessWidget {
  const _SlipPaper({required this.payroll});

  final Payroll payroll;

  static TextStyle get _mono => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11.5,
        height: 1.7,
        color: AppColors.ink,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  TextStyle get _monoMuted => _mono.copyWith(color: AppColors.muted, fontSize: 10.5);

  @override
  Widget build(BuildContext context) {
    final commission = payroll.salaryPercentage % 1 == 0
        ? payroll.salaryPercentage.toStringAsFixed(0)
        : payroll.salaryPercentage.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text('MANN PLUS ADVERTISING',
                  textAlign: TextAlign.center,
                  style: appText(size: 12, weight: FontWeight.w800, letterSpacing: 1.4)),
              const SizedBox(height: 3),
              Text('Neon Box · Billboard · Media Promosi\nJl. Cirebon — Jawa Barat',
                  textAlign: TextAlign.center, style: _monoMuted.copyWith(height: 1.5)),
            ],
          ),
          const _DashedDivider(),
          _MetaRow(label: 'No. Slip', value: payroll.slipNumber),
          _MetaRow(label: 'Periode', value: Formats.period(payroll.period)),
          _MetaRow(label: 'Tanggal', value: Formats.dateFromIso(payroll.createdAt?.toIso8601String())),
          const SizedBox(height: 6),
          _MetaRow(label: 'Nama', value: payroll.employeeName ?? '-'),
          _MetaRow(label: 'NIK', value: payroll.employeeNik ?? '-'),
          _MetaRow(label: 'Jabatan', value: payroll.employeePosition ?? '-'),
          _MetaRow(label: 'Pekerjaan', value: payroll.jobName ?? '-'),
          const _DashedDivider(),
          _MetaRow(label: 'Nilai SPK', value: Formats.amount(payroll.originalSpkValue)),
          _MetaRow(label: 'PPN 3%', value: '-${Formats.amount(payroll.ppnAmount)}'),
          _MetaRow(label: 'Nilai bersih', value: Formats.amount(payroll.netSpkValue)),
          const _DashedDivider(),
          _MetaRow(label: 'Komisi $commission%', value: Formats.amount(payroll.grossSalary)),
          _MetaRow(label: 'Tunjangan makan', value: Formats.amount(payroll.mealAllowance)),
          _MetaRow(label: 'Potongan kasbon', value: '-${Formats.amount(payroll.cashAdvanceDeduction)}'),
          const SizedBox(height: 8),
          Container(height: 3, decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.borderStrong),
              bottom: BorderSide(color: AppColors.borderStrong),
            ),
          )),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('GAJI BERSIH',
                    style: appText(size: 10, weight: FontWeight.w700, color: AppColors.inkMuted, letterSpacing: 0.8)),
              ),
              Money(Formats.amount(payroll.netSalary), size: 19, weight: FontWeight.w800),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusBadge.payment(payroll.paymentStatus),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payroll.paymentDate != null ? Formats.dateFromIso(payroll.paymentDate) : '',
                  style: _monoMuted,
                ),
              ),
            ],
          ),
          const _DashedDivider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Slip ini dibuat otomatis oleh sistem penggajian Mann Plus Advertising.',
                  style: _monoMuted.copyWith(fontSize: 9, height: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              if (payroll.verifyUrl != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: QrImageView(
                    data: payroll.verifyUrl!,
                    size: 58,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      height: 1.7,
      color: AppColors.ink,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style.copyWith(color: AppColors.inkMuted, fontSize: 10.5))),
        const SizedBox(width: 10),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: style.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 4.0;
          const dashSpace = 3.0;
          final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(width: dashWidth, height: 1, color: AppColors.borderStrong),
            ),
          );
        },
      ),
    );
  }
}
