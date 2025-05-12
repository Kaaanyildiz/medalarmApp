import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
import 'package:medalarmm/core/models/user_profile.dart';
import 'package:medalarmm/features/notifications/models/notification_settings.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/profile/providers/user_profile_provider.dart';
import 'package:medalarmm/features/profile/widgets/bmi_gauge_widget.dart';
import 'package:medalarmm/features/onboarding/providers/locale_provider.dart';
import 'package:medalarmm/common/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _medicalConditionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Track the current locale for change detection
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    // Register this object as an observer for system changes
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    // Initialize current locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentLocale = Provider.of<LocaleProvider>(context, listen: false).locale;
        });
      }
    });
  }

  @override
  void dispose() {
    // Unregister the observer when the state is disposed
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _ageController.dispose();
    _medicalConditionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the current locale
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    // If locale has changed, update the UI
    if (_currentLocale?.languageCode != localeProvider.locale.languageCode) {
      _currentLocale = localeProvider.locale;
      
      // Force locale update by rebuilding AppLocalizations
      AppLocalizations.delegate.load(localeProvider.locale);
      
      // Force a complete UI rebuild
      setState(() {});
      
      // Force rebuild of all dependent widgets after frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // Implement didChangeAppLifecycleState to detect app coming to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, check if locale has changed
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      if (_currentLocale?.languageCode != localeProvider.locale.languageCode) {
        _currentLocale = localeProvider.locale;
        setState(() {});
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    await provider.loadUserProfile();
    
    if (provider.userProfile != null) {
      _nameController.text = provider.userProfile!.name;
      _ageController.text = provider.userProfile!.age.toString();
      _medicalConditionController.text = provider.userProfile!.medicalCondition ?? '';
      _notesController.text = provider.userProfile!.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final loc = AppLocalizations.of(context);
        
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(loc.translate('profile')),
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: const Icon(Icons.person),
                    text: loc.translate('personal_info'),
                  ),
                  Tab(
                    icon: const Icon(Icons.favorite),
                    text: loc.translate('health_summary'),
                  ),
                  Tab(
                    icon: const Icon(Icons.settings),
                    text: loc.translate('settings'),
                  ),
                ],
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
              ),
            ),
            body: Consumer<UserProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingIndicator();
                }

                return TabBarView(
                  children: [
                    // Personal Information Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileInfoSection(provider),
                          const SizedBox(height: AppDimens.paddingL),
                          _buildEmergencyContactsSection(provider),
                        ],
                      ),
                    ),
                    
                    // Health Summary Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHealthSummaryCard(provider),
                        ],
                      ),
                    ),
                    
                    // Settings Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationSettingsCard(provider),
                          const SizedBox(height: AppDimens.paddingM),
                          const Divider(),
                          const SizedBox(height: AppDimens.paddingM),
                          _buildLanguageSettingsCard(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoSection(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('personal_info'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.paddingM),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(provider.userProfile?.name ?? loc.translate('name_not_entered')),
              subtitle: Text(provider.userProfile?.age != null 
                ? loc.translate('age_years').replaceAll('{age}', provider.userProfile!.age.toString())
                : loc.translate('please_enter_age')),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.medical_information),
              title: Text(loc.translate('health_condition')),
              subtitle: Text(provider.userProfile?.medicalCondition ?? '-'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.height),
              title: Text(loc.translate('height')),
              subtitle: Text(provider.userProfile?.height != null 
                ? '${provider.userProfile!.height} cm'
                : loc.translate('add_height_weight')),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: Text(loc.translate('weight')),
              subtitle: Text(provider.userProfile?.weight != null 
                ? '${provider.userProfile!.weight} kg'
                : loc.translate('add_height_weight')),
            ),
            const SizedBox(height: AppDimens.paddingM),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(provider),
                icon: const Icon(Icons.edit),
                label: Text(loc.translate('edit_profile')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummaryCard(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    final medicationProvider = Provider.of<MedicationProvider>(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('health_summary'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.paddingM),
            if (provider.userProfile?.height != null && provider.userProfile?.weight != null)
              Column(
                children: [
                  BMIGaugeWidget(
                    bmi: _calculateBMI(provider.userProfile!.height!, provider.userProfile!.weight!),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(
                    loc.translate('body_measurements'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ListTile(
                    title: Text(loc.translate('height')),
                    trailing: Text('${provider.userProfile!.height} cm'),
                  ),
                  ListTile(
                    title: Text(loc.translate('weight')),
                    trailing: Text('${provider.userProfile!.weight} kg'),
                  ),
                ],
              )
            else
              Center(
                child: Column(
                  children: [
                    Text(
                      loc.translate('health_metrics_not_available'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    ElevatedButton(
                      onPressed: () => _showEditProfileDialog(provider),
                      child: Text(loc.translate('add_height_weight')),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Text(
              loc.translate('medication_statistics'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ListTile(
              title: Text(loc.translate('active_medications')),
              trailing: Text(medicationProvider.activeMedicationsCount.toString()),
            ),
            ListTile(
              title: Text(loc.translate('adherence_rate')),
              trailing: Text('${medicationProvider.adherenceRate.toStringAsFixed(1)}%'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('notification_and_alarm_settings'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.paddingM),
            SwitchListTile(
              title: Text(loc.translate('notifications')),
              subtitle: Text(loc.translate('notification_description')),
              value: provider.notificationSettings.notificationsEnabled,
              onChanged: (bool value) {
                provider.updateNotificationSettings(
                  provider.notificationSettings.copyWith(notificationsEnabled: value),
                );
              },
            ),
            const Divider(),
            SwitchListTile(
              title: Text(loc.translate('sound_alarms')),
              subtitle: Text(loc.translate('sound_alarms_description')),
              value: provider.notificationSettings.soundEnabled,
              onChanged: (bool value) {
                provider.updateNotificationSettings(
                  provider.notificationSettings.copyWith(soundEnabled: value),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: Text(loc.translate('alarm_type')),
              subtitle: Text(_getAlarmTypeDescription(provider.notificationSettings.alarmType)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAlarmTypeDialog(provider),
            ),
            const Divider(),
            SwitchListTile(
              title: Text(loc.translate('vibration')),
              subtitle: Text(loc.translate('vibration_description')),
              value: provider.notificationSettings.vibrationEnabled,
              onChanged: (bool value) {
                provider.updateNotificationSettings(
                  provider.notificationSettings.copyWith(vibrationEnabled: value),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: Text(loc.translate('reminder_repeat_time')),
              subtitle: Text(
                loc.translate('reminder_not_taken_description'),
              ),
              trailing: Text('${provider.notificationSettings.reminderInterval} ${loc.translate('minutes')}'),
              onTap: () => _showReminderIntervalDialog(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettingsCard() {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('language'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.paddingM),
            RadioListTile<String>(
              title: Text(loc.translate('turkish')),
              value: 'tr',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (String? value) async {
                if (value != null) {
                  await localeProvider.setTurkish();
                }
              },
            ),
            RadioListTile<String>(
              title: Text(loc.translate('english')),
              value: 'en',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (String? value) async {
                if (value != null) {
                  await localeProvider.setEnglish();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Text(
                loc.translate('language_info_note'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    // Set height and weight values in the form
    if (provider.userProfile?.height != null) {
      _heightController.text = provider.userProfile!.height!.toStringAsFixed(0);
    }
    if (provider.userProfile?.weight != null) {
      _weightController.text = provider.userProfile!.weight!.toStringAsFixed(1);
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('edit_profile')),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: loc.translate('your_name'),
                      prefixIcon: const Icon(Icons.person),
                    ),                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.translate('please_enter_name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: loc.translate('age_years').replaceFirst('{age}', ''),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.translate('please_enter_age');
                      }
                      final age = int.tryParse(value);
                      if (age == null || age <= 0 || age > 120) {
                        return loc.translate('enter_valid_age');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),                  // Height field
                  TextFormField(
                    controller: _heightController,                    decoration: InputDecoration(
                      labelText: '${loc.translate('height')} (cm)',
                      prefixIcon: const Icon(Icons.height),
                      helperText: loc.translate('height_example'),
                    ),
                    keyboardType: TextInputType.number,                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final height = double.tryParse(value);
                        if (height == null || height <= 0 || height > 250) {
                          return loc.translate('enter_valid_height');
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  // Weight field
                  TextFormField(
                    controller: _weightController,                    decoration: InputDecoration(
                      labelText: '${loc.translate('weight')} (kg)',
                      prefixIcon: const Icon(Icons.monitor_weight),
                      helperText: loc.translate('weight_example'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 500) {
                          return loc.translate('enter_valid_weight');
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),                  TextFormField(
                    controller: _medicalConditionController,
                    decoration: InputDecoration(
                      labelText: loc.translate('health_condition') + ' (' + loc.translate('optional') + ')',
                      prefixIcon: const Icon(Icons.medical_services),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: loc.translate('notes') + ' (' + loc.translate('optional') + ')',
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Parse height and weight values from controllers
                  double? height;
                  double? weight;
                  
                  if (_heightController.text.isNotEmpty) {
                    height = double.tryParse(_heightController.text);
                  }
                  
                  if (_weightController.text.isNotEmpty) {
                    weight = double.tryParse(_weightController.text);
                  }
                  
                  final updatedProfile = UserProfile(
                    name: _nameController.text,
                    dateOfBirth: provider.userProfile?.dateOfBirth,
                    weight: weight,
                    height: height,
                    allergies: provider.userProfile?.allergies,                  medicalConditions: _medicalConditionController.text.isEmpty
                        ? {}
                        : {'General': _medicalConditionController.text},
                  healthNotes: _notesController.text.isEmpty
                        ? {}
                        : {'General': _notesController.text},
                    emergencyContacts:
                        provider.userProfile?.emergencyContacts ?? [],
                  );
                  provider.updateUserProfile(updatedProfile);
                  Navigator.pop(context);
                    // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('success')),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(loc.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _showAddEmergencyContactDialog(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    bool notifyOnMissedDoses = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.translate('add_emergency_contact')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: loc.translate('full_name'),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: relationshipController,
                      decoration: InputDecoration(
                        labelText: loc.translate('relationship'),
                        prefixIcon: const Icon(Icons.people),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: loc.translate('phone'),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: loc.translate('email_optional'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),                    const SizedBox(height: AppDimens.paddingM),
                    SwitchListTile(
                      title: Text(
                        loc.translate('notify_on_missed_doses'),
                      ),
                      value: notifyOnMissedDoses,
                      onChanged: (value) {
                        setState(() {
                          notifyOnMissedDoses = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        relationshipController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty) {
                      final newContact = EmergencyContact(
                        name: nameController.text,
                        relationship: relationshipController.text,
                        phoneNumber: phoneController.text,
                        email: emailController.text.isEmpty
                            ? null
                            : emailController.text,
                        notifyOnMissedDoses: notifyOnMissedDoses,
                      );
                      provider.addEmergencyContact(newContact);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('fill_required_fields')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: Text(loc.translate('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getAlarmTypeDescription(AlarmType type) {
    final loc = AppLocalizations.of(context);
    
    switch (type) {
      case AlarmType.medicationAlarm:
        return loc.translate('medication_reminder_alarm');
      case AlarmType.emergencyAlarm:
        return loc.translate('emergency_alarm_type');
      case AlarmType.gentleAlarm:
        return loc.translate('gentle_alarm_type');
      case AlarmType.customAlarm:
        return loc.translate('custom_alarm_type');
    }
  }

  void _showAlarmTypeDialog(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    final currentSettings = provider.notificationSettings;
    AlarmType alarmType = currentSettings.alarmType;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.translate('alarm_type_setting')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                // Alarm type selector
                RadioListTile<AlarmType>(
                  title: Text(loc.translate('medication_reminder_alarm')),
                  subtitle: Text(loc.translate('standard_sound')),
                  value: AlarmType.medicationAlarm,
                  groupValue: alarmType,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      alarmType = value!;
                    });
                  },
                ),
                RadioListTile<AlarmType>(
                  title: Text(loc.translate('emergency_alarm_type')),
                  subtitle: Text(loc.translate('louder_alarm_description')),
                  value: AlarmType.emergencyAlarm,
                  groupValue: alarmType,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      alarmType = value!;
                    });
                  },
                ),                  RadioListTile<AlarmType>(
                  title: Text(loc.translate('gentle_alarm_type')),
                  subtitle: Text(loc.translate('softer_alarm_description')),
                  value: AlarmType.gentleAlarm,
                  groupValue: alarmType,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      alarmType = value!;
                    });
                  },
                ),
                RadioListTile<AlarmType>(
                  title: Text(loc.translate('custom_alarm_type')),
                  subtitle: Text(loc.translate('custom_sound_description')),
                  value: AlarmType.customAlarm,
                  groupValue: alarmType,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      alarmType = value!;
                    });
                  },
                ),
              ],
            ),
          ),          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                // Update notification settings
                final updatedSettings = currentSettings.copyWith(alarmType: alarmType);
                provider.updateNotificationSettings(updatedSettings);
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderIntervalDialog(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    final currentSettings = provider.notificationSettings;
    int reminderInterval = currentSettings.reminderInterval;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.translate('reminder_repeat_time')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                // Reminder interval selector
                Text(
                  loc.translate('reminder_not_taken_description'),
                ),
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  '${reminderInterval} ${loc.translate('minutes')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: reminderInterval.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 6,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withOpacity(0.2),
                  label: '${reminderInterval} ${loc.translate('minutes')}',
                  onChanged: (value) {
                    setState(() {
                      reminderInterval = value.toInt();
                    });
                  },
                ),
              ],
            ),
          ),          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                // Update notification settings
                final updatedSettings = currentSettings.copyWith(reminderInterval: reminderInterval);
                provider.updateNotificationSettings(updatedSettings);
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final loc = AppLocalizations.of(context);
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('call_failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final loc = AppLocalizations.of(context);
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('sms_failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final loc = AppLocalizations.of(context);
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('email_failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  double _calculateBMI(double height, double weight) {
    // BMI = weight (kg) / (height (m))²
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  Widget _buildEmergencyContactsSection(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('emergency_contacts'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.paddingM),
            if (provider.userProfile?.emergencyContacts.isEmpty ?? true)
              Center(
                child: Text(
                  loc.translate('no_emergency_contacts'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.userProfile!.emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = provider.userProfile!.emergencyContacts[index];
                  return ListTile(
                    title: Text(contact.name),
                    subtitle: Text('${contact.relationship} - ${contact.phoneNumber}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () => _callPhoneNumber(contact.phoneNumber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () => _sendSms(contact.phoneNumber),
                        ),
                        if (contact.email != null)
                          IconButton(
                            icon: const Icon(Icons.email),
                            onPressed: () => _sendEmail(contact.email!),
                          ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: AppDimens.paddingM),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddEmergencyContactDialog(provider),
                icon: const Icon(Icons.add),
                label: Text(loc.translate('add_emergency_contact')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}