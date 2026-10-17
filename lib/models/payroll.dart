class Payroll {
  const Payroll({
    required this.id,
    required this.slipNumber,
    required this.period,
    required this.originalSpkValue,
    required this.ppnAmount,
    required this.netSpkValue,
    required this.salaryPercentage,
    required this.grossSalary,
    required this.mealAllowance,
    required this.cashAdvanceDeduction,
    required this.netSalary,
    required this.paymentStatus,
    this.paymentDate,
    this.employeeName,
    this.employeeNik,
    this.employeePosition,
    this.spkNumber,
    this.jobName,
    this.jobStatus,
    this.shopName,
    this.verificationToken,
    this.verifyUrl,
    this.createdAt,
  });

  final String id;
  final String slipNumber;
  final String period;
  final double originalSpkValue;
  final double ppnAmount;
  final double netSpkValue;
  final double salaryPercentage;
  final double grossSalary;
  final double mealAllowance;
  final double cashAdvanceDeduction;
  final double netSalary;
  final String paymentStatus;
  final String? paymentDate;
  final String? employeeName;
  final String? employeeNik;
  final String? employeePosition;
  final String? spkNumber;
  final String? jobName;
  final String? jobStatus;
  final String? shopName;
  final String? verificationToken;
  final String? verifyUrl;
  final DateTime? createdAt;

  bool get isPaid => paymentStatus == 'Sudah Dibayar';

  factory Payroll.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map ? Map<String, dynamic>.from(json['employee'] as Map) : const {};
    final spk = json['spk'] is Map ? Map<String, dynamic>.from(json['spk'] as Map) : const {};
    final shop = spk['shop'] is Map ? Map<String, dynamic>.from(spk['shop'] as Map) : const {};

    double toDouble(dynamic value) => value == null ? 0 : double.tryParse('$value') ?? 0;

    return Payroll(
      id: '${json['id']}',
      slipNumber: '${json['slip_number'] ?? '-'}',
      period: '${json['period'] ?? '-'}',
      originalSpkValue: toDouble(json['original_spk_value']),
      ppnAmount: toDouble(json['ppn_amount']),
      netSpkValue: toDouble(json['net_spk_value']),
      salaryPercentage: toDouble(json['salary_percentage']),
      grossSalary: toDouble(json['gross_salary']),
      mealAllowance: toDouble(json['meal_allowance']),
      cashAdvanceDeduction: toDouble(json['cash_advance_deduction']),
      netSalary: toDouble(json['net_salary']),
      paymentStatus: '${json['payment_status'] ?? 'Belum Dibayar'}',
      paymentDate: json['payment_date'] as String?,
      employeeName: employee['name'] as String?,
      employeeNik: employee['nik'] as String?,
      employeePosition: employee['position'] as String?,
      spkNumber: spk['spk_number'] as String?,
      jobName: spk['job_name'] as String?,
      jobStatus: spk['job_status'] as String?,
      shopName: shop['name'] as String?,
      verificationToken: json['verification_token'] as String?,
      verifyUrl: json['verify_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
    );
  }
}
