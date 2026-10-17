import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_state.dart';
import '../cash_advance/cash_advance_screen.dart';
import '../notifications/notification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(user?.initials ?? '?',
                      style: appText(size: 16, weight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? '-', style: appText(size: 15, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${user?.username ?? ''} · ${user?.role ?? ''}',
                          style: appText(size: 12, color: AppColors.muted)),
                      if (user?.employee != null) ...[
                        const SizedBox(height: 2),
                        Text('${user!.employee!.nik} · ${user.employee!.position}',
                            style: appText(size: 11.5, color: AppColors.muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('MENU', style: labelText()),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuRow(
                  icon: Icons.savings_outlined,
                  label: auth.role == 'Karyawan' ? 'Kasbon saya' : 'Kasbon karyawan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CashAdvanceScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Tentang aplikasi',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Mann Plus Payroll',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text('Aplikasi penggajian karyawan Bengkel Mann Plus Advertising. '
                          'Slip gaji digital dengan verifikasi QR dan notifikasi.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar dari akun?'),
                  content: const Text('Anda perlu memasukkan username dan password lagi untuk masuk.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<AuthState>().logout();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
            label: Text('Keluar', style: appText(size: 14, weight: FontWeight.w600, color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Mann Plus Payroll v1.0.0',
                style: appText(size: 11, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: appText(size: 14, weight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.borderStrong),
          ],
        ),
      ),
    );
  }
}
