import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // TimeOfDay sınıfı burada
import 'package:flutter/widgets.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';
import 'package:medalarmm/core/services/database_service.dart';
import 'package:medalarmm/core/services/notification_service.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  List<Medication> _medications = [];
  List<MedicationLog> _medicationLogs = [];
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  List<MedicationLog> get medicationLogs => _medicationLogs;
  bool get isLoading => _isLoading;
  // İlaçları veritabanından yükle
  Future<List<Medication>> loadMedications() async {
    _setLoading(true);
    try {
      final medications = await _databaseService.getMedications();
      _medications = medications;
      notifyListeners();
      return _medications;
    } catch (e) {
      print('İlaçlar yüklenirken hata oluştu: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // İlaç kullanım kayıtlarını veritabanından yükle
  Future<void> loadMedicationLogs() async {
    _setLoading(true);
    try {
      _medicationLogs = await _databaseService.getMedicationLogs();
      notifyListeners();
    } catch (e) {
      print('İlaç kayıtları yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Belirli bir tarihe ait ilaç kullanım kayıtlarını yükle
  Future<List<MedicationLog>> loadMedicationLogsByDate({required DateTime date}) async {
    try {
      _setLoading(true);
      final logs = await _databaseService.getMedicationLogsByDate(date);
      return logs;
    } catch (e) {
      print('Tarih bazlı ilaç kayıtları yüklenirken hata oluştu: $e');
      return [];
    } finally {
      // Burada bildirimi ana thread'e taşıyarak build sürecinin tamamlanmasını sağlayalım
      Future.microtask(() {
        _setLoading(false);
      });
    }
  }
  // Belirli bir tarih aralığına ait ilaç kullanım kayıtlarını yükle
  Future<List<MedicationLog>> loadMedicationLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? medicationId,
  }) async {
    try {
      _setLoading(true);
      final logs = await _databaseService.getMedicationLogsByDateRange(
        startDate: startDate,
        endDate: endDate,
        medicationId: medicationId,
      );
      return logs;
    } catch (e) {
      print('Tarih aralığı bazlı ilaç kayıtları yüklenirken hata oluştu: $e');
      return [];
    } finally {
      // Bildirimi ana thread'e taşıyalım
      Future.microtask(() {
        _setLoading(false);
      });
    }
  }
  
  // Yeni ilaç ekle
  Future<void> addMedication(Medication medication) async {
    _setLoading(true);
    try {
      // Veritabanına kaydet
      await _databaseService.insertMedication(medication);
      
      // İlaç listesini güncelle
      _medications.add(medication);
      
      // Bildirimleri yeniden planla
      await _notificationService.scheduleAllMedicationNotifications();
      
      notifyListeners();
    } catch (e) {
      print('İlaç eklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // İlaç güncelle
  Future<void> updateMedication(Medication medication) async {
    _setLoading(true);
    try {
      // Eski ilaç bilgilerini al
      final oldMedication = _medications.firstWhere(
        (med) => med.id == medication.id,
        orElse: () => medication,
      );
      
      // Veritabanında güncelle
      await _databaseService.updateMedication(medication);
      
      // İlaç listesini güncelle
      final index = _medications.indexWhere((med) => med.id == medication.id);
      if (index != -1) {
        _medications[index] = medication;
      }
      
      // İlaç zamanlaması değiştiyse eski logları temizle ve yenilerini oluştur
      final bool timeScheduleChanged = _hasTimeScheduleChanged(oldMedication, medication);
      
      if (timeScheduleChanged) {
        await _cleanUpOldMedicationLogs(medication.id);
        
        // Burada yakın gelecek için (mevcut gün ve sonraki 7 gün) yeni loglar oluştur
        final now = DateTime.now();
        for (int i = 0; i < 8; i++) {
          final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
          await generateMedicationLogsForDate(date);
        }
      }
      
      // Bildirimleri yeniden planla
      await _notificationService.scheduleAllMedicationNotifications();
      
      notifyListeners();
    } catch (e) {
      print('İlaç güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
    // İlaç zamanlamasının değişip değişmediğini kontrol et
  bool _hasTimeScheduleChanged(Medication oldMed, Medication newMed) {
    // Farklı sayıda zaman varsa değişmiş demektir
    if (oldMed.timesOfDay.length != newMed.timesOfDay.length) {
      return true;
    }
    
    // Aynı sayıda zaman varsa, her zamanın eşleşip eşleşmediğini kontrol et
    // Önce her iki listeyi de zamanlarına göre sırala
    final List<TimeOfDay> oldTimes = List<TimeOfDay>.from(oldMed.timesOfDay)
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    
    final List<TimeOfDay> newTimes = List<TimeOfDay>.from(newMed.timesOfDay)
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    
    // Zamanları karşılaştır
    for (int i = 0; i < oldTimes.length; i++) {
      final TimeOfDay oldTime = oldTimes[i];
      final TimeOfDay newTime = newTimes[i];
      
      if (oldTime.hour != newTime.hour || oldTime.minute != newTime.minute) {
        return true;
      }
    }
    
    // Alım günleri değiştiyse
    if (oldMed.frequency == MedicationFrequency.specificDays && 
        newMed.frequency == MedicationFrequency.specificDays) {
      if (oldMed.daysOfWeek.length != newMed.daysOfWeek.length) {
        return true;
      }
      
      // Günleri sırala ve karşılaştır
      final List<DayOfWeek> oldDays = List.from(oldMed.daysOfWeek)
        ..sort((a, b) => a.index.compareTo(b.index));
      
      final List<DayOfWeek> newDays = List.from(newMed.daysOfWeek)
        ..sort((a, b) => a.index.compareTo(b.index));
      
      for (int i = 0; i < oldDays.length; i++) {
        if (oldDays[i] != newDays[i]) {
          return true;
        }
      }
    }
    
    // Kullanım sıklığı değiştiyse
    if (oldMed.frequency != newMed.frequency) {
      return true;
    }
    
    // Başlangıç veya bitiş tarihi değiştiyse
    if ((oldMed.startDate?.millisecondsSinceEpoch != newMed.startDate?.millisecondsSinceEpoch) ||
        (oldMed.endDate?.millisecondsSinceEpoch != newMed.endDate?.millisecondsSinceEpoch)) {
      return true;
    }
    
    return false;
  }
  
  // İlaca ait gelecekteki logları temizle
  Future<void> _cleanUpOldMedicationLogs(String medicationId) async {
    try {
      // Veritabanından ilgili ilaca ait gelecekteki kayıtları sil
      await _databaseService.deleteFutureMedicationLogs(medicationId);
      
      // Provider içindeki logları da güncellememiz gerekiyor
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      // Provider'daki gelecekteki kayıtları filtrele
      _medicationLogs.removeWhere((log) {
        if (log.medicationId == medicationId) {
          final logDate = DateTime(log.scheduledTime.year, log.scheduledTime.month, log.scheduledTime.day);
          return !log.isTaken && !log.isSkipped && !logDate.isBefore(startOfToday);
        }
        return false;
      });
      
      print('İlaca ait gelecekteki kayıtlar temizlendi: $medicationId');
    } catch (e) {
      print('Eski ilaç kayıtları temizlenirken hata oluştu: $e');
    }
  }

  // İlaç sil
  Future<void> deleteMedication(String id) async {
    _setLoading(true);
    try {
      // Veritabanından sil
      await _databaseService.deleteMedication(id);
      
      // İlaç listesini güncelle
      _medications.removeWhere((med) => med.id == id);
      
      // Bildirimleri yeniden planla
      await _notificationService.scheduleAllMedicationNotifications();
      
      notifyListeners();
    } catch (e) {
      print('İlaç silinirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // İlaç alındı olarak işaretle
  Future<void> markMedicationAsTaken({required String medicationId, required DateTime scheduledTime}) async {
    _setLoading(true);
    try {
      // İlgili log kaydını bul veya oluştur
      MedicationLog? log = _medicationLogs.firstWhere(
        (log) => log.medicationId == medicationId && log.scheduledTime == scheduledTime,
        orElse: () => MedicationLog(
          medicationId: medicationId,
          scheduledTime: scheduledTime,
        ),
      );
      
      // İlacı alındı olarak işaretle
      final updatedLog = log.copyWith(
        takenTime: DateTime.now(),
        isTaken: true,
      );
      
      // Veritabanına kaydet
      await _databaseService.insertMedicationLog(updatedLog);
      
      // İlaç kayıtlarını güncelle
      final index = _medicationLogs.indexWhere(
        (log) => log.id == updatedLog.id,
      );
      
      if (index != -1) {
        _medicationLogs[index] = updatedLog;
      } else {
        _medicationLogs.add(updatedLog);
      }
      
      notifyListeners();
    } catch (e) {
      print('İlaç alındı olarak işaretlenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // İlaç alınmadı olarak işaretle
  Future<void> markMedicationAsNotTaken(String logId) async {
    _setLoading(true);
    try {
      // İlgili log kaydını bul
      final index = _medicationLogs.indexWhere((log) => log.id == logId);
      if (index != -1) {
        // İlacı alınmadı olarak işaretle
        final updatedLog = _medicationLogs[index].copyWith(
          takenTime: null,
          isTaken: false,
        );
        
        // Veritabanına kaydet
        await _databaseService.updateMedicationLog(updatedLog);
        
        // İlaç kayıtlarını güncelle
        _medicationLogs[index] = updatedLog;
        
        notifyListeners();
      }
    } catch (e) {
      print('İlaç alınmadı olarak işaretlenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Belirli bir ilaca ait alınmamış dozların sayısını hesapla
  int getMissedDosesCount(String medicationId) {
    final now = DateTime.now();
    return _medicationLogs.where((log) => 
      log.medicationId == medicationId &&
      !log.isTaken &&
      log.scheduledTime.isBefore(now)
    ).length;
  }

  // İlaç uyum yüzdesini hesapla (alınan dozlar / toplam planlanan dozlar)
  double getMedicationAdherencePercentage(String medicationId) {
    final logs = _medicationLogs.where((log) => log.medicationId == medicationId).toList();
    if (logs.isEmpty) return 100.0;
    
    final takenLogs = logs.where((log) => log.isTaken).length;
    return (takenLogs / logs.length) * 100;
  }

  // ID'ye göre ilaç getir
  Future<Medication?> getMedicationById(String id) async {
    try {
      return _medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // İlaç kayıtlarını getir
  Future<List<MedicationLog>> getMedicationLogs({String? medicationId}) async {
    if (medicationId != null) {
      return _medicationLogs.where((log) => log.medicationId == medicationId).toList();
    }
    return _medicationLogs;
  }
  
  // İlacı atlandı olarak işaretle
  Future<void> markMedicationAsSkipped({
    required String medicationId, 
    required DateTime scheduledTime, 
    String? notes
  }) async {
    _setLoading(true);
    try {
      // İlgili log kaydını bul veya oluştur
      MedicationLog? log = _medicationLogs.firstWhere(
        (log) => log.medicationId == medicationId && log.scheduledTime == scheduledTime,
        orElse: () => MedicationLog(
          medicationId: medicationId,
          scheduledTime: scheduledTime,
        ),
      );
      
      // İlacı atlandı olarak işaretle
      final updatedLog = log.copyWith(
        isSkipped: true,
        isTaken: false,
        notes: notes ?? log.notes,
      );
      
      // Veritabanına kaydet
      await _databaseService.insertMedicationLog(updatedLog);
      
      // İlaç kayıtlarını güncelle
      final index = _medicationLogs.indexWhere((l) => l.id == updatedLog.id);
      if (index != -1) {
        _medicationLogs[index] = updatedLog;
      } else {
        _medicationLogs.add(updatedLog);
      }
      
      notifyListeners();
    } catch (e) {
      print('İlaç atlandı olarak işaretlenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  // İlaç için seçilen tarihte otomatik log oluştur
  Future<void> generateMedicationLogsForDate(DateTime date) async {
    _setLoading(true);
    try {
      // Tüm aktif ilaçları al
      if (_medications.isEmpty) {
        await loadMedications();
      }
      
      final medications = _medications.where((med) => med.isActive).toList();
      
      // Mevcut logları al
      final existingLogs = await _databaseService.getMedicationLogsByDate(date);
      
      for (final medication in medications) {
        // İlacın başlangıç ve bitiş tarihlerini kontrol et
        final startDate = medication.startDate;
        final endDate = medication.endDate;
        
        // Eğer belirtilen tarih, ilacın kullanım aralığında değilse atla
        if (startDate != null && date.isBefore(startDate)) continue;
        if (endDate != null && date.isAfter(endDate)) continue;
        
        // İlacın hangi günlerde alınacağını kontrol et
        if (medication.frequency == MedicationFrequency.specificDays) {
          final dayOfWeek = DayOfWeek.values[date.weekday % 7]; // 0-indexed
          if (!medication.daysOfWeek.contains(dayOfWeek)) continue;
        }
          // İlacın gün içinde alınacağı saatler
        for (final timeOfDay in medication.timesOfDay) {
          // Planlanmış zaman
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            timeOfDay.hour,
            timeOfDay.minute,
          );
          
          // Bu log daha önce oluşturulmuş mu?
          final existingLog = existingLogs.firstWhere(
            (log) => log.medicationId == medication.id && 
                    log.scheduledTime.hour == timeOfDay.hour && 
                    log.scheduledTime.minute == timeOfDay.minute,
            orElse: () => MedicationLog(
              medicationId: medication.id,
              scheduledTime: scheduledTime,
            ),
          );
          
          // Eğer log oluşturulmamışsa veya listeye eklenmemişse, ekle
          if (existingLogs.indexWhere((log) => log.id == existingLog.id) == -1) {
            await _databaseService.insertMedicationLog(existingLog);
            _medicationLogs.add(existingLog);
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('İlaç logları oluşturulurken hata: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Yükleme durumunu güncelle
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Aynı değeri tekrar ayarlamaya gerek yok
    _isLoading = loading;
    
    // WidgetsBinding.instance.addPostFrameCallback kullanarak
    // notifyListeners'ı mevcut frame bittikten sonra çağıralım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}