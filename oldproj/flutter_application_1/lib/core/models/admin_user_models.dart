class MentorMiniDto {
  MentorMiniDto({required this.id, required this.email, required this.fullName});

  final int id;
  final String email;
  final String fullName;

  factory MentorMiniDto.fromJson(Map<String, dynamic> json) {
    return MentorMiniDto(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
    );
  }
}

