class MentorMiniDto {
  MentorMiniDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.workUnit,
  });

  final int id;
  final String email;
  final String fullName;
  final String? workUnit;

  factory MentorMiniDto.fromJson(Map<String, dynamic> json) {
    return MentorMiniDto(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      workUnit: json['workUnit']?.toString(),
    );
  }
}
