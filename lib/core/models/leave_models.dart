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
    required this.attachmentUrl,
  });

  final int id;
  final int internUserId;
  final String internName;
  final String type;
  final String dateFrom;
  final String dateTo;
  final String reason;
  final String status;
  final String createdAt;
  final String? attachmentUrl;

  bool get hasAttachment => (attachmentUrl ?? '').trim().isNotEmpty;

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      internUserId: (json['intern_user_id'] as num?)?.toInt() ?? 0,
      internName: (json['full_name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      dateFrom: (json['date_from'] ?? '').toString(),
      dateTo: (json['date_to'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }
}

class InternDto {
  InternDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.nisn,
    required this.gender,
    required this.unitId,
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
  final String nisn;
  final String? gender;
  final int unitId;
  final String unitName;
  final bool active;
  final String? schoolName;
  final String? schoolAddress;
  final String internshipStart;
  final String internshipEnd;

  factory InternDto.fromJson(Map<String, dynamic> json) {
    return InternDto(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nisn: (json['nisn'] ?? '').toString(),
      gender: json['gender']?.toString(),
      unitId: (json['unitId'] as num?)?.toInt() ?? 0,
      unitName: (json['unitName'] ?? '').toString(),
      active: json['active'] == true,
      schoolName: json['schoolName']?.toString(),
      schoolAddress: json['schoolAddress']?.toString(),
      internshipStart: (json['internshipStart'] ?? '').toString(),
      internshipEnd: (json['internshipEnd'] ?? '').toString(),
    );
  }
}
