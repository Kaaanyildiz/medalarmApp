import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';
import 'package:medalarmm/core/models/user_profile.dart';

class DatabaseService {
  static const String _medicationsKey = 'medications';
  static const String _medicationLogsKey = 'medication_logs';
  static const String _userProfileKey = 'user_profile';

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Shared Preferences örneği
  SharedPreferences? _prefs;

  // Veritabanını başlat
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // İlaçları getir
  Future<List<Medication>> getMedications() async {
    if (_prefs == null) await init();
    final String? medicationsJson = _prefs!.getString(_medicationsKey);

    if (medicationsJson == null) return [];

    List<dynamic> medicationsList = jsonDecode(medicationsJson);
    return medicationsList.map((e) => Medication.fromJson(e)).toList();
  }

  // İlaç ekle
  Future<void> addMedication(Medication medication) async {
    if (_prefs == null) await init();
    
    List<Medication> medications = await getMedications();
    medications.add(medication);
    
    await _saveMedications(medications);
  }

  // İlaç güncelle
  Future<void> updateMedication(Medication updatedMedication) async {
    if (_prefs == null) await init();
    
    List<Medication> medications = await getMedications();
    int index = medications.indexWhere((m) => m.id == updatedMedication.id);
    
    if (index != -1) {
      medications[index] = updatedMedication;
      await _saveMedications(medications);
    }
  }

  // İlaç sil
  Future<void> deleteMedication(String medicationId) async {
    if (_prefs == null) await init();
    
    List<Medication> medications = await getMedications();
    medications.removeWhere((m) => m.id == medicationId);
    
    await _saveMedications(medications);
    
    // İlgili ilaç kayıtlarını da sil
    List<MedicationLog> logs = await getMedicationLogs();
    logs.removeWhere((log) => log.medicationId == medicationId);
    
    await _saveMedicationLogs(logs);
  }

  // İlaçları kaydet
  Future<void> _saveMedications(List<Medication> medications) async {
    if (_prefs == null) await init();
    
    List<Map<String, dynamic>> medicationsJson = 
        medications.map((e) => e.toJson()).toList();
    
    await _prefs!.setString(_medicationsKey, jsonEncode(medicationsJson));
  }

  // İlaç kayıtlarını getir
  Future<List<MedicationLog>> getMedicationLogs({String? medicationId}) async {
    if (_prefs == null) await init();
    
    final String? logsJson = _prefs!.getString(_medicationLogsKey);
    
    if (logsJson == null) return [];
    
    List<dynamic> logsList = jsonDecode(logsJson);
    List<MedicationLog> logs = logsList.map((e) => MedicationLog.fromJson(e)).toList();
    
    if (medicationId != null) {
      logs = logs.where((log) => log.medicationId == medicationId).toList();
    }
    
    return logs;
  }

  // İlaç kaydı ekle
  Future<void> addMedicationLog(MedicationLog log) async {
    if (_prefs == null) await init();
    
    List<MedicationLog> logs = await getMedicationLogs();
    logs.add(log);
    
    await _saveMedicationLogs(logs);
  }

  // İlaç kaydı güncelle
  Future<void> updateMedicationLog(MedicationLog updatedLog) async {
    if (_prefs == null) await init();
    
    List<MedicationLog> logs = await getMedicationLogs();
    int index = logs.indexWhere((log) => log.id == updatedLog.id);
    
    if (index != -1) {
      logs[index] = updatedLog;
      await _saveMedicationLogs(logs);
    }
  }

  // İlaç kaydı ekle
  Future<void> insertMedicationLog(MedicationLog log) async {
    return addMedicationLog(log);
  }

  // İlaç ekle - alternatif isim, uyumluluk için
  Future<void> insertMedication(Medication medication) async {
    return addMedication(medication);
  }
  
  // Belirli bir tarih aralığındaki ilaç kayıtlarını getir
  Future<List<MedicationLog>> getMedicationLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? medicationId,
  }) async {
    List<MedicationLog> logs = await getMedicationLogs(medicationId: medicationId);
    
    return logs.where((log) {
      final date = log.scheduledTime;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
             date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
  
  // Belirli bir tarihteki ilaç kayıtlarını getir
  Future<List<MedicationLog>> getMedicationLogsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return getMedicationLogsByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Kullanıcı profilini getir
  Future<UserProfile?> getUserProfile() async {
    if (_prefs == null) await init();
    
    final String? profileJson = _prefs!.getString(_userProfileKey);
    
    if (profileJson == null) return null;
    
    Map<String, dynamic> profileMap = jsonDecode(profileJson);
    return UserProfile.fromJson(profileMap);
  }

  // Kullanıcı profilini kaydet
  Future<void> saveUserProfile(UserProfile profile) async {
    if (_prefs == null) await init();
    
    Map<String, dynamic> profileJson = profile.toJson();
    
    await _prefs!.setString(_userProfileKey, jsonEncode(profileJson));
  }

  // Veritabanını temizle (test için)
  Future<void> clearDatabase() async {
    if (_prefs == null) await init();
    
    await _prefs!.remove(_medicationsKey);
    await _prefs!.remove(_medicationLogsKey);
    await _prefs!.remove(_userProfileKey);
  }

  // İlaç kayıtlarını kaydet
  Future<void> _saveMedicationLogs(List<MedicationLog> logs) async {
    if (_prefs == null) await init();
    
    List<Map<String, dynamic>> logsJson = logs.map((e) => e.toJson()).toList();
    
    await _prefs!.setString(_medicationLogsKey, jsonEncode(logsJson));
  }
  
  // Belirli bir ilaca ait gelecekteki alınmamış logları temizle
  Future<void> deleteFutureMedicationLogs(String medicationId) async {
    if (_prefs == null) await init();
    
    // Tüm kayıtları al
    List<MedicationLog> logs = await getMedicationLogs();
    
    // Bugünün başlangıcı
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    // Gelecekteki ve alınmamış/atlanmamış kayıtları filtrele
    logs.removeWhere((log) {
      // Eğer bu ilaca ait bir kayıt ise
      if (log.medicationId == medicationId) {
        // İlaç zamanının başlangıcını al (saat-dakika olmadan)
        final logDate = DateTime(log.scheduledTime.year, log.scheduledTime.month, log.scheduledTime.day);
        
        // Eğer log bugün veya gelecekte ise VE alınmadıysa/atlanmadıysa sil
        return !log.isTaken && !log.isSkipped && !logDate.isBefore(startOfToday);
      }
      // Diğer ilaçların kayıtlarına dokunma
      return false;
    });
    
    // Güncellenmiş kayıtları kaydet
    await _saveMedicationLogs(logs);
  }
}