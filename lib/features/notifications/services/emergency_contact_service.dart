// filepath: c:\Users\Msi\medalarm\lib\services\emergency_contact_service.dart
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';
import 'package:medalarmm/core/models/user_profile.dart';
import 'package:medalarmm/core/services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactService {
  final DatabaseService _databaseService = DatabaseService();

  // Belirli bir kullanıcı için ilacı kaçırma durumlarını kontrol et
  Future<void> checkMissedMedications() async {
    try {
      // Kullanıcı profili
      final UserProfile? userProfile = await _databaseService.getUserProfile();
      
      if (userProfile == null) return;
      
      // Eğer acil durum bildirimleri etkin değilse işlemi sonlandır
      if (!userProfile.emergencySettings.enableEmergencyAlerts) return;
      
      // Acil durum ayarları
      final threshold = userProfile.emergencySettings.missedDosesThreshold;
      final medicationsToMonitor = userProfile.emergencySettings.medicationsToMonitor;
      
      // Eğer izlenecek ilaç yoksa işlemi sonlandır
      if (medicationsToMonitor.isEmpty) return;
      
      // Son 7 gün içindeki ilaç kayıtlarını al
      final DateTime now = DateTime.now();
      final DateTime weekAgo = now.subtract(const Duration(days: 7));
      
      // İlaçları al
      final List<Medication> medications = await _databaseService.getMedications();
      
      // İzlenecek ilaçlar listesi
      final List<Medication> monitoredMedications = medications
          .where((medication) => 
              medicationsToMonitor.contains(medication.id) || 
              medicationsToMonitor.isEmpty // Eğer izlenecek ilaç listesi boşsa tüm ilaçlar izlenir
          )
          .toList();
      
      // Her izlenen ilaç için kaçırılan dozları kontrol et
      for (final medication in monitoredMedications) {
        // İlaç kayıtlarını al
        final List<MedicationLog> logs = await _databaseService.getMedicationLogsByDateRange(
          startDate: weekAgo,
          endDate: now,
          medicationId: medication.id,
        );
        
        // Kaçırılan dozlar (alınmayan ve atlanmayan, zamanı geçmiş dozlar)
        final List<MedicationLog> missedLogs = logs
            .where((log) => 
                !log.isTaken && 
                !log.isSkipped && 
                log.scheduledTime.isBefore(now)
            )
            .toList();
        
        // Eğer kaçırılan doz sayısı eşiği geçtiyse acil durum bildirimi gönder
        if (missedLogs.length >= threshold) {
          await _sendEmergencyNotifications(userProfile, medication, missedLogs);
        }
      }
    } catch (e) {
      print('Acil durum kontrolü yapılırken hata: $e');
    }
  }
  
  // Acil durum bildirimleri gönder
  Future<void> _sendEmergencyNotifications(
    UserProfile userProfile, 
    Medication medication,
    List<MedicationLog> missedLogs,
  ) async {
    // Acil durum kişileri
    final List<EmergencyContact> contacts = userProfile.emergencyContacts
        .where((contact) => contact.canReceiveAlerts)
        .toList();
    
    if (contacts.isEmpty) return;
    
    // Bildirim içeriği oluştur
    final String patientName = userProfile.name;
    final String medicationName = medication.name;
    final int missedCount = missedLogs.length;
    
    final String subject = 'Acil Durum: $patientName İlaç Uyarısı';
    final String body = '''
$patientName adlı kişi, $medicationName ilacını son zamanlarda $missedCount kez almayı unuttu.

Bu bir otomatik bildirimdir. Lütfen $patientName ile iletişime geçin ve ilacını alıp almadığını kontrol edin.

İlaç alınması gereken zamanlar:
${_formatMissedTimes(missedLogs)}

Bu bildirim, MedAlarm uygulaması tarafından gönderilmiştir.
''';
    
    // Her acil durum kişisine bildirim gönder
    for (final contact in contacts) {
      if (contact.email != null && contact.email!.isNotEmpty) {
        await _sendEmail(contact.email!, subject, body);
      }
      
      if (contact.phoneNumber.isNotEmpty) {
        await _sendSMS(contact.phoneNumber, body);
      }
    }
  }
  
  // E-posta gönder
  Future<void> _sendEmail(String emailAddress, String subject, String body) async {
    try {
      final emailMessage = Email(
        body: body,
        subject: subject,
        recipients: [emailAddress],
        isHTML: false,
      );

      await FlutterEmailSender.send(emailMessage);
    } catch (e) {
      print('E-posta gönderilirken hata: $e');
    }
  }
  
  // SMS gönder
  Future<void> _sendSMS(String phoneNumber, String body) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': body},
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      print('SMS gönderilirken hata: $e');
    }
  }
  
  // Kaçırılan dozları formatlı metin olarak göster
  String _formatMissedTimes(List<MedicationLog> missedLogs) {
    return missedLogs.map((log) => 
      '- ${log.scheduledTime.day}/${log.scheduledTime.month}/${log.scheduledTime.year} '
      '${log.scheduledTime.hour}:${log.scheduledTime.minute.toString().padLeft(2, '0')}'
    ).join('\n');
  }
}