class CashAdvance {
  const CashAdvance({
    required this.id,
    required this.amount,
    required this.date,
    this.description,
    this.employeeName,
  });

  final String id;
  final double amount;
  final String date;
  final String? description;
  final String? employeeName;

  factory CashAdvance.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] is Map ? Map<String, dynamic>.from(json['employee'] as Map) : const {};

    return CashAdvance(
      id: '${json['id']}',
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      date: '${json['date'] ?? ''}',
      description: json['description'] as String?,
      employeeName: employee['name'] as String?,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.payrollId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? payrollId;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      type: '${json['type'] ?? 'info'}',
      isRead: json['is_read'] == true,
      payrollId: json['payroll_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
    );
  }
}
