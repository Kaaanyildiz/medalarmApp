class NotificationSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final AlarmType alarmType;
  final int reminderInterval;
  final int alarmDuration;  // Alarm süresi (saniye)

  const NotificationSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.alarmType = AlarmType.medicationAlarm,
    this.reminderInterval = 15,
    this.alarmDuration = 30,  // Varsayılan 30 saniye
  });

  // Eski isimlerle uyumluluk için getter'lar
  bool get enableNotifications => notificationsEnabled;
  bool get enableAlarms => soundEnabled;
  bool get vibrate => vibrationEnabled;

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    AlarmType? alarmType,
    int? reminderInterval,
    int? alarmDuration,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      alarmType: alarmType ?? this.alarmType,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      alarmDuration: alarmDuration ?? this.alarmDuration,
    );
  }

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'alarmType': alarmType.index,
      'reminderInterval': reminderInterval,
      'alarmDuration': alarmDuration,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      alarmType: AlarmType.values[json['alarmType'] ?? 0],
      reminderInterval: json['reminderInterval'] ?? 15,
      alarmDuration: json['alarmDuration'] ?? 30,
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
