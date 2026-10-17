import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/spk.dart';
import '../../state/auth_state.dart';
import '../../widgets/ui.dart';
import '../shell_screen.dart';
import '../payroll/payroll_create_screen.dart';
import 'spk_form_screen.dart';

/// Daftar SPK / tugas. Untuk karyawan hanya berisi SPK yang ditugaskan ke dia.
class SpkListScreen extends StatefulWidget {
  const SpkListScreen({super.key});

  @override
  State<SpkListScreen> createState() => _SpkListScreenState();
}

class _SpkListScreenState extends State<SpkListScreen> {
  List<Spk> _items = const [];
  bool _loading = true;
  String? _error;
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });

    try {
      final items = await context.read<AuthState>().services.spks();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<Spk> get _filtered => switch (_filter) {
        'jalan' => _items.where((item) => !item.isDone).toList(),
        'selesai' => _items.where((item) => item.isDone).toList(),
        _ => _items,
      };

  @override
  Widget build(BuildContext context) {
    final isKaryawan = context.watch<AuthState>().role == 'Karyawan';

    return Scaffold(
      appBar: AppBarWithNotifications(title: isKaryawan ? 'Tugas Saya' : 'Surat Perintah Kerja'),
      floatingActionButton: isKaryawan
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const SpkFormScreen()),
                );
                if (changed == true) _load();
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 18),
              label: Text('SPK', style: appText(size: 13, weight: FontWeight.w700, color: Colors.white)),
            ),
      body: AsyncContent(
        loading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _items.isEmpty,
        emptyMessage: isKaryawan ? 'Belum ada SPK yang ditugaskan ke Anda.' : 'Belum ada SPK.',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _Chip(label: 'Semua', active: _filter == 'semua', onTap: () => setState(() => _filter = 'semua')),
                  const SizedBox(width: 8),
                  _Chip(label: 'Berjalan', active: _filter == 'jalan', onTap: () => setState(() => _filter = 'jalan')),
                  const SizedBox(width: 8),
                  _Chip(label: 'Selesai', active: _filter == 'selesai', onTap: () => setState(() => _filter = 'selesai')),
                ],
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const EmptyState(message: 'Tidak ada SPK pada filter ini.', icon: Icons.filter_alt_off_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final spk = _filtered[index];

                          return AppCard(
                            onTap: () => _showDetail(spk),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(spk.jobName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: appText(size: 14, weight: FontWeight.w600, height: 1.35)),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(spk.jobStatus),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${spk.spkNumber} · ${Formats.dateFromIso(spk.date)}',
                                    style: appText(size: 11.5, color: AppColors.muted)),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('TOKO', style: labelText().copyWith(fontSize: 9.5)),
                                          const SizedBox(height: 2),
                                          Text(spk.shopName ?? '-',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: appText(size: 12.5, weight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('NILAI SPK', style: labelText().copyWith(fontSize: 9.5)),
                                        const SizedBox(height: 2),
                                        Money(Formats.amount(spk.spkValue), size: 13.5),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Spk spk) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
            ),
            Text(spk.jobName, style: appText(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(spk.spkNumber, style: appText(size: 12, color: AppColors.muted)),
            const SizedBox(height: 14),
            _DetailLine(label: 'Toko', value: spk.shopName ?? '-'),
            _DetailLine(label: 'Karyawan', value: spk.employeeName ?? 'Belum ditugaskan'),
            _DetailLine(label: 'Tanggal', value: Formats.dateFromIso(spk.date)),
            _DetailLine(label: 'Status pekerjaan', value: spk.jobStatus),
            _DetailLine(label: 'Status bayar', value: spk.paymentStatus),
            _DetailLine(label: 'Nilai SPK', value: Formats.rupiahExact(spk.spkValue)),
            if ((spk.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('DESKRIPSI', style: labelText()),
              const SizedBox(height: 4),
              Text(spk.description!, style: appText(size: 13, height: 1.5, color: AppColors.inkMuted)),
            ],
            const SizedBox(height: 16),
            if (context.read<AuthState>().role != 'Karyawan') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final changed = await Navigator.of(this.context).push<bool>(
                          MaterialPageRoute(builder: (_) => SpkFormScreen(spk: spk)),
                        );
                        if (changed == true) _load();
                      },
                      child: const Text('Ubah SPK'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(this.context).push(
                          MaterialPageRoute(builder: (_) => PayrollCreateScreen(spkId: spk.id)),
                        );
                      },
                      child: const Text('Buat slip'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: appText(size: 12.5, color: AppColors.muted))),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: appText(size: 12.5, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? const Color(0xFFC7D2FE) : AppColors.border),
        ),
        child: Text(label,
            style: appText(
                size: 12, weight: FontWeight.w600, color: active ? AppColors.primary : AppColors.inkMuted)),
      ),
    );
  }
}
