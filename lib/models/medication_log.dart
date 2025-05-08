import 'package:uuid/uuid.dart';

class MedicationLog {
  final String id;
  final String medicationId; // İlgili ilacın ID'si
  final DateTime scheduledTime; // Planlanmış ilaç alım zamanı
  final DateTime? takenTime; // İlacın gerçekten alındığı zaman (null ise alınmamış)
  final bool isTaken; // İlaç alındı mı?
  final bool isSkipped; // İlaç bilinçli olarak atlandı mı?
  final String? notes; // İlaç alım notu veya neden alınmadığı

  MedicationLog({
    String? id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    this.isTaken = false,
    this.isSkipped = false,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  // İlacın alındı olarak işaretlenmesi
  MedicationLog markAsTaken({String? notes}) {
    return MedicationLog(
      id: id,
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      takenTime: DateTime.now(),
      isTaken: true,
      isSkipped: false,
      notes: notes ?? this.notes,
    );
  }

  // İlacın atlandı olarak işaretlenmesi
  MedicationLog markAsSkipped({String? notes}) {
    return MedicationLog(
      id: id,
      medicationId: medicationId,
      scheduledTime: scheduledTime,
      takenTime: null,
      isTaken: false,
      isSkipped: true,
      notes: notes ?? this.notes,
    );
  }

  // Gecikme süresi (dakika cinsinden)
  int? get delayInMinutes {
    if (!isTaken || takenTime == null) return null;
    return takenTime!.difference(scheduledTime).inMinutes;
  }

  // Zamanında alındı mı? (15 dakika tolerans)
  bool get takenOnTime {
    if (!isTaken || takenTime == null) return false;
    final delayMins = delayInMinutes!;
    return delayMins >= -15 && delayMins <= 15; // ±15 dakika tolerans
  }

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'isTaken': isTaken,
      'isSkipped': isSkipped,
      'notes': notes,
    };
  }

  // JSON'dan nesne oluşturma
  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      medicationId: json['medicationId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      takenTime: json['takenTime'] != null ? DateTime.parse(json['takenTime']) : null,
      isTaken: json['isTaken'],
      isSkipped: json['isSkipped'],
      notes: json['notes'],
    );
  }

  // Kopyalama metodu ile yeni nesne oluşturma
  MedicationLog copyWith({
    String? medicationId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    bool? isTaken,
    bool? isSkipped,
    String? notes,
  }) {
    return MedicationLog(
      id: id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      isTaken: isTaken ?? this.isTaken,
      isSkipped: isSkipped ?? this.isSkipped,
      notes: notes ?? this.notes,
    );
  }
}