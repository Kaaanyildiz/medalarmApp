import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';

enum MedicationFrequency {
  daily,       // Her gün
  specificDays, // Belirli günler
  asNeeded,    // Gerektiğinde
  cyclical,    // Belirli bir periyot (örn: 1 hafta kullan, 1 hafta ara ver)
}

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class Medication {
  final String id;
  final String name;
  final String? dosage;           // örn: "1 tablet", "5ml"
  final String? instructions;     // örn: "Yemekten sonra"
  final String? medicationType;   // Hap, Sıvı, Enjeksiyon, vs.
  final Color color;
  
  // Yeni eklenen alanlar
  final MedicationFrequency frequency;        // Kullanım sıklığı
  final List<TimeOfDay> timesOfDay;           // Günün hangi saatlerinde alınacak
  final List<DayOfWeek> daysOfWeek;           // Hangi günler alınacak (specificDays için)
  final DateTime? startDate;                  // Başlangıç tarihi
  final DateTime? endDate;                    // Bitiş tarihi (null ise süresiz)
  final int? durationDays;                    // Kaç gün kullanılacak (endDate yerine)
  
  // Stok takibi
  final int? currentStock;                    // Mevcut stok miktarı
  final int? stockThreshold;                  // Uyarı eşiği
  final String? stockUnit;                    // Stok birimi (tablet, şişe, vb.)
  final DateTime? lastRefillDate;             // Son tedarik tarihi
  
  final bool remindRefill;                    // Stok hatırlatması etkin mi?
  final int timesPerDay;                      // Günde kaç kere alınacak
  final int dosesPerTime;                     // Her seferde kaç doz alınacak
  final String? notes;                        // İlaç hakkında notlar
  final bool isActive;                        // İlacın aktif olup olmadığı
  final List<MedicationLog> medicationLogs;

  /// Alınan doz sayısı
  int get takenCount => medicationLogs.where((log) => log.isTaken).length;

  /// Planlanan toplam doz sayısı
  int get scheduledCount => medicationLogs.length;

  Medication({
    String? id,
    required this.name,
    this.dosage,
    this.instructions,
    this.medicationType,
    this.color = Colors.blue,
    this.frequency = MedicationFrequency.daily,
    List<TimeOfDay>? timesOfDay,
    List<DayOfWeek>? daysOfWeek,
    this.startDate,
    this.endDate,
    this.durationDays,
    this.currentStock,
    this.stockThreshold = 5,  // Varsayılan olarak 5 birim kaldığında uyarı
    this.stockUnit = 'tablet',
    this.lastRefillDate,
    this.remindRefill = true,
    this.timesPerDay = 1,
    this.dosesPerTime = 1,
    this.notes,
    bool? isActive,
    List<MedicationLog>? medicationLogs,
  })  : id = id ?? const Uuid().v4(),
        timesOfDay = timesOfDay ?? [],
        daysOfWeek = daysOfWeek ?? [],
        isActive = isActive ?? true,
        medicationLogs = medicationLogs ?? [];
  
  // Kalan stok gün sayısını hesapla
  int? get daysUntilEmpty {
    if (currentStock == null || timesPerDay == 0 || dosesPerTime == 0) return null;
    return (currentStock! / (timesPerDay * dosesPerTime)).floor();
  }
  
  // Stok uyarısı gerekiyor mu?
  bool get needsRefill {
    if (currentStock == null || stockThreshold == null) return false;
    return currentStock! <= stockThreshold!;
  }
  
  // İlaç aktif mi? (kullanım süresi devam ediyor mu?)
  bool get isWithinActiveSchedule {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    // Eğer başlangıç tarihi ve kullanım süresi gün olarak belirtilmişse
    if (startDate != null && durationDays != null) {
      final endDate = startDate!.add(Duration(days: durationDays!));
      if (now.isAfter(endDate)) return false;
    }
    
    return true;
  }
  
  // Belirli bir günde alınması gerekiyor mu?
  bool shouldTakeOnDay(DateTime date) {
    if (!isActive || !isWithinActiveSchedule) return false;
    
    switch (frequency) {
      case MedicationFrequency.daily:
        return true;
      case MedicationFrequency.specificDays:
        final dayIndex = date.weekday - 1;  // 0: Pazartesi, 6: Pazar
        return daysOfWeek.contains(DayOfWeek.values[dayIndex]);
      case MedicationFrequency.asNeeded:
        return false;  // Gerektikçe alınan ilaçlar otomatik hatırlatılmaz
      case MedicationFrequency.cyclical:
        // Burada döngüsel kullanım kontrolü yapılabilir
        return true;  // Basitleştirilmiş
    }
  }
  
  // Zamanlanan saat için kolay erişim sağlayan getter (compatibility için)
  List<TimeOfDay> get scheduledTimes => timesOfDay;
  
  // Stok sayısı için kolay erişim sağlayan getter (compatibility için)
  int? get stockCount => currentStock;
  
  // Kopyalama metodu ile yeni nesne
  Medication copyWith({
    String? name,
    String? dosage,
    String? instructions,
    String? medicationType,
    Color? color,
    MedicationFrequency? frequency,
    List<TimeOfDay>? timesOfDay,
    List<DayOfWeek>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate, 
    int? durationDays,
    int? currentStock,
    int? stockThreshold,
    String? stockUnit,
    DateTime? lastRefillDate,
    bool? remindRefill,
    int? timesPerDay,
    int? dosesPerTime,
    String? notes,
    bool? isActive,
    List<MedicationLog>? medicationLogs,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      medicationType: medicationType ?? this.medicationType,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      currentStock: currentStock ?? this.currentStock,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      stockUnit: stockUnit ?? this.stockUnit,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      remindRefill: remindRefill ?? this.remindRefill,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      dosesPerTime: dosesPerTime ?? this.dosesPerTime,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      medicationLogs: medicationLogs ?? this.medicationLogs,
    );
  }
  
  // Stok güncelleme
  Medication updateStock(int newStock) {
    return copyWith(
      currentStock: newStock,
      lastRefillDate: newStock > (currentStock ?? 0) ? DateTime.now() : lastRefillDate,
    );
  }
  
  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
      'medicationType': medicationType,
      'color': color.value,
      'frequency': frequency.index,
      'timesOfDay': timesOfDay.map((time) => '${time.hour}:${time.minute}').toList(),
      'daysOfWeek': daysOfWeek.map((day) => day.index).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'durationDays': durationDays,
      'currentStock': currentStock,
      'stockThreshold': stockThreshold,
      'stockUnit': stockUnit,
      'lastRefillDate': lastRefillDate?.toIso8601String(),
      'remindRefill': remindRefill,
      'timesPerDay': timesPerDay,
      'dosesPerTime': dosesPerTime,
      'notes': notes,
      'isActive': isActive,
      'medicationLogs': medicationLogs.map((log) => log.toJson()).toList(),
    };
  }
  
  // JSON'dan nesne oluşturma
  factory Medication.fromJson(Map<String, dynamic> json) {
    // TimeOfDay nesnelerini JSON'dan dönüştürme
    List<TimeOfDay> times = [];
    if (json['timesOfDay'] != null) {
      times = (json['timesOfDay'] as List).map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
    
    // DayOfWeek nesnelerini JSON'dan dönüştürme
    List<DayOfWeek> days = [];
    if (json['daysOfWeek'] != null) {
      days = (json['daysOfWeek'] as List)
          .map((dayIndex) => DayOfWeek.values[dayIndex])
          .toList();
    }
    
    final defaultColor = Colors.blue;
    final colorValue = json['color'];
    final color = colorValue != null 
        ? Color(colorValue)
        : defaultColor;
    
    List<MedicationLog> logs = [];
    if (json['medicationLogs'] != null) {
      logs = (json['medicationLogs'] as List)
          .map((logJson) => MedicationLog.fromJson(logJson))
          .toList();
    }
    
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      instructions: json['instructions'],
      medicationType: json['medicationType'],
      color: color,
      frequency: MedicationFrequency.values[json['frequency'] ?? 0],
      timesOfDay: times,
      daysOfWeek: days,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      durationDays: json['durationDays'],
      currentStock: json['currentStock'],
      stockThreshold: json['stockThreshold'] ?? 5,
      stockUnit: json['stockUnit'] ?? 'tablet',
      lastRefillDate: json['lastRefillDate'] != null ? DateTime.parse(json['lastRefillDate']) : null,
      remindRefill: json['remindRefill'] ?? true,
      timesPerDay: json['timesPerDay'] ?? 1,
      dosesPerTime: json['dosesPerTime'] ?? 1,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      medicationLogs: logs,
    );
  }
  
  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, scheduleTimes: ${timesOfDay.length}, active: $isActive)';
  }
}