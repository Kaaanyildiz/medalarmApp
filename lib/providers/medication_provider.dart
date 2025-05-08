import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:medalarmm/models/medication.dart';
import 'package:medalarmm/models/medication_log.dart';
import 'package:medalarmm/services/database_service.dart';
import 'package:medalarmm/services/notification_service.dart';

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
      // Veritabanında güncelle
      await _databaseService.updateMedication(medication);
      
      // İlaç listesini güncelle
      final index = _medications.indexWhere((med) => med.id == medication.id);
      if (index != -1) {
        _medications[index] = medication;
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