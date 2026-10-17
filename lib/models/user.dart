class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.employee,
  });

  final String id;
  final String username;
  final String role;
  final Employee? employee;

  bool get isAdmin => role == 'Admin';
  bool get isOwner => role == 'Owner';
  bool get isKaryawan => role == 'Karyawan';

  String get displayName => employee?.name ?? username;

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = json['role'];

    return AppUser(
      id: '${json['id']}',
      username: '${json['username']}',
      role: role is Map ? '${role['name']}' : '$role',
      employee: json['employee'] is Map
          ? Employee.fromJson(Map<String, dynamic>.from(json['employee'] as Map))
          : null,
    );
  }
}

class Employee {
  const Employee({
    required this.id,
    required this.nik,
    required this.name,
    required this.position,
    this.phone,
    this.address,
    this.isActive = true,
    this.username,
  });

  final String id;
  final String nik;
  final String name;
  final String position;
  final String? phone;
  final String? address;
  final bool isActive;
  final String? username;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: '${json['id']}',
      nik: '${json['nik'] ?? '-'}',
      name: '${json['name'] ?? '-'}',
      position: '${json['position'] ?? '-'}',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      username: json['username'] as String?,
    );
  }
}
