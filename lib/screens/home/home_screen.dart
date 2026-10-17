import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/payroll.dart';
import '../../models/spk.dart';
import '../../state/auth_state.dart';
import '../../state/notification_state.dart';
import '../../widgets/ui.dart';
import '../payroll/slip_detail_screen.dart';
import '../payroll/slip_list_screen.dart';
import '../notifications/notification_screen.dart';
import '../spk/spk_list_screen.dart';

/// Beranda per role. Tiap varian menjawab satu pertanyaan utama:
/// karyawan "gaji saya berapa", admin "apa yang harus dikerjakan",
/// owner "bagaimana angka bulan ini".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;
  List<Spk> _recentSpk = const [];
  bool _loading = true;
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

    final auth = context.read<AuthState>();

    try {
      final data = await auth.services.dashboard();

      if (auth.role == 'Admin') {
        final spks = await auth.services.spks();
        _recentSpk = spks.take(3).toList();
      }

      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });

      // Segarkan badge notifikasi setiap kali beranda dibuka.
      context.read<NotificationState>().refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(auth.user?.initials ?? 'MP',
                  style: appText(size: 12, weight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(auth.user?.displayName ?? '-',
                    style: appText(size: 13, weight: FontWeight.w700, height: 1.2)),
                Text(
                  auth.role == 'Karyawan'
                      ? (auth.user?.employee?.position ?? 'Karyawan')
                      : auth.role,
                  style: appText(size: 11, color: AppColors.muted, height: 1.2),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<NotificationState>(
            builder: (context, notif, _) => Stack(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (notif.unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                      child: Text('${notif.unread}',
                          style: appText(size: 9, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AsyncContent(
        loading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: _data == null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          child: switch (auth.role) {
            'Karyawan' => _KaryawanHome(data: _data ?? const {}, onRefresh: _load),
            'Owner' => _OwnerHome(data: _data ?? const {}, onRefresh: _load),
            _ => _AdminHome(data: _data ?? const {}, recentSpk: _recentSpk, onRefresh: _load),
          },
        ),
      ),
    );
  }
}

class _KaryawanHome extends StatelessWidget {
  const _KaryawanHome({required this.data, required this.onRefresh});

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final financial = Map<String, dynamic>.from((data['financial'] as Map?) ?? {});
    final spk = Map<String, dynamic>.from((data['spk'] as Map?) ?? {});
    final latest = data['latest_payroll'] is Map
        ? Payroll.fromJson(Map<String, dynamic>.from(data['latest_payroll'] as Map))
        : null;
    final tasks = (data['active_tasks'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(latest == null ? 'BELUM ADA SLIP' : 'PERIODE ${Formats.period(latest.period).toUpperCase()}',
                            style: labelText()),
                        const SizedBox(height: 6),
                        Money(
                          Formats.amount(latest?.netSalary ?? 0),
                          size: 30,
                          weight: FontWeight.w800,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latest == null ? 'Slip pertama belum diterbitkan' : latest.slipNumber,
                          style: appText(size: 11.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (latest != null) StatusBadge.payment(latest.paymentStatus),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      latest?.isPaid == true
                          ? 'Dibayar ${Formats.dateFromIso(latest?.paymentDate)}'
                          : 'Menunggu pembayaran',
                      style: appText(size: 11.5, color: AppColors.inkMuted),
                    ),
                  ),
                  if (latest != null)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SlipDetailScreen(payrollId: latest.id)),
                      ),
                      child: Text('Lihat slip',
                          style: appText(size: 12, weight: FontWeight.w600, color: AppColors.primary)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Diterima',
                value: Formats.amount(financial['total_salary_received']),
                valueSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                label: 'Tertunda',
                value: Formats.amount(financial['pending_salary']),
                valueSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                label: 'Sisa kasbon',
                value: Formats.amount(financial['remaining_cash_advance']),
                valueSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader('Tugas aktif',
            actionLabel: 'Lihat semua',
            onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpkListScreen()))),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const AppCard(child: Text('Tidak ada tugas berjalan.', style: TextStyle(color: AppColors.muted)))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _TaskRow(task: Map<String, dynamic>.from(tasks[i] as Map)),
                ],
              ],
            ),
          ),
        const SizedBox(height: 18),
        SectionHeader('Ringkasan tugas'),
        const SizedBox(height: 8),
        AppCard(
          child: Row(
            children: [
              Expanded(child: _MiniStat(label: 'Total', value: '${spk['total_assigned'] ?? 0}')),
              Expanded(child: _MiniStat(label: 'Jalan', value: '${spk['in_progress'] ?? 0}')),
              Expanded(child: _MiniStat(label: 'Selesai', value: '${spk['completed'] ?? 0}')),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final shop = task['shop'] is Map ? Map<String, dynamic>.from(task['shop'] as Map) : const {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${task['job_name'] ?? '-'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: appText(size: 13.5, weight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 2),
                Text('${task['spk_number'] ?? ''}${shop['name'] != null ? ' · ${shop['name']}' : ''}',
                    style: appText(size: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge('${task['job_status'] ?? '-'}'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: appText(size: 18, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: appText(size: 11, color: AppColors.muted)),
      ],
    );
  }
}

// --------------------------------------------------------------------- admin

class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.data, required this.recentSpk, required this.onRefresh});

  final Map<String, dynamic> data;
  final List<Spk> recentSpk;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final overview = Map<String, dynamic>.from((data['overview'] as Map?) ?? {});
    final spk = Map<String, dynamic>.from((data['spk'] as Map?) ?? {});
    final cash = Map<String, dynamic>.from((data['cash_advance'] as Map?) ?? {});
    final payroll = Map<String, dynamic>.from((data['payroll'] as Map?) ?? {});

    final selesaiTanpaSlip = recentSpk.where((item) => item.isDone && !item.hasPayroll).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Total SPK',
                value: '${spk['total_spk'] ?? 0}',
                hint: '${spk['pending'] ?? 0} belum dikerjakan',
                valueSize: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Karyawan aktif',
                value: '${overview['active_employees'] ?? 0}',
                hint: 'dari ${overview['total_employees'] ?? 0} karyawan',
                valueSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Kasbon berjalan',
                value: Formats.amount(cash['remaining_unpaid']),
                hint: 'belum terpotong',
                valueSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Slip belum dibayar',
                value: Formats.amount(payroll['total_unpaid_salary']),
                hint: 'dari ${payroll['total_slips'] ?? 0} slip',
                valueSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader('Perlu tindakan'),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              _ActionRow(
                title: selesaiTanpaSlip > 0
                    ? '$selesaiTanpaSlip SPK selesai belum punya slip'
                    : 'Semua SPK selesai sudah punya slip',
                subtitle: selesaiTanpaSlip > 0 ? 'Buat slip dari menu SPK' : 'Tidak ada tunggakan slip',
                actionLabel: selesaiTanpaSlip > 0 ? 'Lihat' : null,
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpkListScreen())),
              ),
              const Divider(height: 1),
              _ActionRow(
                title: 'Kasbon menunggu potong',
                subtitle: Formats.rupiah(cash['remaining_unpaid']),
                actionLabel: 'Lihat',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SlipListScreen())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader('SPK terbaru',
            actionLabel: 'Semua',
            onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpkListScreen()))),
        const SizedBox(height: 8),
        if (recentSpk.isEmpty)
          const AppCard(child: Text('Belum ada SPK.', style: TextStyle(color: AppColors.muted)))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < recentSpk.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recentSpk[i].jobName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: appText(size: 13.5, weight: FontWeight.w600, height: 1.3)),
                              const SizedBox(height: 2),
                              Text('${recentSpk[i].spkNumber} · ${recentSpk[i].employeeName ?? '-'}',
                                  style: appText(size: 11.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Money(Formats.amount(recentSpk[i].spkValue), size: 13),
                            const SizedBox(height: 4),
                            StatusBadge(recentSpk[i].jobStatus, tone: StatusTone.neutral, dot: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.title, required this.subtitle, this.actionLabel, this.onAction});

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: appText(size: 13, weight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 2),
                Text(subtitle, style: appText(size: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.primarySoft,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionLabel!, style: appText(size: 11.5, weight: FontWeight.w700, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- owner

class _OwnerHome extends StatelessWidget {
  const _OwnerHome({required this.data, required this.onRefresh});

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final financial = Map<String, dynamic>.from((data['financial'] as Map?) ?? {});
    final performance = Map<String, dynamic>.from((data['spk_performance'] as Map?) ?? {});
    final shops = (data['top_shops'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MARGIN OPERASIONAL', style: labelText()),
              const SizedBox(height: 6),
              Money(Formats.amount(financial['operating_margin']), size: 28, weight: FontWeight.w800),
              const SizedBox(height: 4),
              Text('Omzet bersih dikurangi total gaji', style: appText(size: 11.5, color: AppColors.muted)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Omzet kotor', value: Formats.compact(financial['gross_revenue'] ?? 0))),
                  Expanded(child: _MiniStat(label: 'PPN', value: Formats.compact(financial['estimated_ppn'] ?? 0))),
                  Expanded(child: _MiniStat(label: 'Gaji', value: Formats.compact(financial['total_salary_expense'] ?? 0))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'SPK',
                value: '${performance['total_spks'] ?? 0}',
                hint: '${performance['completed_spks'] ?? 0} selesai',
                valueSize: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Gaji terbayar',
                value: Formats.amount(financial['paid_salary_expense']),
                hint: 'belum ${Formats.rupiah(financial['unpaid_salary_expense'])}',
                valueSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader('Toko teratas'),
        const SizedBox(height: 8),
        if (shops.isEmpty)
          const AppCard(child: Text('Belum ada data toko.', style: TextStyle(color: AppColors.muted)))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < shops.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${(shops[i] as Map)['name'] ?? '-'}',
                                  style: appText(size: 13.5, weight: FontWeight.w600)),
                              Text('${(shops[i] as Map)['total_spk_count'] ?? 0} SPK',
                                  style: appText(size: 11.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Money(Formats.amount((shops[i] as Map)['total_revenue']), size: 13),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
