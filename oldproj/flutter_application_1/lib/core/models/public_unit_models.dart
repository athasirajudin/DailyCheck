class PublicUnitDto {
  PublicUnitDto({required this.id, required this.name});

  final int id;
  final String name;

  factory PublicUnitDto.fromJson(Map<String, dynamic> json) {
    return PublicUnitDto(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

