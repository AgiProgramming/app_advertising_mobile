import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_state.dart';
import '../state/notification_state.dart';
import 'home/home_screen.dart';
import 'notifications/notification_screen.dart';
import 'payroll/slip_list_screen.dart';
import 'profile/profile_screen.dart';
import 'spk/spk_list_screen.dart';

/// Kerangka utama: bottom navigation 4 tab sesuai role.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isKaryawan = auth.role == 'Karyawan';

    final tabs = [
      _Tab(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
      _Tab(label: 'Slip', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long),
      _Tab(
        label: isKaryawan ? 'Tugas' : 'SPK',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
      ),
      _Tab(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person),
    ];

    final pages = <Widget>[
      const HomeScreen(),
      const SlipListScreen(),
      const SpkListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// App bar ringkas dengan tombol notifikasi + badge jumlah belum dibaca.
class AppBarWithNotifications extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithNotifications({super.key, required this.title, this.showBack = false, this.actions = const []});

  final String title;
  final bool showBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationState>().unread;

    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      actions: [
        ...actions,
        Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: Text('$unread',
                      style: appText(size: 9, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
