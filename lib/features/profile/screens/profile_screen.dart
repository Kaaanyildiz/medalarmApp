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

class _ProfileScreenState extends State<ProfileScreen> {  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _medicalConditionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalConditionController.dispose();
    _notesController.dispose();
    super.dispose();
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
  }  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
      return DefaultTabController(
      length: 3, // Three tabs: Personal Info, Health Summary, Settings
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

            return TabBarView(              children: [
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
                  ),                ),
                
                // Health Summary Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHealthSummaryCard(provider),
                    ],
                  ),                ),
                
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
  }Widget _buildProfileInfoSection(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 36,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      Text(
                        provider.userProfile?.name.isNotEmpty == true
                            ? provider.userProfile!.name
                            : loc.translate('name_not_entered'),
                        style: AppTextStyles.heading2,
                      ),
                      if (provider.userProfile?.age != null &&
                          (provider.userProfile!.age ?? 0) > 0) ...[
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          loc.translate('age_years').replaceFirst('{age}', '${provider.userProfile!.age}'),
                          style: AppTextStyles.bodyTextSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(provider),
                ),
              ],
            ),
            
            if (provider.userProfile?.medicalCondition?.isNotEmpty == true) ...[              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                loc.translate('health_condition'),
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                provider.userProfile!.medicalCondition!,
                style: AppTextStyles.bodyText,
              ),
            ],
            if (provider.userProfile?.notes?.isNotEmpty == true) ...[              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                loc.translate('notes'),
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                provider.userProfile!.notes!,
                style: AppTextStyles.bodyText,
              ),
            ],
          ],
        ),
      ),
    );
  }  // Health summary card
  Widget _buildHealthSummaryCard(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [            Text(
              loc.translate('health_summary'),
              style: AppTextStyles.heading3,
            ),
            if (provider.userProfile?.height == null || provider.userProfile?.weight == null)              TextButton.icon(
                onPressed: () => _showEditProfileDialog(provider),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: Text(loc.translate('add_height_weight')),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),        // Height, weight and body mass index
        if (provider.userProfile?.height != null && provider.userProfile?.weight != null) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              color: AppColors.primary.withOpacity(0.05),
            ),
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              children: [
                Row(
                  children: [                    _buildHealthMetricItem(
                      icon: Icons.height,
                      title: loc.translate('height'),
                      value: '${provider.userProfile!.height!.toStringAsFixed(0)} cm',
                      color: AppColors.primary,
                    ),                    _buildHealthMetricItem(
                      icon: Icons.monitor_weight,
                      title: loc.translate('weight'),
                      value: '${provider.userProfile!.weight!.toStringAsFixed(1)} kg',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingM),
                  // BMI indicator
                if (provider.userProfile!.bmi != null)
                  BMIGaugeWidget(bmi: provider.userProfile!.bmi!),
                
                const SizedBox(height: AppDimens.paddingS),
                Align(
                  alignment: Alignment.centerRight,                  child: TextButton.icon(
                    onPressed: () => _showEditProfileDialog(provider),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(loc.translate('update')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.paddingM),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              color: AppColors.background,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monitor_weight_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppDimens.paddingS),                Text(
                  loc.translate('add_height_weight_prompt'),
                  style: AppTextStyles.bodyTextBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  loc.translate('bmi_calculation_note'),
                  style: AppTextStyles.bodyTextSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.paddingM),                ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(provider),
                  icon: const Icon(Icons.add),
                  label: Text(loc.translate('add_height_weight')),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.paddingM),
        ],
          // Medication usage statistics
        FutureBuilder<Map<String, dynamic>>(
          future: _getMedicationStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.paddingM),
                  child: CircularProgressIndicator(),
                ),
              );
            }
              if (snapshot.hasError || !snapshot.hasData) {
              return Text(loc.translate('error'));
            }
            
            final stats = snapshot.data!;
            
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                color: AppColors.secondary.withOpacity(0.05),
              ),
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('medication_statistics'),
                    style: AppTextStyles.bodyTextBold,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Row(
                    children: [                      _buildHealthMetricItem(
                        icon: Icons.medication,
                        title: loc.translate('active_medications'),
                        value: '${stats['activeCount'] ?? 0}',
                        color: AppColors.primary,
                      ),
                      _buildHealthMetricItem(
                        icon: Icons.check_circle,
                        title: loc.translate('adherence_rate'),
                        value: '${stats['adherenceRate'] ?? 0}%',
                        color: _getAdherenceColor(stats['adherenceRate']),
                      ),
                      _buildHealthMetricItem(
                        icon: Icons.calendar_today,
                        title: loc.translate('todays_doses'),
                        value: '${stats['todayDoses'] ?? 0}',
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  
                  if (stats['adherenceRate'] != null) ...[
                    const SizedBox(height: AppDimens.paddingM),
                    
                    // Uyum oranı ilerleme çubuğu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [                            Text(
                              loc.translate('weekly_adherence'),
                              style: AppTextStyles.bodyTextSmall,
                            ),
                            Text(
                              '${stats['adherenceRate']}%',
                              style: AppTextStyles.bodyTextBold.copyWith(
                                color: _getAdherenceColor(stats['adherenceRate']),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingXS),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                          child: LinearProgressIndicator(
                            value: (stats['adherenceRate'] as num).toDouble() / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            color: _getAdherenceColor(stats['adherenceRate']),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          _getAdherenceDescription(stats['adherenceRate']),
                          style: AppTextStyles.bodyTextSmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    // İlaç alma zamanlaması istatistiği (zamanında, geç, atlanmış)
                    if (stats['onTimePercentage'] != null) ...[
                      const SizedBox(height: AppDimens.paddingM),
                      const Divider(),
                      const SizedBox(height: AppDimens.paddingS),
                        Text(
                        loc.translate('medication_timing'),
                        style: AppTextStyles.bodyTextSmall,
                      ),
                      const SizedBox(height: AppDimens.paddingS),
                      
                      Row(
                        children: [
                          _buildTimingStatItem(
                            label: loc.translate('on_time'),
                            percentage: stats['onTimePercentage'],
                            color: Colors.green,
                          ),
                          _buildTimingStatItem(
                            label: loc.translate('delayed'),
                            percentage: stats['latePercentage'] ?? 0,
                            color: Colors.orange,
                          ),
                          _buildTimingStatItem(
                            label: loc.translate('skipped'),
                            percentage: stats['missedPercentage'] ?? 0,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ); 
          },  
        ),
      ],
    );
  }
  // Medication timing statistics item
  Widget _buildTimingStatItem({
    required String label, 
    required num percentage, 
    required Color color
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingXS),          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyTextSmall,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTextStyles.bodyTextBold.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }  // Adherence description
  String _getAdherenceDescription(dynamic adherenceRate) {
    final loc = AppLocalizations.of(context);
    final rate = adherenceRate is int || adherenceRate is double 
      ? (adherenceRate as num).toDouble() 
      : 0.0;
    
    if (rate < 50) {
      return loc.translate('adherence_low');
    }
    if (rate < 80) {
      return loc.translate('adherence_medium');
    }
    return loc.translate('adherence_high');
  }
    // Health metric item widget
  Widget _buildHealthMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppDimens.paddingXS),
              Text(
                title,
                style: AppTextStyles.bodyTextSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.paddingXS / 2),
              Text(
                value,
                style: AppTextStyles.bodyTextBold,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Calculate adherence rate color
  Color _getAdherenceColor(dynamic adherenceRate) {
    final rate = adherenceRate is int || adherenceRate is double 
      ? (adherenceRate as num).toDouble() 
      : 0.0;
    
    if (rate < 50) return Colors.red;
    if (rate < 80) return Colors.orange;
    return Colors.green;
  }
  // Get medication statistics
  Future<Map<String, dynamic>> _getMedicationStatistics() async {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    
    // Active medication count
    final medications = await medicationProvider.loadMedications();
    final activeCount = medications.where((med) => med.isActive).length;
    
    // Today's doses
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayLogs = await medicationProvider.loadMedicationLogsByDate(date: todayDate);
    final todayDoses = todayLogs.length;
      // Calculate adherence rate
    int totalDoses = 0;
    int takenDoses = 0;
    int takenOnTime = 0;
    int takenLate = 0;
    int skippedDoses = 0;
    int missedDoses = 0;
    
    // Get all logs from the past week
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final logsLastWeek = await medicationProvider.loadMedicationLogsByDateRange(
      startDate: weekAgo,
      endDate: today,
    );
    
    if (logsLastWeek.isNotEmpty) {
      totalDoses = logsLastWeek.length;
        for (final log in logsLastWeek) {
        // Calculate taken doses
        if (log.isTaken) {
          takenDoses++;
          
          // Taken on time or delayed?
          if (log.delayInMinutes != null && log.delayInMinutes! > 15) {
            takenLate++;
          } else {
            takenOnTime++;
          }
        } 
        // Calculate skipped doses
        else if (log.isSkipped) {
          skippedDoses++;
        } 
        // Calculate missed doses (not taken and time passed)
        else if (DateTime.now().isAfter(log.scheduledTime)) {
          missedDoses++;
        }
      }
    }
      // Calculate adherence and timing rates
    final adherenceRate = totalDoses > 0 
      ? ((takenDoses / totalDoses) * 100).round() 
      : 100;
    
    // On-time rate
    final onTimePercentage = takenDoses > 0
      ? ((takenOnTime / takenDoses) * 100).round()
      : 0;
    
    // Delayed rate
    final latePercentage = takenDoses > 0
      ? ((takenLate / takenDoses) * 100).round()
      : 0;
    
    // Missed/Skipped rate
    final missedPercentage = totalDoses > 0
      ? (((skippedDoses + missedDoses) / totalDoses) * 100).round()
      : 0;
    
    return {
      'activeCount': activeCount,
      'todayDoses': todayDoses,
      'adherenceRate': adherenceRate,
      'onTimePercentage': onTimePercentage,
      'latePercentage': latePercentage,
      'missedPercentage': missedPercentage,
      'takenDoses': takenDoses,
      'totalDoses': totalDoses,
    };
  }
  Widget _buildEmergencyContactsSection(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.translate('emergency_contacts'),
              style: AppTextStyles.heading2,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _showAddEmergencyContactDialog(provider),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        if (provider.userProfile?.emergencyContacts.isEmpty == true)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimens.paddingL),
                const Icon(
                  Icons.contact_emergency,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppDimens.paddingM),                Text(
                  loc.translate('no_emergency_contacts'),
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                ElevatedButton(
                  onPressed: () => _showAddEmergencyContactDialog(provider),
                  child: Text(loc.translate('add_emergency_contact')),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.userProfile!.emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = provider.userProfile!.emergencyContacts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Icon(
                              Icons.contact_phone,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: AppTextStyles.heading3,
                                ),
                                const SizedBox(height: AppDimens.paddingXS),
                                Text(
                                  contact.relationship ?? '',
                                  style: AppTextStyles.bodyTextSmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditEmergencyContactDialog(
                              provider,
                              index,
                              contact,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: AppColors.error,
                            onPressed: () => _showDeleteEmergencyContactDialog(
                              provider,
                              index,
                              contact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingM),                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callPhoneNumber(contact.phoneNumber),
                              icon: const Icon(Icons.phone),
                              label: Text(loc.translate('call')),
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _sendSms(contact.phoneNumber),
                              icon: const Icon(Icons.message),
                              label: Text(loc.translate('message')),
                            ),
                          ),
                        ],
                      ),
                      if (contact.email?.isNotEmpty == true) ...[
                        const SizedBox(height: AppDimens.paddingS),                        OutlinedButton.icon(
                          onPressed: () => _sendEmail(contact.email!),
                          icon: const Icon(Icons.email),
                          label: Text(loc.translate('send_email')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimens.paddingS),                      SwitchListTile(
                        title: Text(
                          loc.translate('notify_on_missed_doses'),
                          style: AppTextStyles.bodyTextSmall,
                        ),
                        value: contact.notifyOnMissedDoses,
                        onChanged: (value) {
                          final updatedContact = EmergencyContact(
                            name: contact.name,
                            relationship: contact.relationship,
                            phoneNumber: contact.phoneNumber,
                            email: contact.email ?? '',
                            notifyOnMissedDoses: value,
                          );
                          provider.updateEmergencyContact(index, updatedContact);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }  void _showEditProfileDialog(UserProfileProvider provider) {
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
  }  void _showAddEmergencyContactDialog(UserProfileProvider provider) {
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
  void _showEditEmergencyContactDialog(
    UserProfileProvider provider,
    int index,
    EmergencyContact contact,
  ) {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController(text: contact.name);
    final relationshipController =
        TextEditingController(text: contact.relationship);
    final phoneController = TextEditingController(text: contact.phoneNumber);
    final emailController = TextEditingController(text: contact.email ?? '');
    bool notifyOnMissedDoses = contact.notifyOnMissedDoses;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.translate('edit_emergency_contact')),
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
                      final updatedContact = EmergencyContact(
                        name: nameController.text,
                        relationship: relationshipController.text,
                        phoneNumber: phoneController.text,
                        email: emailController.text.isEmpty
                            ? null
                            : emailController.text,
                        notifyOnMissedDoses: notifyOnMissedDoses,
                      );
                      provider.updateEmergencyContact(index, updatedContact);
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
                  child: Text(loc.translate('update_contact')),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showDeleteEmergencyContactDialog(
    UserProfileProvider provider,
    int index,
    EmergencyContact contact,
  ) {
    final loc = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('delete')),
          content: Text(
            loc.translate('confirm_delete'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                provider.removeEmergencyContact(index);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: Text(loc.translate('delete')),
            ),
          ],
        );
      },
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
  }// Notification and alarm settings card
  Widget _buildNotificationSettingsCard(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    final notificationSettings = provider.userProfile!.notificationSettings;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.translate('notification_and_alarm_settings'),
              style: AppTextStyles.heading3,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showNotificationSettingsDialog(provider),
              tooltip: loc.translate('edit_notification_settings'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            color: AppColors.secondary.withOpacity(0.05),
          ),
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            children: [              // Notification status (enabled/disabled)
              _buildSettingRow(
                loc.translate('notifications'),
                notificationSettings.enableNotifications 
                  ? loc.translate('on')
                  : loc.translate('off'),
                notificationSettings.enableNotifications
                  ? Icons.notifications_active
                  : Icons.notifications_off,
                notificationSettings.enableNotifications
                  ? AppColors.success
                  : Colors.grey,
              ),
              
              const Divider(),
              
              // Alarm status (enabled/disabled)
              _buildSettingRow(
                loc.translate('sound_alarms'),
                notificationSettings.enableAlarms 
                  ? loc.translate('on')
                  : loc.translate('off'),
                notificationSettings.enableAlarms
                  ? Icons.alarm_on
                  : Icons.alarm_off,
                notificationSettings.enableAlarms
                  ? AppColors.success
                  : Colors.grey,
              ),
              
              const Divider(),
              
              // Alarm type
              _buildSettingRow(
                loc.translate('alarm_type'),
                _getAlarmTypeName(notificationSettings.alarmType),
                Icons.music_note,
                AppColors.primary,
              ),
              
              const Divider(),
                // Vibration status
              _buildSettingRow(
                loc.translate('vibrate'),
                notificationSettings.vibrate
                  ? loc.translate('on')
                  : loc.translate('off'),
                notificationSettings.vibrate
                  ? Icons.vibration
                  : Icons.do_not_disturb_on,
                notificationSettings.vibrate
                  ? AppColors.success
                  : Colors.grey,
              ),
              
              const Divider(),
              
              // Reminder interval
              _buildSettingRow(
                loc.translate('reminder_interval'),
                '${notificationSettings.reminderInterval} ${loc.translate('minutes')}',
                Icons.update,
                AppColors.primary,
              ),
              
              const SizedBox(height: AppDimens.paddingM),
                // Settings edit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showNotificationSettingsDialog(provider),
                  icon: const Icon(Icons.settings),
                  label: Text(loc.translate('edit_notification_settings')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingRow(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyTextBold,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyTextSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }  String _getAlarmTypeName(AlarmType type) {
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
  void _showNotificationSettingsDialog(UserProfileProvider provider) {
    final loc = AppLocalizations.of(context);
    final currentSettings = provider.userProfile!.notificationSettings;
    bool enableNotifications = currentSettings.enableNotifications;
    bool enableAlarms = currentSettings.enableAlarms;
    bool vibrate = currentSettings.vibrate;
    int alarmDuration = currentSettings.alarmDuration;
    int reminderInterval = currentSettings.reminderInterval;
    AlarmType alarmType = currentSettings.alarmType;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.translate('notification_and_alarm_settings')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                // Notifications on/off
                SwitchListTile(
                  title: Text(loc.translate('notifications')),
                  subtitle: Text(loc.translate('notification_description')),
                  value: enableNotifications,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      enableNotifications = value;
                      if (!value) {
                        // If notifications are disabled, also disable alarms
                        enableAlarms = false;
                      }
                    });
                  },
                ),
                
                const Divider(),
                
                // Sound alarms on/off
                SwitchListTile(
                  title: Text(loc.translate('sound_alarms')),
                  subtitle: Text(loc.translate('sound_alarms_description')),
                  value: enableAlarms,
                  activeColor: AppColors.primary,
                  onChanged: enableNotifications 
                    ? (value) {
                        setState(() {
                          enableAlarms = value;
                        });
                      }
                    : null,
                ),
                  // Alarm type selector (if Notifications and Alarms are enabled)
                if (enableNotifications && enableAlarms) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.paddingM, 
                      top: AppDimens.paddingM,
                      bottom: AppDimens.paddingS,
                    ),
                    child: Text(loc.translate('alarm_type_setting')),
                  ),
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
                  
                  const Divider(),
                    // Alarm duration selector
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('alarm_duration')),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          '${alarmDuration} ${loc.translate('seconds')}', 
                          style: AppTextStyles.bodyTextBold,
                        ),
                        Slider(
                          value: alarmDuration.toDouble(),
                          min: 10,
                          max: 60,
                          divisions: 5,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.primary.withOpacity(0.2),
                          label: '${alarmDuration} ${loc.translate('seconds')}',
                          onChanged: (value) {
                            setState(() {
                              alarmDuration = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                    // Vibration setting
                  SwitchListTile(
                    title: Text(loc.translate('vibration_setting')),
                    subtitle: Text(loc.translate('vibration_description')),
                    value: vibrate,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        vibrate = value;
                      });
                    },
                  ),
                ],
                
                if (enableNotifications) ...[
                  const Divider(),
                    // Reminder interval selector
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('reminder_repeat_time')),
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          loc.translate('reminder_not_taken_description'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          '${reminderInterval} ${loc.translate('minutes')}', 
                          style: AppTextStyles.bodyTextBold,
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
                  ),
                ],
              ],
            ),
          ),          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                // Create new settings
                final newSettings = NotificationSettings(
                  enableNotifications: enableNotifications,
                  enableAlarms: enableAlarms,
                  alarmDuration: alarmDuration,
                  alarmType: alarmType,
                  vibrate: vibrate,
                  reminderInterval: reminderInterval,
                );
                
                // Update user profile with new settings
                _updateNotificationSettings(provider, newSettings);
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );  }
    // Language settings card
  Widget _buildLanguageSettingsCard() {
    final loc = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.translate('language'),
              style: AppTextStyles.heading3,
            ),
            IconButton(
              icon: const Icon(Icons.translate),
              onPressed: () => Navigator.pushNamed(context, '/language_settings'),
              tooltip: loc.translate('edit'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
          // Language selection card
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/language_settings'),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              color: AppColors.primary.withOpacity(0.05),
            ),
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('language'),
                        style: AppTextStyles.bodyTextBold,
                      ),
                      const SizedBox(height: AppDimens.paddingXS),
                      Consumer<LocaleProvider>(
                        builder: (context, localeProvider, _) {
                          return Text(
                            localeProvider.isTurkish 
                              ? loc.translate('turkish') 
                              : loc.translate('english'),
                            style: AppTextStyles.bodyText,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }  // Method to update notification settings
  Future<void> _updateNotificationSettings(
    UserProfileProvider provider, 
    NotificationSettings newSettings
  ) async {
    final loc = AppLocalizations.of(context);
    final updatedProfile = provider.userProfile!.copyWith(
      notificationSettings: newSettings,
    );
    
    await provider.updateUserProfile(updatedProfile);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('notification_settings_updated')),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }  }
  }