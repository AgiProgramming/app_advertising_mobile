import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../../state/auth_state.dart';
import '../../widgets/ui.dart';
import 'employee_form_screen.dart';
import 'shop_form_screen.dart';

/// Data master Admin: karyawan & toko (tambah / ubah / hapus).
class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);

  List<Employee> _employees = const [];
  List<Shop> _shops = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final services = context.read<AuthState>().services;
      final employees = await services.employees();
      final shops = await services.shops();

      if (!mounted) return;
      setState(() {
        _employees = employees;
        _shops = shops;
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

  Future<void> _add() async {
    final isEmployee = _tabs.index == 0;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => isEmployee ? const EmployeeFormScreen() : const ShopFormScreen()),
    );

    if (changed == true) _load();
  }

  Future<void> _editEmployee(Employee employee) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (changed == true) _load();
  }

  Future<void> _editShop(Shop shop) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ShopFormScreen(shop: shop)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete({required String id, required String name, required bool employee}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus $name?'),
        content: Text(employee
            ? 'Akun login karyawan ini juga akan dihapus dan tidak bisa dipakai lagi.'
            : 'Data toko akan dihapus dari daftar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final services = context.read<AuthState>().services;
      employee ? await services.deleteEmployee(id) : await services.deleteShop(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Master'),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: appText(size: 13, weight: FontWeight.w700),
          unselectedLabelStyle: appText(size: 13, weight: FontWeight.w500),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [Tab(text: 'Karyawan'), Tab(text: 'Toko')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 18),
        label: Text(_tabs.index == 0 ? 'Karyawan' : 'Toko', style: appText(size: 13, weight: FontWeight.w700, color: Colors.white)),
      ),
      body: AsyncContent(
        loading: _loading,
        error: _error,
        onRetry: _load,
        isEmpty: false,
        child: TabBarView(
          controller: _tabs,
          children: [
            _employees.isEmpty
                ? const EmptyState(message: 'Belum ada karyawan.', icon: Icons.people_outline)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    itemCount: _employees.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final employee = _employees[index];

                      return AppCard(
                        onTap: () => _editEmployee(employee),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSunken,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                employee.name.isEmpty ? '?' : employee.name.substring(0, 1).toUpperCase(),
                                style: appText(size: 14, weight: FontWeight.w800, color: AppColors.inkMuted),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(employee.name,
                                      style: appText(size: 14, weight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${employee.nik} · ${employee.position}',
                                      style: appText(size: 11.5, color: AppColors.muted)),
                                  if (employee.username != null)
                                    Text('akun: ${employee.username}',
                                        style: appText(size: 11, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            StatusBadge(employee.isActive ? 'Aktif' : 'Nonaktif',
                                tone: employee.isActive ? StatusTone.paid : StatusTone.neutral, dot: false),
                            IconButton(
                              onPressed: () => _delete(id: employee.id, name: employee.name, employee: true),
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            _shops.isEmpty
                ? const EmptyState(message: 'Belum ada toko.', icon: Icons.storefront_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    itemCount: _shops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];

                      return AppCard(
                        onTap: () => _editShop(shop),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shop.name, style: appText(size: 14, weight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${shop.code}${shop.ownerName != null ? ' · ${shop.ownerName}' : ''}',
                                      style: appText(size: 11.5, color: AppColors.muted)),
                                  if (shop.phone != null)
                                    Text(shop.phone!, style: appText(size: 11, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            StatusBadge(shop.status,
                                tone: shop.isActive ? StatusTone.paid : StatusTone.neutral, dot: false),
                            IconButton(
                              onPressed: () => _delete(id: shop.id, name: shop.name, employee: false),
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
