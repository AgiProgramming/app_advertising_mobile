/// Anggota penugasan pada satu SPK.
class SpkMember {
  const SpkMember({
    required this.employeeId,
    required this.name,
    required this.role,
    required this.daysWorked,
    this.replacementForId,
    this.replacementForName,
    this.shareAmount = 0,
  });

  final String employeeId;
  final String name;
  final String role; // worker | replacement
  final int daysWorked;
  final String? replacementForId;
  final String? replacementForName;
  final double shareAmount;

  bool get isReplacement => role == 'replacement';

  factory SpkMember.fromJson(Map<String, dynamic> json) => SpkMember(
        employeeId: '${json['employee_id']}',
        name: '${json['name'] ?? '-'}',
        role: '${json['role'] ?? 'worker'}',
        daysWorked: int.tryParse('${json['days_worked'] ?? 0}') ?? 0,
        replacementForId: json['replacement_for_id'] as String?,
        replacementForName: json['replacement_for_name'] as String?,
        shareAmount: double.tryParse('${json['share_amount'] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'role': role,
        'days_worked': daysWorked,
        if (replacementForId != null) 'replacement_for_id': replacementForId,
      };
}

class Spk {
  const Spk({
    required this.id,
    required this.spkNumber,
    required this.date,
    required this.jobName,
    required this.spkValue,
    required this.jobStatus,
    required this.paymentStatus,
    this.shopId,
    this.shopName,
    this.employeeId,
    this.employeeName,
    this.description,
    this.notes,
    this.hasPayroll = false,
    this.clientName,
    this.location,
    this.startDate,
    this.endDate,
    this.durationDays = 1,
    this.slotCount = 0,
    this.dailyRate = 0,
    this.members = const [],
  });

  final String id;
  final String spkNumber;
  final String date;
  final String jobName;
  final double spkValue;
  final String jobStatus;
  final String paymentStatus;
  final String? shopId;
  final String? shopName;
  final String? employeeId;
  final String? employeeName;
  final String? description;
  final String? notes;
  final bool hasPayroll;
  final String? clientName;
  final String? location;
  final String? startDate;
  final String? endDate;
  final int durationDays;
  final int slotCount;
  final double dailyRate;
  final List<SpkMember> members;

  bool get isDone => jobStatus == 'Selesai';
  bool get isPaid => paymentStatus == 'Sudah Dibayar';
  int get workerCount => members.where((m) => !m.isReplacement).length;
  int get replacementCount => members.where((m) => m.isReplacement).length;

  factory Spk.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] is Map ? Map<String, dynamic>.from(json['shop'] as Map) : const {};
    final employee = json['employee'] is Map ? Map<String, dynamic>.from(json['employee'] as Map) : const {};
    final rawMembers = json['members'] is List ? json['members'] as List : const [];

    return Spk(
      id: '${json['id']}',
      spkNumber: '${json['spk_number'] ?? '-'}',
      date: '${json['date'] ?? ''}',
      jobName: '${json['job_name'] ?? '-'}',
      spkValue: double.tryParse('${json['spk_value'] ?? 0}') ?? 0,
      jobStatus: '${json['job_status'] ?? 'Belum Dikerjakan'}',
      paymentStatus: '${json['payment_status'] ?? 'Belum Dibayar'}',
      shopId: shop['id'] as String?,
      shopName: shop['name'] as String?,
      employeeId: employee['id'] as String?,
      employeeName: employee['name'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      hasPayroll: json['payroll'] != null,
      clientName: json['client_name'] as String?,
      location: json['location'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      durationDays: int.tryParse('${json['duration_days'] ?? 1}') ?? 1,
      slotCount: int.tryParse('${json['slot_count'] ?? 0}') ?? 0,
      dailyRate: double.tryParse('${json['daily_rate'] ?? 0}') ?? 0,
      members: rawMembers
          .whereType<Map>()
          .map((m) => SpkMember.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}
