import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payroll.dart';
import '../../state/auth_state.dart';
import '../../widgets/ui.dart';
import '../shell_screen.dart';
import 'slip_detail_screen.dart';

/// Daftar slip gaji (surface: compare) — dikelompokkan per tahun.
class SlipListScreen extends StatefulWidget {
  const SlipListScreen({super.key});

  @override
  State<SlipListScreen> createState() => _SlipListScreenState();
}

class _SlipListScreenState extends State<SlipListScreen> {
  List<Payroll> _items = const [];
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
      final services = context.read<AuthState>().services;
      final items = await services.payrolls();

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

  List<Payroll> get _filtered => switch (_filter) {
        'belum' => _items.where((item) => !item.isPaid).toList(),
        'sudah' => _items.where((item) => item.isPaid).toList(),
        _ => _items,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithNotifications(title: 'Slip Gaji'),
      body: AsyncContent(
        loading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _items.isEmpty,
        emptyMessage: 'Belum ada slip gaji yang diterbitkan.',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(label: 'Semua', active: _filter == 'semua', onTap: () => setState(() => _filter = 'semua')),
                    const SizedBox(width: 8),
                    _Chip(
                        label: 'Belum dibayar',
                        active: _filter == 'belum',
                        onTap: () => setState(() => _filter = 'belum')),
                    const SizedBox(width: 8),
                    _Chip(
                        label: 'Sudah dibayar',
                        active: _filter == 'sudah',
                        onTap: () => setState(() => _filter = 'sudah')),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const EmptyState(message: 'Tidak ada slip pada filter ini.', icon: Icons.filter_alt_off_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: _buildGroups(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups() {
    final groups = <String, List<Payroll>>{};

    for (final item in _filtered) {
      final year = item.period.split('-').first;
      groups.putIfAbsent(year, () => []).add(item);
    }

    final years = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final widgets = <Widget>[];

    for (final year in years) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Text(year, style: labelText()),
      ));

      widgets.add(AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(
          children: [
            for (var i = 0; i < groups[year]!.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _SlipRow(
                payroll: groups[year]![i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SlipDetailScreen(payrollId: groups[year]![i].id)),
                ),
              ),
            ],
          ],
        ),
      ));
    }

    widgets.add(Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text('Menampilkan ${_filtered.length} dari ${_items.length} slip',
          textAlign: TextAlign.center, style: appText(size: 11, color: AppColors.muted)),
    ));

    return widgets;
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
        child: Text(
          label,
          style: appText(
            size: 12,
            weight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _SlipRow extends StatelessWidget {
  const _SlipRow({required this.payroll, required this.onTap});

  final Payroll payroll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (month, monthName) = Formats.periodParts(payroll.period);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              padding: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Text(month, style: appText(size: 15, weight: FontWeight.w700)),
                  Text(monthName.toUpperCase(),
                      style: appText(size: 10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payroll.jobName ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: appText(size: 13.5, weight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 2),
                  Text(payroll.slipNumber, style: appText(size: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Money(Formats.amount(payroll.netSalary), size: 14),
                const SizedBox(height: 4),
                StatusBadge.payment(payroll.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
