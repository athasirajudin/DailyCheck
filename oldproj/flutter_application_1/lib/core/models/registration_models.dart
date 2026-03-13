class RegistrationRequestDto {
  RegistrationRequestDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.unitId,
    required this.unitName,
    required this.mentorUserId,
    required this.mentorName,
    this.schoolName,
    this.schoolAddress,
    required this.internshipStart,
    required this.internshipEnd,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String fullName;
  final int unitId;
  final String unitName;
  final int? mentorUserId;
  final String? mentorName;
  final String? schoolName;
  final String? schoolAddress;
  final String internshipStart;
  final String internshipEnd;
  final String? notes;
  final String status;
  final String createdAt;

  factory RegistrationRequestDto.fromJson(Map<String, dynamic> json) {
    return RegistrationRequestDto(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      unitId: (json['unit_id'] as num).toInt(),
      unitName: (json['unit_name'] ?? '').toString(),
      mentorUserId: json['mentor_user_id'] == null ? null : (json['mentor_user_id'] as num).toInt(),
      mentorName: json['mentor_name']?.toString(),
      schoolName: json['school_name']?.toString(),
      schoolAddress: json['school_address']?.toString(),
      internshipStart: (json['internship_start'] ?? '').toString(),
      internshipEnd: (json['internship_end'] ?? '').toString(),
      notes: json['notes']?.toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
