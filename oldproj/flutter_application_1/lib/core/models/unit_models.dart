class UnitDto {
  UnitDto({
    required this.id,
    required this.name,
    required this.geofenceLat,
    required this.geofenceLon,
    required this.geofenceRadiusM,
  });

  final int id;
  final String name;
  final double geofenceLat;
  final double geofenceLon;
  final int geofenceRadiusM;

  factory UnitDto.fromJson(Map<String, dynamic> json) {
    return UnitDto(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      geofenceLat: (json['geofenceLat'] as num).toDouble(),
      geofenceLon: (json['geofenceLon'] as num).toDouble(),
      geofenceRadiusM: (json['geofenceRadiusM'] as num).toInt(),
    );
  }
}

