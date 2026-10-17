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

  bool get isDone => jobStatus == 'Selesai';
  bool get isPaid => paymentStatus == 'Sudah Dibayar';

  factory Spk.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] is Map ? Map<String, dynamic>.from(json['shop'] as Map) : const {};
    final employee = json['employee'] is Map ? Map<String, dynamic>.from(json['employee'] as Map) : const {};

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
    );
  }
}
