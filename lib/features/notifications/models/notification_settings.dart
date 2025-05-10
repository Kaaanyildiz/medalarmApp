class NotificationSettings {
  final bool enableNotifications; // Bildirimleri etkinleştirme
  final bool enableAlarms; // Alarmları etkinleştirme
  final int alarmDuration; // Alarm süresi (saniye)
  final AlarmType alarmType; // Alarm tipi
  final bool vibrate; // Titreşim etkinleştirme
  final int reminderInterval; // Hatırlatma aralığı (dakika olarak, örn. 5 dakika sonra tekrar hatırlat)

  NotificationSettings({
    this.enableNotifications = true,
    this.enableAlarms = true,
    this.alarmDuration = 30, // 30 saniye varsayılan
    this.alarmType = AlarmType.medicationAlarm,
    this.vibrate = true,
    this.reminderInterval = 5, // 5 dakika varsayılan
  });

  NotificationSettings copyWith({
    bool? enableNotifications,
    bool? enableAlarms,
    int? alarmDuration,
    AlarmType? alarmType,
    bool? vibrate,
    int? reminderInterval,
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAlarms: enableAlarms ?? this.enableAlarms,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      alarmType: alarmType ?? this.alarmType,
      vibrate: vibrate ?? this.vibrate,
      reminderInterval: reminderInterval ?? this.reminderInterval,
    );
  }

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enableAlarms': enableAlarms,
      'alarmDuration': alarmDuration,
      'alarmType': alarmType.index,
      'vibrate': vibrate,
      'reminderInterval': reminderInterval,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      enableAlarms: json['enableAlarms'] ?? true,
      alarmDuration: json['alarmDuration'] ?? 30,
      alarmType: AlarmType.values[json['alarmType'] ?? 0],
      vibrate: json['vibrate'] ?? true,
      reminderInterval: json['reminderInterval'] ?? 5,
    );
  }
}

// Alarm türü - farklı alarm sesleri için
enum AlarmType {
  medicationAlarm, // İlaç hatırlatıcı alarmı (varsayılan)
  emergencyAlarm, // Acil durum alarmı (daha yüksek sesli)
  gentleAlarm, // Nazik alarm (daha yumuşak sesli)
  customAlarm, // Özel alarm (kullanıcının seçtiği)
}
