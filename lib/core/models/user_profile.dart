import 'package:medalarmm/features/notifications/models/notification_settings.dart';

class UserProfile {
  final String name;
  final DateTime? dateOfBirth;
  final double? weight;
  final double? height;
  final List<EmergencyContact> emergencyContacts;
  final Map<String, String> allergies;
  final Map<String, String> medicalConditions;
  final Map<String, String> healthNotes; // Eklenen: Genel sağlık notları
  final EmergencyNotificationSettings emergencySettings; // Eklenen: Acil durum bildirimleri ayarları
  final NotificationSettings notificationSettings; // Eklenen: Bildirim ve alarm ayarları

  UserProfile({
    required this.name,
    this.dateOfBirth,
    this.weight,
    this.height,
    List<EmergencyContact>? emergencyContacts,
    Map<String, String>? allergies,
    Map<String, String>? medicalConditions,
    Map<String, String>? healthNotes,
    EmergencyNotificationSettings? emergencySettings,
    NotificationSettings? notificationSettings,
  })  : emergencyContacts = emergencyContacts ?? [],
        allergies = allergies ?? {},
        medicalConditions = medicalConditions ?? {},
        healthNotes = healthNotes ?? {},
        emergencySettings = emergencySettings ?? EmergencyNotificationSettings(),
        notificationSettings = notificationSettings ?? NotificationSettings();

  UserProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    List<EmergencyContact>? emergencyContacts,
    Map<String, String>? allergies,
    Map<String, String>? medicalConditions,
    Map<String, String>? healthNotes,
    EmergencyNotificationSettings? emergencySettings,
    NotificationSettings? notificationSettings,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      healthNotes: healthNotes ?? this.healthNotes,
      emergencySettings: emergencySettings ?? this.emergencySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  // Kullanıcı yaşını hesapla
  int? get age {
    if (dateOfBirth == null) return null;

    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;

    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }

    return age;
  }

  // Vücut kitle indeksi hesapla
  double? get bmi {
    if (weight == null || height == null || height == 0) return null;
    return weight! / ((height! / 100) * (height! / 100)); // Height is in cm
  }

  // Tıbbi durumu getir (uyumluluğu korumak için)
  String? get medicalCondition {
    if (medicalConditions.isEmpty) return null;
    return medicalConditions.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  // Sağlık notlarını getir (uyumluluğu korumak için)
  String? get notes {
    if (healthNotes.isEmpty) return null;
    return healthNotes.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'weight': weight,
      'height': height,
      'emergencyContacts':
          emergencyContacts.map((contact) => contact.toJson()).toList(),
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'healthNotes': healthNotes,
      'emergencySettings': emergencySettings.toJson(),
      'notificationSettings': notificationSettings.toJson(),
    };
  }
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<EmergencyContact> contacts = [];
    if (json['emergencyContacts'] != null) {
      contacts = (json['emergencyContacts'] as List)
          .map((contactJson) => EmergencyContact.fromJson(contactJson))
          .toList();
    }

    return UserProfile(
      name: json['name'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      weight: json['weight'],
      height: json['height'],
      emergencyContacts: contacts,
      allergies: json['allergies'] != null
          ? Map<String, String>.from(json['allergies'])
          : {},
      medicalConditions: json['medicalConditions'] != null
          ? Map<String, String>.from(json['medicalConditions'])
          : {},
      healthNotes: json['healthNotes'] != null
          ? Map<String, String>.from(json['healthNotes'])
          : {},
      emergencySettings: json['emergencySettings'] != null
          ? EmergencyNotificationSettings.fromJson(json['emergencySettings'])
          : EmergencyNotificationSettings(),
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettings.fromJson(json['notificationSettings']) 
          : NotificationSettings(),
    );
  }
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String? relationship;
  final String? email; // Eklenen: Email adresi
  final bool canReceiveAlerts; // Eklenen: Uyarı gönderilsin mi?
  final bool notifyOnMissedDoses; // Eklenen: Kaçırılan dozlar için bildirim

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.relationship,
    this.email,
    this.canReceiveAlerts = false,
    this.notifyOnMissedDoses = false,
  });

  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? relationship,
    String? email,
    bool? canReceiveAlerts,
    bool? notifyOnMissedDoses,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      canReceiveAlerts: canReceiveAlerts ?? this.canReceiveAlerts,
      notifyOnMissedDoses: notifyOnMissedDoses ?? this.notifyOnMissedDoses,
    );
  }

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'email': email,
      'canReceiveAlerts': canReceiveAlerts,
      'notifyOnMissedDoses': notifyOnMissedDoses,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relationship: json['relationship'],
      email: json['email'],
      canReceiveAlerts: json['canReceiveAlerts'] ?? false,
      notifyOnMissedDoses: json['notifyOnMissedDoses'] ?? false,
    );
  }
}

// Yeni eklenen: Acil durum bildirimleri ayarları
class EmergencyNotificationSettings {
  final bool enableEmergencyAlerts; // Acil durum bildirimleri etkin mi?
  final int missedDosesThreshold; // Kaç doz kaçırınca bildirim gönderilsin
  final List<String> medicationsToMonitor; // Hangi ilaçlar izlensin

  EmergencyNotificationSettings({
    this.enableEmergencyAlerts = false,
    this.missedDosesThreshold = 3, // Varsayılan: 3 doz kaçırılırsa
    List<String>? medicationsToMonitor,
  }) : medicationsToMonitor = medicationsToMonitor ?? [];

  EmergencyNotificationSettings copyWith({
    bool? enableEmergencyAlerts,
    int? missedDosesThreshold,
    List<String>? medicationsToMonitor,
  }) {
    return EmergencyNotificationSettings(
      enableEmergencyAlerts: enableEmergencyAlerts ?? this.enableEmergencyAlerts,
      missedDosesThreshold: missedDosesThreshold ?? this.missedDosesThreshold,
      medicationsToMonitor: medicationsToMonitor ?? this.medicationsToMonitor,
    );
  }

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'enableEmergencyAlerts': enableEmergencyAlerts,
      'missedDosesThreshold': missedDosesThreshold,
      'medicationsToMonitor': medicationsToMonitor,
    };
  }

  factory EmergencyNotificationSettings.fromJson(Map<String, dynamic> json) {
    return EmergencyNotificationSettings(
      enableEmergencyAlerts: json['enableEmergencyAlerts'] ?? false,
      missedDosesThreshold: json['missedDosesThreshold'] ?? 3,
      medicationsToMonitor: json['medicationsToMonitor'] != null
          ? List<String>.from(json['medicationsToMonitor'])
          : [],
    );
  }
}