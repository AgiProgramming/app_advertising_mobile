import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/cash_advance.dart';
import '../../state/auth_state.dart';
import '../../widgets/ui.dart';
import '../shell_screen.dart';

/// Daftar kasbon. Karyawan melihat kasbon miliknya, Admin melihat semua.
class CashAdvanceScreen extends StatefulWidget {
  const CashAdvanceScreen({super.key});

  @override
  State<CashAdvanceScreen> createState() => _CashAdvanceScreenState();
}

class _CashAdvanceScreenState extends State<CashAdvanceScreen> {
  List<CashAdvance> _items = const [];
  bool _loading = true;
  String? _error;

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
      final items = await context.read<AuthState>().services.cashAdvances();
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

  double get _total => _items.fold(0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthState>().role;

    return Scaffold(
      appBar: const AppBarWithNotifications(title: 'Kasbon'),
      body: AsyncContent(
        loading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _items.isEmpty,
        emptyMessage: 'Belum ada kasbon tercatat.',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL KASBON', style: labelText()),
                        const SizedBox(height: 6),
                        Money(Formats.amount(_total), size: 24, weight: FontWeight.w800),
                      ],
                    ),
                  ),
                  Text('${_items.length} catatan', style: appText(size: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('RIWAYAT', style: labelText()),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_items[i].description?.isNotEmpty == true
                                        ? _items[i].description!
                                        : 'Kasbon',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: appText(size: 13.5, weight: FontWeight.w600, height: 1.3)),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    Formats.dateFromIso(_items[i].date),
                                    if (role != 'Karyawan' && _items[i].employeeName != null) _items[i].employeeName!,
                                  ].join(' · '),
                                  style: appText(size: 11.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Money(Formats.amount(_items[i].amount), size: 14),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kasbon dipotong otomatis dari slip gaji berikutnya, maksimal sebesar sisa utang.',
              style: appText(size: 11, color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
