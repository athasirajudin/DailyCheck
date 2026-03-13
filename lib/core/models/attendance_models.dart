class AttendanceDto {
  AttendanceDto({
    required this.id,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.checkInAt,
    required this.checkOutAt,
    required this.checkoutMissing,
  });

  final int id;
  final String date;
  final String status;
  final String markedBy;
  final String? checkInAt;
  final String? checkOutAt;
  final bool checkoutMissing;

  factory AttendanceDto.fromJson(Map<String, dynamic> json) {
    return AttendanceDto(
      id: (json['id'] as num).toInt(),
      date: (json['date'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      markedBy: (json['markedBy'] ?? '').toString(),
      checkInAt: json['checkInAt']?.toString(),
      checkOutAt: json['checkOutAt']?.toString(),
      checkoutMissing: json['checkoutMissing'] == true,
    );
  }
}

class RecapSummary {
  RecapSummary({
    required this.hadir,
    required this.terlambat,
    required this.izin,
    required this.sakit,
    required this.alpa,
    required this.checkoutMissing,
  });

  final int hadir;
  final int terlambat;
  final int izin;
  final int sakit;
  final int alpa;
  final int checkoutMissing;

  factory RecapSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    return RecapSummary(
      hadir: asInt(json['HADIR']),
      terlambat: asInt(json['TERLAMBAT']),
      izin: asInt(json['IZIN']),
      sakit: asInt(json['SAKIT']),
      alpa: asInt(json['ALPA']),
      checkoutMissing: asInt(json['CHECKOUT_MISSING']),
    );
  }
}

class RecapItem {
  RecapItem({
    required this.id,
    required this.date,
    required this.internUserId,
    required this.internName,
    required this.schoolName,
    required this.unitName,
    required this.status,
    required this.markedBy,
    required this.checkInAt,
    required this.checkOutAt,
    required this.checkoutMissing,
  });

  final int id;
  final String date;
  final int internUserId;
  final String internName;
  final String? schoolName;
  final String unitName;
  final String status;
  final String markedBy;
  final String? checkInAt;
  final String? checkOutAt;
  final bool checkoutMissing;

  factory RecapItem.fromJson(Map<String, dynamic> json) {
    return RecapItem(
      id: (json['id'] as num).toInt(),
      date: (json['date'] ?? '').toString(),
      internUserId: (json['internUserId'] as num).toInt(),
      internName: (json['internName'] ?? '').toString(),
      schoolName: json['schoolName']?.toString(),
      unitName: (json['unitName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      markedBy: (json['markedBy'] ?? '').toString(),
      checkInAt: json['checkInAt']?.toString(),
      checkOutAt: json['checkOutAt']?.toString(),
      checkoutMissing: json['checkoutMissing'] == true,
    );
  }
}
