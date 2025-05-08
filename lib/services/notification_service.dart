import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medalarmm/models/medication.dart';
import 'package:medalarmm/services/database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();
  
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          debugPrint('Bildirim tıklandı: ${response.payload}');
        }
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
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
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
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
    );
  }
  
  // Tüm ilaç bildirimlerini planla
  Future<void> scheduleAllMedicationNotifications() async {
    try {
      // Önce tüm bildirimleri iptal et
      await cancelAllNotifications();
      
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
          );
        }
      }
    } catch (e) {
      debugPrint('İlaç bildirimleri planlanırken hata: $e');
    }
  }
  
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
