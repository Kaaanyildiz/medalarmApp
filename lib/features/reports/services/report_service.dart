// filepath: c:\Users\Msi\medalarm\lib\services\report_service.dart
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';
import 'package:medalarmm/core/services/database_service.dart';

class ReportService {
  final DatabaseService _databaseService = DatabaseService();
  
  // Belirli bir ilacın uyum oranını hesapla (alınan dozların yüzdesi)
  Future<double> getMedicationAdherenceRate(
    String medicationId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Varsayılan olarak son 7 gün
    final DateTime end = endDate ?? DateTime.now();
    final DateTime start = startDate ?? end.subtract(const Duration(days: 7));
    
    // İlaç kayıtlarını al
    final List<MedicationLog> logs = await _databaseService.getMedicationLogsByDateRange(
      startDate: start,
      endDate: end,
      medicationId: medicationId,
    );
    
    if (logs.isEmpty) return 0.0;
    
    // Alınan dozlar
    final int takenCount = logs.where((log) => log.isTaken).length;
    
    // Uyum oranı
    return takenCount / logs.length;
  }
  
  // Tüm ilaçların uyum raporunu al
  Future<List<MedicationAdherenceReport>> getAllMedicationsAdherenceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final List<MedicationAdherenceReport> reports = [];
    
    // Tüm ilaçları al
    final List<Medication> medications = await _databaseService.getMedications();
    
    // Her ilaç için rapor oluştur
    for (final medication in medications) {
      final double adherenceRate = await getMedicationAdherenceRate(
        medication.id,
        startDate: startDate,
        endDate: endDate,
      );
      
      // İlaç kayıtlarını al
      final DateTime end = endDate ?? DateTime.now();
      final DateTime start = startDate ?? end.subtract(const Duration(days: 7));
      
      final List<MedicationLog> logs = await _databaseService.getMedicationLogsByDateRange(
        startDate: start,
        endDate: end,
        medicationId: medication.id,
      );
      
      // Atlanmış dozlar
      final int skippedCount = logs.where((log) => 
        log.isSkipped || (!log.isTaken && log.scheduledTime.isBefore(DateTime.now()))
      ).length;
      
      // Gecikmiş dozlar
      final int delayedCount = logs.where((log) => 
        log.isTaken && log.delayInMinutes != null && log.delayInMinutes! > 15
      ).length;
      
      // İlaç raporunu oluştur
      final report = MedicationAdherenceReport(
        medication: medication,
        adherenceRate: adherenceRate,
        totalDoses: logs.length,
        takenDoses: logs.where((log) => log.isTaken).length,
        skippedDoses: skippedCount,
        delayedDoses: delayedCount,
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        endDate: endDate ?? DateTime.now(),
      );
      
      reports.add(report);
    }
    
    return reports;
  }
  
  // Belirli bir ilacın günlük uyum detaylarını al
  Future<List<DailyAdherenceDetail>> getDailyAdherenceDetails(
    String medicationId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Varsayılan olarak son 7 gün
    final DateTime end = endDate ?? DateTime.now();
    final DateTime start = startDate ?? end.subtract(const Duration(days: 7));
    
    // İlaç kayıtlarını al
    final List<MedicationLog> logs = await _databaseService.getMedicationLogsByDateRange(
      startDate: start,
      endDate: end,
      medicationId: medicationId,
    );
    
    // Günlük detaylar
    final Map<DateTime, List<MedicationLog>> logsByDay = {};
    
    // Kayıtları günlere ayır
    for (final log in logs) {
      final DateTime day = DateTime(
        log.scheduledTime.year,
        log.scheduledTime.month,
        log.scheduledTime.day,
      );
      
      if (!logsByDay.containsKey(day)) {
        logsByDay[day] = [];
      }
      
      logsByDay[day]!.add(log);
    }
    
    // Günlük detayları oluştur
    final List<DailyAdherenceDetail> details = [];
    
    logsByDay.forEach((day, dayLogs) {
      final int totalDoses = dayLogs.length;
      final int takenDoses = dayLogs.where((log) => log.isTaken).length;
      final double adherenceRate = totalDoses > 0 ? takenDoses / totalDoses : 0.0;
      
      final detail = DailyAdherenceDetail(
        date: day,
        totalDoses: totalDoses,
        takenDoses: takenDoses,
        adherenceRate: adherenceRate,
        logs: dayLogs,
      );
      
      details.add(detail);
    });
    
    // Tarihe göre sırala
    details.sort((a, b) => a.date.compareTo(b.date));
    
    return details;
  }
  
  // İlaç kullanım özeti oluştur
  Future<String> generateMedicationSummary(String medicationId) async {
    // İlacı al
    final List<Medication> medications = await _databaseService.getMedications();
    final Medication medication = medications.firstWhere(
      (med) => med.id == medicationId,
      orElse: () => throw Exception('Medication not found'),
    );
    
    // Son 7 günlük uyum oranı
    final double adherenceRate = await getMedicationAdherenceRate(medicationId);
    final int adherencePercentage = (adherenceRate * 100).round();
    
    // Günlük detaylar
    final List<DailyAdherenceDetail> dailyDetails = 
        await getDailyAdherenceDetails(medicationId);
    
    // Özet oluştur
    String summary = '';
    
    // Uyum durumuna göre mesaj
    if (adherenceRate >= 0.9) {
      summary = '${medication.name} ilacınızı son 7 gündür düzenli kullanıyorsunuz. ';
      summary += 'Uyum oranınız: %$adherencePercentage. Harika!';
    } else if (adherenceRate >= 0.7) {
      summary = '${medication.name} ilacınızı son 7 günde çoğunlukla düzenli kullandınız. ';
      summary += 'Uyum oranınız: %$adherencePercentage. İyi gidiyorsunuz!';
    } else if (adherenceRate >= 0.5) {
      summary = '${medication.name} ilacınızı son 7 günde bazen kaçırdınız. ';
      summary += 'Uyum oranınız: %$adherencePercentage. Biraz daha dikkat edin.';
    } else {
      summary = '${medication.name} ilacınızı son 7 günde düzenli kullanmadınız. ';
      summary += 'Uyum oranınız: %$adherencePercentage. Daha dikkatli olmalısınız.';
    }
    
    return summary;
  }
  
  // Kullanımı en kötü olan ilaçları bul
  Future<List<MedicationAdherenceReport>> getWorstAdherenceMedications() async {
    // Tüm raporları al
    final List<MedicationAdherenceReport> reports = 
        await getAllMedicationsAdherenceReport();
    
    // Uyum oranına göre sırala (en kötüden en iyiye)
    reports.sort((a, b) => a.adherenceRate.compareTo(b.adherenceRate));
    
    // En kötü 3 ilacı döndür (ya da daha az varsa hepsini)
    return reports.take(3).toList();
  }
  
  // Genel uyum özeti oluştur (Ana sayfa için)
  Future<String> generateOverallAdherenceSummary() async {
    // Tüm ilaçların uyum raporlarını al
    final List<MedicationAdherenceReport> reports = 
        await getAllMedicationsAdherenceReport();
    
    if (reports.isEmpty) {
      return '';
    }
    
    // Genel uyum oranı
    final double overallAdherence = reports.fold(0.0, (sum, report) => sum + report.adherenceRate) / reports.length;
    final int adherencePercentage = (overallAdherence * 100).round();
    
    // İlaç alma durumunu analiz et
    final int goodMedications = reports.where((r) => r.adherenceRate >= 0.8).length;
    final int mediumMedications = reports.where((r) => r.adherenceRate >= 0.5 && r.adherenceRate < 0.8).length;
    final int poorMedications = reports.where((r) => r.adherenceRate < 0.5).length;
    
    // En kötü performanslı ilaç
    reports.sort((a, b) => a.adherenceRate.compareTo(b.adherenceRate));
    final lowestAdherenceMedication = reports.isNotEmpty ? reports.first.medication.name : null;
    
    // Özet oluştur
    String summary = '';
    
    if (overallAdherence >= 0.8) {
      summary = 'İlaçlarınızı oldukça düzenli kullanıyorsunuz. Genel uyum oranınız %$adherencePercentage. ';
      
      if (poorMedications > 0) {
        summary += 'Ancak $poorMedications ilacınızda düzensizlik var. ';
        
        if (lowestAdherenceMedication != null) {
          summary += 'Özellikle $lowestAdherenceMedication ilacını daha düzenli almanız önerilir.';
        }
      } else {
        summary += 'Harika iş, böyle devam edin!';
      }
    } else if (overallAdherence >= 0.5) {
      summary = 'İlaçlarınızı orta düzeyde düzenli kullanıyorsunuz. Genel uyum oranınız %$adherencePercentage. ';
      
      if (goodMedications > 0) {
        summary += '$goodMedications ilacı düzenli kullanıyorsunuz, ';
      }
      
      summary += 'ancak bazı ilaçlarınızı daha düzenli almanız sağlığınız için önemli. ';
      
      if (lowestAdherenceMedication != null) {
        summary += 'Özellikle $lowestAdherenceMedication ilacı için daha dikkatli olmalısınız.';
      }
    } else {
      summary = 'İlaçlarınızı düzenli kullanma konusunda zorlanıyorsunuz. Genel uyum oranınız %$adherencePercentage. ';
      
      if (goodMedications > 0) {
        summary += 'Sadece $goodMedications ilacınızı düzenli kullanıyorsunuz. ';
      }
      
      summary += 'Sağlığınız için ilaçlarınızı zamanında almayı hatırlamak önemli. ';
      summary += 'Alarmlarımız ve bildirimlerimiz size yardımcı olacaktır.';
    }
    
    return summary;
  }
}

// İlaç uyum raporu sınıfı
class MedicationAdherenceReport {
  final Medication medication;
  final double adherenceRate;
  final int totalDoses;
  final int takenDoses;
  final int skippedDoses;
  final int delayedDoses;
  final DateTime startDate;
  final DateTime endDate;
  
  MedicationAdherenceReport({
    required this.medication,
    required this.adherenceRate,
    required this.totalDoses,
    required this.takenDoses,
    required this.skippedDoses,
    required this.delayedDoses,
    required this.startDate,
    required this.endDate,
  });
  
  // Atlanmış doz yüzdesi
  double get skippedRate => totalDoses > 0 ? skippedDoses / totalDoses : 0.0;
  
  // Gecikmiş doz yüzdesi
  double get delayedRate => totalDoses > 0 ? delayedDoses / totalDoses : 0.0;
  
  // Kullanım özeti
  String get summary {
    final int adherencePercentage = (adherenceRate * 100).round();
    
    if (adherenceRate >= 0.9) {
      return '${medication.name} ilacınızı mükemmel kullanıyorsunuz (%$adherencePercentage)';
    } else if (adherenceRate >= 0.7) {
      return '${medication.name} ilacınızı iyi kullanıyorsunuz (%$adherencePercentage)';
    } else if (adherenceRate >= 0.5) {
      return '${medication.name} ilacınızı orta düzeyde kullanıyorsunuz (%$adherencePercentage)';
    } else {
      return '${medication.name} ilacınızı düzensiz kullanıyorsunuz (%$adherencePercentage)';
    }
  }
}

// Günlük uyum detayı sınıfı
class DailyAdherenceDetail {
  final DateTime date;
  final int totalDoses;
  final int takenDoses;
  final double adherenceRate;
  final List<MedicationLog> logs;
  
  DailyAdherenceDetail({
    required this.date,
    required this.totalDoses,
    required this.takenDoses,
    required this.adherenceRate,
    required this.logs,
  });
  
  // Gün başarılı mı?
  bool get isSuccessful => adherenceRate >= 0.9;
  
  // Gün kısmen başarılı mı?
  bool get isPartiallySuccessful => adherenceRate >= 0.5 && adherenceRate < 0.9;
  
  // Gün başarısız mı?
  bool get isFailed => adherenceRate < 0.5;
}