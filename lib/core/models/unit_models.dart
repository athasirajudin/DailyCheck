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
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      geofenceLat: (json['geofenceLat'] as num?)?.toDouble() ?? 0,
      geofenceLon: (json['geofenceLon'] as num?)?.toDouble() ?? 0,
      geofenceRadiusM: (json['geofenceRadiusM'] as num?)?.toInt() ?? 0,
    );
  }
}
