class LeaveRequestDto {
  LeaveRequestDto({
    required this.id,
    required this.internUserId,
    required this.internName,
    required this.type,
    required this.dateFrom,
    required this.dateTo,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int internUserId;
  final String internName;
  final String type; // IZIN/SAKIT
  final String dateFrom;
  final String dateTo;
  final String reason;
  final String status; // PENDING/APPROVED/REJECTED
  final String createdAt;

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDto(
      id: (json['id'] as num).toInt(),
      internUserId: (json['intern_user_id'] as num).toInt(),
      internName: (json['full_name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      dateFrom: (json['date_from'] ?? '').toString(),
      dateTo: (json['date_to'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class InternDto {
  InternDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.unitName,
    required this.active,
    required this.schoolName,
    required this.schoolAddress,
    required this.internshipStart,
    required this.internshipEnd,
  });

  final int userId;
  final String fullName;
  final String email;
  final String unitName;
  final bool active;
  final String? schoolName;
  final String? schoolAddress;
  final String internshipStart;
  final String internshipEnd;

  factory InternDto.fromJson(Map<String, dynamic> json) {
    return InternDto(
      userId: (json['userId'] as num).toInt(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      unitName: (json['unitName'] ?? '').toString(),
      active: json['active'] == true,
      schoolName: json['schoolName']?.toString(),
      schoolAddress: json['schoolAddress']?.toString(),
      internshipStart: (json['internshipStart'] ?? '').toString(),
      internshipEnd: (json['internshipEnd'] ?? '').toString(),
    );
  }
}
