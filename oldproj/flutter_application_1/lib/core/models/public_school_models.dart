class PublicSchoolDto {
  PublicSchoolDto({
    required this.id,
    required this.name,
    this.npsn,
    this.level,
    this.city,
    this.address,
  });

  final String id;
  final String name;
  final String? npsn;
  final String? level;
  final String? city;
  final String? address;

  factory PublicSchoolDto.fromJson(Map<String, dynamic> json) {
    return PublicSchoolDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      npsn: json['npsn']?.toString(),
      level: json['level']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
    );
  }
}
