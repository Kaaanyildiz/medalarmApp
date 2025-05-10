import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback için ekleyelim
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/core/services/database_service.dart';
import 'package:medalarmm/features/notifications/models/notification_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();
  
  // AudioPlayer örneği
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Bildirim ve alarm ayarları
  NotificationSettings _settings = NotificationSettings();
  
  // Bildirim ayarlarını güncelle
  void updateSettings(NotificationSettings settings) {
    _settings = settings;
  }
  
  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }
  
  // Bildirim yanıtı için callback
  Future<void> _onNotificationResponse(NotificationResponse response) async {
    debugPrint('Bildirim yanıtı: ${response.payload}');
    
    // Eğer kullanıcı alarmları aktif ettiyse ve payload "play_alarm" ise alarm çal
    if (response.payload == 'play_alarm' && _settings.enableAlarms) {
      await playMedicationAlarm();
    }
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool playAlarm = false,
  }) async {
    // Bildirimler devre dışı bırakıldıysa hiçbir şey yapma
    if (!_settings.enableNotifications) return;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_channel_id',
      'Medication Reminders',
      channelDescription: 'Medication reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );

    // Hem bildirimler hem de alarmlar aktifse ve alarm çalma isteği varsa zil sesini çal
    if (playAlarm && _settings.enableAlarms) {
      await playMedicationAlarm();
    }
  }
  
  // Alarm sesini çalmak için metod
  Future<void> playMedicationAlarm() async {
    try {
      // Alarm tipi seçimi
      AlarmType alarmType = _settings.alarmType;
      
      // Ses dosyası yolu
      String soundPath;
      double volume;
      bool loop;
      
      switch (alarmType) {
        case AlarmType.medicationAlarm:
          soundPath = 'alarm.mp3'; // Alarm sesi
          volume = 1.0;
          loop = true;
          break;
          
        case AlarmType.emergencyAlarm:
          soundPath = 'emergency.mp3'; // Acil durum sesi
          volume = 1.0;
          loop = true;
          break;
          
        case AlarmType.gentleAlarm:
          soundPath = 'gentle.mp3'; // Nazik alarm
          volume = 0.7;
          loop = true;
          break;
          
        case AlarmType.customAlarm:
          soundPath = 'notification.mp3'; // Bildirim sesi
          volume = 0.8;
          loop = true;
          break;
      }
      
      // Ses dosyasını çal
      await _audioPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(AssetSource(soundPath));
      
      // Alarm süresi sonunda otomatik olarak durdur
      if (_settings.alarmDuration > 0) {
        Future.delayed(Duration(seconds: _settings.alarmDuration), () {
          stopMedicationAlarm();
        });
      }
      
      // Titreşim de etkinleştirilmişse
      if (_settings.vibrate) {
        HapticFeedback.vibrate(); // Titreşim için HapticFeedback kullanıyoruz
      }
    } catch (e) {
      debugPrint('Alarm çalınırken hata: $e');
    }
  }
  
  // Çalan alarmı durdurmak için metod
  Future<void> stopMedicationAlarm() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Alarm durdurulurken hata: $e');
    }
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool playAlarm = true,
  }) async {
    // Bildirimler devre dışı bırakıldıysa hiçbir şey yapma
    if (!_settings.enableNotifications) return;
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel_id',
          'Medication Reminders',
          channelDescription: 'Medication reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: playAlarm && _settings.enableAlarms ? 'play_alarm' : 'no_alarm',
    );
    
    // Tekrarlanan hatırlatıcı ayarlandıysa ek bir bildirim planla
    if (_settings.reminderInterval > 0) {
      final DateTime reminderTime = scheduledDate.add(
        Duration(minutes: _settings.reminderInterval)
      );
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id + 100000, // Orijinal ID'den farklı bir ID kullan
        'Hatırlatma: $title',
        'Bu ilacı henüz almadınız: $body',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminder_channel_id',
            'Medication Reminder Alerts',
            channelDescription: 'Medication second reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: playAlarm && _settings.enableAlarms ? 'play_alarm' : 'no_alarm',
      );
    }
  }
  
  // Tüm ilaç bildirimlerini planla
  Future<void> scheduleAllMedicationNotifications() async {
    try {
      // Önce tüm bildirimleri iptal et
      await cancelAllNotifications();
      
      // Bildirimler devre dışı bırakıldıysa hiçbir şey yapma
      if (!_settings.enableNotifications) return;
      
      // Tüm ilaçları al
      final List<Medication> medications = await _databaseService.getMedications();
      
      // Her ilaç için bildirim oluştur
      for (final medication in medications) {
        // İlaç aktif değilse atla
        if (!medication.isActive) continue;
        
        // İlaç hatırlatma zamanları
        for (final time in medication.timesOfDay) {
          // Bugün için zamanı ayarla
          final DateTime now = DateTime.now();
          DateTime scheduledTime = DateTime(
            now.year, 
            now.month, 
            now.day,
            time.hour,
            time.minute,
          );
            // Eğer zaman geçmişse bir sonraki günü ayarla
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }

          // Bildirimi planla
          await scheduleNotification(
            id: '${medication.id}-${time.hour}-${time.minute}'.hashCode,
            title: 'İlaç Hatırlatıcı: ${medication.name}',
            body: '${medication.dosage} ${medication.stockUnit} ${medication.name} alma zamanı geldi.',
            scheduledDate: scheduledTime,
            playAlarm: true,
          );
        }
      }
    } catch (e) {
      debugPrint('İlaç bildirimleri planlanırken hata: $e');
    }
  }
  
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    // İlgili hatırlatma bildirimini de iptal et
    await flutterLocalNotificationsPlugin.cancel(id + 100000);
  }
  
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
