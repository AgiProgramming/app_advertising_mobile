/// Rincian bagian seorang karyawan dari satu SPK di dalam slip.
class PayrollItem {
  const PayrollItem({
    required this.spkNumber,
    required this.spkValue,
    required this.slotCount,
    required this.durationDays,
    required this.daysWorked,
    required this.dailyRate,
    required this.shareAmount,
    this.jobName,
  });

  final String spkNumber;
  final double spkValue;
  final int slotCount;
  final int durationDays;
  final int daysWorked;
  final double dailyRate;
  final double shareAmount;
  final String? jobName;

  String get shortNumber {
    final parts = spkNumber.split('/');
    return parts.length > 1 ? parts.last : spkNumber;
  }

  factory PayrollItem.fromJson(Map<String, dynamic> json) => PayrollItem(
        spkNumber: '${json['spk_number'] ?? '-'}',
        spkValue: double.tryParse('${json['spk_value'] ?? 0}') ?? 0,
        slotCount: int.tryParse('${json['slot_count'] ?? 0}') ?? 0,
        durationDays: int.tryParse('${json['duration_days'] ?? 1}') ?? 1,
        daysWorked: int.tryParse('${json['days_worked'] ?? 0}') ?? 0,
        dailyRate: double.tryParse('${json['daily_rate'] ?? 0}') ?? 0,
        shareAmount: double.tryParse('${json['share_amount'] ?? 0}') ?? 0,
        jobName: json['job_name'] as String?,
      );
}

class Payroll {
  const Payroll({
    required this.id,
    required this.slipNumber,
    required this.period,
    required this.netSalary,
    required this.paymentStatus,
    this.grossShare = 0,
    this.ppnRate = 4,
    this.ppnAmount = 0,
    this.commissionRate = 22,
    this.commissionAmount = 0,
    this.mealRate = 0,
    this.mealCount = 0,
    this.mealDeduction = 0,
    this.cashAdvanceDeduction = 0,
    this.isNegative = false,
    this.items = const [],
    this.paymentDate,
    this.employeeName,
    this.employeeNik,
    this.employeePosition,
    this.verificationToken,
    this.verifyUrl,
    this.createdAt,
  });

  final String id;
  final String slipNumber;
  final String period;
  final double netSalary;
  final String paymentStatus;
  final double grossShare;
  final double ppnRate;
  final double ppnAmount;
  final double commissionRate;
  final double commissionAmount;
  final double mealRate;
  final int mealCount;
  final double mealDeduction;
  final double cashAdvanceDeduction;
  final bool isNegative;
  final List<PayrollItem> items;
  final String? paymentDate;
  final String? employeeName;
  final String? employeeNik;
  final String? employeePosition;
  final String? verificationToken;
  final String? verifyUrl;
  final DateTime? createdAt;

  bool get isPaid => paymentStatus == 'Sudah Dibayar';
  int get spkCount => items.length;

  factory Payroll.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map ? Map<String, dynamic>.from(json['employee'] as Map) : const {};
    final rawItems = json['items'] is List ? json['items'] as List : const [];

    double toDouble(dynamic value) => value == null ? 0 : double.tryParse('$value') ?? 0;
    int toInt(dynamic value) => value == null ? 0 : int.tryParse('$value') ?? 0;

    final net = toDouble(json['net_salary']);

    return Payroll(
      id: '${json['id']}',
      slipNumber: '${json['slip_number'] ?? '-'}',
      period: '${json['period'] ?? '-'}',
      netSalary: net,
      paymentStatus: '${json['payment_status'] ?? 'Belum Dibayar'}',
      grossShare: toDouble(json['gross_share']),
      ppnRate: toDouble(json['ppn_rate']),
      ppnAmount: toDouble(json['ppn_amount']),
      commissionRate: toDouble(json['commission_rate']),
      commissionAmount: toDouble(json['commission_amount']),
      mealRate: toDouble(json['meal_rate']),
      mealCount: toInt(json['meal_count']),
      mealDeduction: toDouble(json['meal_deduction']),
      cashAdvanceDeduction: toDouble(json['cash_advance_deduction']),
      isNegative: json['is_negative'] == true || net < 0,
      items: rawItems
          .whereType<Map>()
          .map((m) => PayrollItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      paymentDate: json['payment_date'] as String?,
      employeeName: employee['name'] as String?,
      employeeNik: employee['nik'] as String?,
      employeePosition: employee['position'] as String?,
      verificationToken: json['verification_token'] as String?,
      verifyUrl: json['verify_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
    );
  }
}
