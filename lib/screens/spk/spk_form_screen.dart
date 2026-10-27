import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/spk.dart';
import '../../models/user.dart';
import '../../services/api_services.dart';
import '../../state/auth_state.dart';

/// Draf anggota SPK di form (belum dikirim ke server).
class _MemberDraft {
  _MemberDraft({
    required this.employeeId,
    required this.name,
    required this.role,
    required this.days,
    this.replacementForId,
    this.replacementForName,
  });

  final String employeeId;
  final String name;
  String role; // worker | replacement
  int days;
  String? replacementForId;
  String? replacementForName;

  bool get isReplacement => role == 'replacement';
}

/// Form tambah/ubah SPK: satu SPK bisa dikerjakan beberapa orang,
/// lengkap dengan orang pengganti dan jumlah hari kerja masing-masing.
class SpkFormScreen extends StatefulWidget {
  const SpkFormScreen({super.key, this.spk});

  final Spk? spk;

  @override
  State<SpkFormScreen> createState() => _SpkFormScreenState();
}

class _SpkFormScreenState extends State<SpkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jobName;
  late final TextEditingController _value;
  late final TextEditingController _description;
  late final TextEditingController _clientName;
  late final TextEditingController _location;

  DateTime _date = DateTime.now();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  String? _shopId;
  String _jobStatus = 'Belum Dikerjakan';
  String _paymentStatus = 'Belum Dibayar';

  final List<_MemberDraft> _members = [];

  List<Shop> _shops = const [];
  List<Employee> _employees = const [];
  bool _loadingRefs = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  bool get _isEdit => widget.spk != null;
  int get _duration => _end.difference(_start).inDays + 1;
  int get _workerCount => _members.where((m) => !m.isReplacement).length;
  double get _spkValue =>
      double.tryParse(_value.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  double get _dailyRate =>
      _workerCount == 0 ? 0 : _spkValue / (_workerCount * _duration);

  String _rp(num value) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(value);

  @override
  void initState() {
    super.initState();
    final spk = widget.spk;

    _jobName = TextEditingController(text: spk?.jobName ?? '');
    _value = TextEditingController(text: spk == null ? '' : spk.spkValue.toStringAsFixed(0));
    _description = TextEditingController(text: spk?.description ?? '');
    _clientName = TextEditingController(text: spk?.clientName ?? 'PT Albany Corona Lestari');
    _location = TextEditingController(text: spk?.location ?? '');

    if (spk != null) {
      _date = DateTime.tryParse(spk.date) ?? DateTime.now();
      _start = DateTime.tryParse(spk.startDate ?? spk.date) ?? _date;
      _end = DateTime.tryParse(spk.endDate ?? spk.date) ?? _date;
      _shopId = spk.shopId;
      _jobStatus = spk.jobStatus;
      _paymentStatus = spk.paymentStatus;

      for (final m in spk.members) {
        _members.add(_MemberDraft(
          employeeId: m.employeeId,
          name: m.name,
          role: m.role,
          days: m.daysWorked,
          replacementForId: m.replacementForId,
          replacementForName: m.replacementForName,
        ));
      }
    }

    _value.addListener(() => setState(() {}));
    _loadReferences();
  }

  @override
  void dispose() {
    _jobName.dispose();
    _value.dispose();
    _description.dispose();
    _clientName.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final services = context.read<AuthState>().services;
      final shops = await services.shops();
      final employees = await services.employees();

      if (!mounted) return;
      setState(() {
        _shops = shops;
        _employees = employees;
        _shopId ??= shops.isNotEmpty ? shops.first.id : null;
        _loadingRefs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar toko/karyawan: $e';
        _loadingRefs = false;
      });
    }
  }

  Future<void> _pickDate(DateTime current, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _addMember() async {
    if (_employees.isEmpty) return;

    final tersedia = _employees.where((e) => !_members.any((m) => m.employeeId == e.id)).toList();
    if (tersedia.isEmpty) {
      setState(() => _error = 'Semua karyawan sudah masuk ke SPK ini.');
      return;
    }

    String employeeId = tersedia.first.id;
    String role = 'worker';
    String? replacementForId = _members.where((m) => !m.isReplacement).isEmpty
        ? null
        : _members.firstWhere((m) => !m.isReplacement).employeeId;
    int days = _duration;

    final hasil = await showModalBottomSheet<_MemberDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Anggota', style: appText(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'SPK ini berlangsung $_duration hari.',
                style: appText(size: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              Text('KARYAWAN', style: labelText(color: AppColors.inkMuted)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: employeeId,
                isExpanded: true,
                items: [
                  for (final e in tersedia)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.name} · ${e.position}', style: appText(size: 14)),
                    ),
                ],
                onChanged: (v) => setSheetState(() => employeeId = v ?? employeeId),
              ),
              const SizedBox(height: 14),
              Text('PERAN', style: labelText(color: AppColors.inkMuted)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'worker', label: Text('Pekerja'), icon: Icon(Icons.person_outline, size: 16)),
                  ButtonSegment(value: 'replacement', label: Text('Pengganti'), icon: Icon(Icons.swap_horiz, size: 16)),
                ],
                selected: {role},
                onSelectionChanged: (v) => setSheetState(() {
                  role = v.first;
                  if (role == 'replacement' && replacementForId == null) {
                    final pekerja = _members.where((m) => !m.isReplacement).toList();
                    replacementForId = pekerja.isEmpty ? null : pekerja.first.employeeId;
                  }
                }),
              ),
              if (role == 'replacement') ...[
                const SizedBox(height: 14),
                Text('MENGGANTIKAN', style: labelText(color: AppColors.inkMuted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: replacementForId,
                  isExpanded: true,
                  items: [
                    for (final m in _members.where((m) => !m.isReplacement))
                      DropdownMenuItem(value: m.employeeId, child: Text(m.name, style: appText(size: 14))),
                  ],
                  onChanged: (v) => setSheetState(() => replacementForId = v),
                ),
              ],
              const SizedBox(height: 14),
              Text('JUMLAH HARI MASUK', style: labelText(color: AppColors.inkMuted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: days > 0 ? () => setSheetState(() => days--) : null,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('$days hari', style: appText(size: 15, weight: FontWeight.w600)),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: days < _duration ? () => setSheetState(() => days++) : null,
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final employee = tersedia.firstWhere((e) => e.id == employeeId);
                    final pekerja = _members.where((m) => !m.isReplacement).toList();
                    Navigator.of(sheetContext).pop(
                      _MemberDraft(
                        employeeId: employee.id,
                        name: employee.name,
                        role: role,
                        days: days,
                        replacementForId: role == 'replacement' ? replacementForId : null,
                        replacementForName: role == 'replacement'
                            ? pekerja.where((m) => m.employeeId == replacementForId).map((m) => m.name).firstOrNull
                            : null,
                      ),
                    );
                  },
                  child: const Text('Tambahkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (hasil != null) {
      setState(() {
        _members.add(hasil);
        _error = null;
      });
    }
  }

  /// Baca PDF SPK dari klien lalu isi form otomatis.
  Future<void> _uploadPdf() async {
    const group = XTypeGroup(label: 'Dokumen PDF', extensions: ['pdf']);
    final file = await openFile(acceptedTypeGroups: [group]);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      setState(() => _error = 'Berkas tidak bisa dibaca dari perangkat.');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final d = await context.read<AuthState>().services.parseSpkPdf(bytes, file.name);
      if (!mounted) return;

      setState(() {
        final client = '${d['client_name'] ?? ''}';
        if (client.isNotEmpty && client != 'null') _clientName.text = client;

        final location = '${d['location'] ?? ''}';
        if (location.isNotEmpty && location != 'null') _location.text = location;

        final value = double.tryParse('${d['spk_value']}') ?? 0;
        if (value > 0) _value.text = value.toStringAsFixed(0);

        final tanggal = DateTime.tryParse('${d['date']}');
        if (tanggal != null) _date = tanggal;

        final mulai = DateTime.tryParse('${d['start_date']}');
        final selesai = DateTime.tryParse('${d['end_date']}');
        if (mulai != null) _start = mulai;
        if (selesai != null) _end = selesai;

        final items = (d['items'] as List? ?? const []);
        if (_jobName.text.trim().isEmpty && items.isNotEmpty && items.first is Map) {
          _jobName.text = '${(items.first as Map)['name']}';
        }

        _uploading = false;
      });

      final total = (double.tryParse('${d['spk_value']}') ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF terbaca: ${d['item_count'] ?? 0} item · total '
            'Rp${NumberFormat('#,##0', 'id_ID').format(total)} · periksa lalu pilih anggotanya.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _uploading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_shopId == null) {
      setState(() => _error = 'Pilih toko terlebih dahulu.');
      return;
    }

    if (_workerCount == 0) {
      setState(() => _error = 'Tambahkan minimal satu pekerja pada SPK ini.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final services = context.read<AuthState>().services;
    final body = <String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'start_date': DateFormat('yyyy-MM-dd').format(_start),
      'end_date': DateFormat('yyyy-MM-dd').format(_end),
      'shop_id': _shopId,
      'client_name': _clientName.text.trim().isEmpty ? null : _clientName.text.trim(),
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      'job_name': _jobName.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'spk_value': _spkValue,
      'job_status': _jobStatus,
      'payment_status': _paymentStatus,
      'members': [
        for (final m in _members)
          {
            'employee_id': m.employeeId,
            'role': m.role,
            'days_worked': m.days,
            if (m.replacementForId != null) 'replacement_for_id': m.replacementForId,
          },
      ],
    };

    try {
      if (_isEdit) {
        await services.updateSpk(widget.spk!.id, body);
      } else {
        await services.createSpk(body);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah SPK' : 'Tambah SPK')),
      body: _loadingRefs
          ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          : Form(
              key: _formKey,
              child: ListView(
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Muat dari PDF SPK',
                            style: appText(size: 13.5, weight: FontWeight.w700, color: AppColors.primary)),
                        const SizedBox(height: 3),
                        Text(
                          'Nomor, tanggal, nilai, lokasi, dan durasi terisi otomatis. Nama pekerja tetap dipilih manual.',
                          style: appText(size: 11.5, color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _uploading ? null : _uploadPdf,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_file_outlined, size: 18),
                            label: Text(_uploading ? 'Membaca PDF…' : 'Pilih berkas PDF'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('NOMOR / TANGGAL SPK'),
                  _dateTile(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                    () => _pickDate(_date, (d) => _date = d),
                  ),
                  const SizedBox(height: 14),
                  _label('KLIEN'),
                  TextFormField(
                    controller: _clientName,
                    decoration: const InputDecoration(hintText: 'PT Albany Corona Lestari'),
                  ),
                  const SizedBox(height: 14),
                  _label('TOKO / LOKASI'),
                  DropdownButtonFormField<String>(
                    initialValue: _shopId,
                    items: [
                      for (final shop in _shops)
                        DropdownMenuItem(value: shop.id, child: Text(shop.name, style: appText(size: 14))),
                    ],
                    onChanged: (value) => setState(() => _shopId = value),
                    decoration: const InputDecoration(hintText: 'Pilih toko'),
                  ),
                  const SizedBox(height: 14),
                  _label('DETAIL LOKASI (OPSIONAL)'),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(hintText: 'T4PO - Gebang Kulon'),
                  ),
                  const SizedBox(height: 14),
                  _label('NAMA PEKERJAAN'),
                  TextFormField(
                    controller: _jobName,
                    decoration: const InputDecoration(hintText: 'Neon Box — Toko Sinar Jaya'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pekerjaan wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  _label('NILAI SPK (Rp)'),
                  TextFormField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '2449636'),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Nilai SPK harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('MULAI'),
                            _dateTile(
                              DateFormat('dd MMM yyyy').format(_start),
                              () => _pickDate(_start, (d) {
                                _start = d;
                                if (_end.isBefore(d)) _end = d;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('SELESAI'),
                            _dateTile(
                              DateFormat('dd MMM yyyy').format(_end),
                              () => _pickDate(_end, (d) => _end = d),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Durasi kerja: $_duration hari',
                    style: appText(size: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Text('ANGGOTA SPK', style: labelText(color: AppColors.inkMuted))),
                      TextButton.icon(
                        onPressed: _addMember,
                        icon: const Icon(Icons.person_add_alt_1, size: 17),
                        label: const Text('Tambah'),
                      ),
                    ],
                  ),
                  if (_members.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Belum ada anggota. Tambahkan pekerja yang mengerjakan SPK ini.',
                        style: appText(size: 12.5, color: AppColors.inkMuted),
                      ),
                    )
                  else
                    for (final m in _members) _memberTile(m),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembagi: $_workerCount pekerja · $_duration hari',
                          style: appText(size: 12.5, weight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nilai per hari: ${_rp(_dailyRate)}',
                          style: appText(size: 12, color: AppColors.primary),
                        ),
                        if (_members.any((m) => m.isReplacement))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Pengganti tidak menambah pembagi.',
                              style: appText(size: 11.5, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('DESKRIPSI (OPSIONAL)'),
                  TextFormField(
                    controller: _description,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Catatan pekerjaan'),
                  ),
                  const SizedBox(height: 14),
                  _label('STATUS PEKERJAAN'),
                  DropdownButtonFormField<String>(
                    initialValue: _jobStatus,
                    items: const ['Belum Dikerjakan', 'Sedang Dikerjakan', 'Selesai']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value, style: appText(size: 14))))
                        .toList(),
                    onChanged: (value) => setState(() => _jobStatus = value ?? _jobStatus),
                  ),
                  const SizedBox(height: 14),
                  _label('STATUS PEMBAYARAN KLIEN'),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    items: const ['Belum Dibayar', 'Sudah Dibayar']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value, style: appText(size: 14))))
                        .toList(),
                    onChanged: (value) => setState(() => _paymentStatus = value ?? _paymentStatus),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah SPK'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _memberTile(_MemberDraft m) {
    final badgeColor = m.isReplacement ? AppColors.warning : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: appText(size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  m.isReplacement
                      ? 'Pengganti ${m.replacementForName ?? '-'} · ${m.days} hari'
                      : 'Pekerja · ${m.days} hari',
                  style: appText(size: 11.5, color: badgeColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _members.remove(m)),
            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(text, style: appText(size: 13.5))),
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: labelText(color: AppColors.inkMuted)),
      );
}
