class PublicSchoolDto {
  PublicSchoolDto({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.npsn,
  });

  final String id;
  final String name;
  final String? city;
  final String? address;
  final String? npsn;

  factory PublicSchoolDto.fromJson(Map<String, dynamic> json) {
    return PublicSchoolDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      npsn: json['npsn']?.toString(),
    );
  }
}
