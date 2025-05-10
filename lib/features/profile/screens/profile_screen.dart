import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/core/models/user_profile.dart';
import 'package:medalarmm/features/notifications/models/notification_settings.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/profile/providers/user_profile_provider.dart';
import 'package:medalarmm/features/profile/widgets/bmi_gauge_widget.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfileSection(provider),
                const SizedBox(height: AppDimens.paddingL),
                _buildEmergencyContactsSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildUserProfileSection(UserProfileProvider provider) {
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
                    children: [
                      Text(
                        provider.userProfile?.name.isNotEmpty == true
                            ? provider.userProfile!.name
                            : 'İsim Girilmemiş',
                        style: AppTextStyles.heading2,
                      ),
                      if (provider.userProfile?.age != null &&
                          (provider.userProfile!.age ?? 0) > 0) ...[
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          '${provider.userProfile!.age} yaşında',
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
            
            // Kullanıcı sağlık özeti kartı
            const SizedBox(height: AppDimens.paddingM),
            const Divider(),
            const SizedBox(height: AppDimens.paddingM),
            _buildHealthSummaryCard(provider),
            
            // Bildirim ve alarm ayarları kartı
            const SizedBox(height: AppDimens.paddingM),
            const Divider(),
            const SizedBox(height: AppDimens.paddingM),
            _buildNotificationSettingsCard(provider),
            
            if (provider.userProfile?.medicalCondition?.isNotEmpty == true) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'Sağlık Durumu',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                provider.userProfile!.medicalCondition!,
                style: AppTextStyles.bodyText,
              ),
            ],
            if (provider.userProfile?.notes?.isNotEmpty == true) ...[
              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              Text(
                'Notlar',
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
  }
    // Yeni eklenen sağlık özeti kartı
  Widget _buildHealthSummaryCard(UserProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sağlık Özeti',
              style: AppTextStyles.heading3,
            ),
            if (provider.userProfile?.height == null || provider.userProfile?.weight == null)
              TextButton.icon(
                onPressed: () => _showEditProfileDialog(provider),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Boy/Kilo Ekle'),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),          // Boy, kilo ve vücut kitle indeksi
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
                  children: [
                    _buildHealthMetricItem(
                      icon: Icons.height,
                      title: 'Boy',
                      value: '${provider.userProfile!.height!.toStringAsFixed(0)} cm',
                      color: AppColors.primary,
                    ),
                    _buildHealthMetricItem(
                      icon: Icons.monitor_weight,
                      title: 'Kilo',
                      value: '${provider.userProfile!.weight!.toStringAsFixed(1)} kg',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingM),
                
                // VKİ Göstergesi
                if (provider.userProfile!.bmi != null)
                  BMIGaugeWidget(bmi: provider.userProfile!.bmi!),
                
                const SizedBox(height: AppDimens.paddingS),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showEditProfileDialog(provider),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Güncelle'),
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
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  'Boy ve kilo bilgilerinizi ekleyin',
                  style: AppTextStyles.bodyTextBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  'VKİ hesaplaması ve daha kişiselleştirilmiş öneriler için boy ve kilo bilgilerinizi girin.',
                  style: AppTextStyles.bodyTextSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.paddingM),
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Boy/Kilo Ekle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.paddingM),
        ],
        
        // İlaç kullanım istatistikleri
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
              return const Text('İlaç istatistikleri yüklenemedi');
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
                    'İlaç Kullanım İstatistikleri',
                    style: AppTextStyles.bodyTextBold,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Row(
                    children: [
                      _buildHealthMetricItem(
                        icon: Icons.medication,
                        title: 'Aktif İlaçlar',
                        value: '${stats['activeCount'] ?? 0}',
                        color: AppColors.primary,
                      ),
                      _buildHealthMetricItem(
                        icon: Icons.check_circle,
                        title: 'Uyum Oranı',
                        value: '${stats['adherenceRate'] ?? 0}%',
                        color: _getAdherenceColor(stats['adherenceRate']),
                      ),
                      _buildHealthMetricItem(
                        icon: Icons.calendar_today,
                        title: 'Bugünkü Dozlar',
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
                          children: [
                            Text(
                              'Haftalık İlaç Uyum Oranı',
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
                        'İlaç Alma Zamanlaması',
                        style: AppTextStyles.bodyTextSmall,
                      ),
                      const SizedBox(height: AppDimens.paddingS),
                      
                      Row(
                        children: [
                          _buildTimingStatItem(
                            label: 'Zamanında',
                            percentage: stats['onTimePercentage'],
                            color: Colors.green,
                          ),
                          _buildTimingStatItem(
                            label: 'Gecikmeli',
                            percentage: stats['latePercentage'] ?? 0,
                            color: Colors.orange,
                          ),
                          _buildTimingStatItem(                            label: 'Atlanmış',
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
    // İlaç alma zamanlama istatistiği öğesi
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
  }// Uyum oranı açıklaması
  String _getAdherenceDescription(dynamic adherenceRate) {
    final rate = adherenceRate is int || adherenceRate is double 
      ? (adherenceRate as num).toDouble() 
      : 0.0;
    
    if (rate < 50) {
      return 'İlaç uyumunuz düşük. İlaçlarınızı düzenli almak için hatırlatıcıları etkinleştirmeyi düşünün.';
    }
    if (rate < 80) {
      return 'İlaç uyumunuz orta seviyede. Daha iyi sonuçlar için ilaçlarınızı daha düzenli almaya çalışın.';
    }
    return 'İlaç uyumunuz yüksek. Harika gidiyorsunuz, bu şekilde devam edin!';
  }
  
  // Sağlık metrik öğesi widget'ı
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
    // Uyum oranı rengini hesaplama
  Color _getAdherenceColor(dynamic adherenceRate) {
    final rate = adherenceRate is int || adherenceRate is double 
      ? (adherenceRate as num).toDouble() 
      : 0.0;
    
    if (rate < 50) return Colors.red;
    if (rate < 80) return Colors.orange;
    return Colors.green;
  }
    // İlaç istatistiklerini alma
  Future<Map<String, dynamic>> _getMedicationStatistics() async {
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
    
    // Aktif ilaç sayısı
    final medications = await medicationProvider.loadMedications();
    final activeCount = medications.where((med) => med.isActive).length;
    
    // Bugünkü dozlar
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayLogs = await medicationProvider.loadMedicationLogsByDate(date: todayDate);
    final todayDoses = todayLogs.length;
    
    // Uyum oranı hesaplama
    int totalDoses = 0;
    int takenDoses = 0;
    int takenOnTime = 0;
    int takenLate = 0;
    int skippedDoses = 0;
    int missedDoses = 0;
    
    // Son bir haftadaki tüm logları al
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final logsLastWeek = await medicationProvider.loadMedicationLogsByDateRange(
      startDate: weekAgo,
      endDate: today,
    );
    
    if (logsLastWeek.isNotEmpty) {
      totalDoses = logsLastWeek.length;
      
      for (final log in logsLastWeek) {
        // Alınmış dozları hesapla
        if (log.isTaken) {
          takenDoses++;
          
          // Zamanında veya gecikmeli alınmış mı?
          if (log.delayInMinutes != null && log.delayInMinutes! > 15) {
            takenLate++;
          } else {
            takenOnTime++;
          }
        } 
        // Atlanmış dozları hesapla
        else if (log.isSkipped) {
          skippedDoses++;
        } 
        // Alınmamış ve zamanı geçmiş dozları hesapla
        else if (DateTime.now().isAfter(log.scheduledTime)) {
          missedDoses++;
        }
      }
    }
    
    // Uyum ve zamanlama oranlarını hesapla
    final adherenceRate = totalDoses > 0 
      ? ((takenDoses / totalDoses) * 100).round() 
      : 100;
    
    // Zamanında alınma oranı
    final onTimePercentage = takenDoses > 0
      ? ((takenOnTime / takenDoses) * 100).round()
      : 0;
    
    // Gecikmeli alınma oranı
    final latePercentage = takenDoses > 0
      ? ((takenLate / takenDoses) * 100).round()
      : 0;
    
    // Atlanmış/Kaçırılmış oranı
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Acil Durum Kişileri',
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
                const SizedBox(height: AppDimens.paddingM),
                Text(
                  'Henüz acil durum kişisi eklenmemiş',
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingS),
                ElevatedButton(
                  onPressed: () => _showAddEmergencyContactDialog(provider),
                  child: const Text('Acil Durum Kişisi Ekle'),
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
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callPhoneNumber(contact.phoneNumber),
                              icon: const Icon(Icons.phone),
                              label: const Text('Ara'),
                            ),
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _sendSms(contact.phoneNumber),
                              icon: const Icon(Icons.message),
                              label: const Text('Mesaj'),
                            ),
                          ),
                        ],
                      ),
                      if (contact.email?.isNotEmpty == true) ...[
                        const SizedBox(height: AppDimens.paddingS),
                        OutlinedButton.icon(
                          onPressed: () => _sendEmail(contact.email!),
                          icon: const Icon(Icons.email),
                          label: const Text('E-posta Gönder'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimens.paddingS),
                      SwitchListTile(
                        title: const Text(
                          'Doz alınmadığında bilgilendir',
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
  }
  void _showEditProfileDialog(UserProfileProvider provider) {
    // Boy ve kilo değerlerini formda göstermek için tanımla
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
          title: const Text('Profili Düzenle'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adınızı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Yaş',
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen yaşınızı girin';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age <= 0 || age > 120) {
                        return 'Geçerli bir yaş girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  // Boy alanı
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Boy (cm)',
                      prefixIcon: Icon(Icons.height),
                      helperText: 'Örn: 175',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final height = double.tryParse(value);
                        if (height == null || height <= 0 || height > 250) {
                          return 'Geçerli bir boy girin (1-250 cm)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  // Kilo alanı
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Kilo (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                      helperText: 'Örn: 70.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 500) {
                          return 'Geçerli bir kilo girin (1-500 kg)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _medicalConditionController,
                    decoration: const InputDecoration(
                      labelText: 'Sağlık Durumu (Opsiyonel)',
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notlar (Opsiyonel)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {                if (_formKey.currentState!.validate()) {
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
                    allergies: provider.userProfile?.allergies,
                    medicalConditions: _medicalConditionController.text.isEmpty
                        ? {}
                        : {'Genel': _medicalConditionController.text},
                    healthNotes: _notesController.text.isEmpty
                        ? {}
                        : {'Genel': _notesController.text},
                    emergencyContacts:
                        provider.userProfile?.emergencyContacts ?? [],
                  );
                  provider.updateUserProfile(updatedProfile);
                  Navigator.pop(context);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil başarıyla güncellendi'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEmergencyContactDialog(UserProfileProvider provider) {
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
              title: const Text('Acil Durum Kişisi Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Yakınlık',
                        prefixIcon: Icon(Icons.people),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta (Opsiyonel)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    SwitchListTile(
                      title: const Text(
                        'Doz alınmadığında bilgilendir',
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
                  child: const Text('İptal'),
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
                        const SnackBar(
                          content: Text('Lütfen tüm zorunlu alanları doldurun'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Ekle'),
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
              title: const Text('Acil Durum Kişisini Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: relationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Yakınlık',
                        prefixIcon: Icon(Icons.people),
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta (Opsiyonel)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    SwitchListTile(
                      title: const Text(
                        'Doz alınmadığında bilgilendir',
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
                  child: const Text('İptal'),
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
                        const SnackBar(
                          content: Text('Lütfen tüm zorunlu alanları doldurun'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Güncelle'),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Acil Durum Kişisini Sil'),
          content: Text(
            '${contact.name} kişisini silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.removeEmergencyContact(index);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon araması başlatılamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS gönderilemedi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta gönderilemedi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Bildirim ve alarm ayarları kartı
  Widget _buildNotificationSettingsCard(UserProfileProvider provider) {
    final notificationSettings = provider.userProfile!.notificationSettings;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bildirim ve Alarm Ayarları',
              style: AppTextStyles.heading3,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showNotificationSettingsDialog(provider),
              tooltip: 'Bildirim Ayarlarını Düzenle',
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
            children: [
              // Bildirim açık/kapalı durumu
              _buildSettingRow(
                'Bildirimler',
                notificationSettings.enableNotifications 
                  ? 'Açık' 
                  : 'Kapalı',
                notificationSettings.enableNotifications
                  ? Icons.notifications_active
                  : Icons.notifications_off,
                notificationSettings.enableNotifications
                  ? AppColors.success
                  : Colors.grey,
              ),
              
              const Divider(),
              
              // Alarm açık/kapalı durumu
              _buildSettingRow(
                'Sesli Alarmlar',
                notificationSettings.enableAlarms 
                  ? 'Açık' 
                  : 'Kapalı',
                notificationSettings.enableAlarms
                  ? Icons.alarm_on
                  : Icons.alarm_off,
                notificationSettings.enableAlarms
                  ? AppColors.success
                  : Colors.grey,
              ),
              
              const Divider(),
              
              // Alarm tipi
              _buildSettingRow(
                'Alarm Türü',
                _getAlarmTypeName(notificationSettings.alarmType),
                Icons.music_note,
                AppColors.primary,
              ),
              
              const Divider(),
              
              // Titreşim durumu
              _buildSettingRow(
                'Titreşim',
                notificationSettings.vibrate
                  ? 'Açık'
                  : 'Kapalı',
                notificationSettings.vibrate
                  ? Icons.vibration
                  : Icons.do_not_disturb_on,
                notificationSettings.vibrate
                  ? AppColors.success
                  : Colors.grey,
              ),
              
              const Divider(),
              
              // Hatırlatma aralığı
              _buildSettingRow(
                'Hatırlatma Aralığı',
                '${notificationSettings.reminderInterval} dakika',
                Icons.update,
                AppColors.primary,
              ),
              
              const SizedBox(height: AppDimens.paddingM),
              
              // Ayar düzenleme butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showNotificationSettingsDialog(provider),
                  icon: const Icon(Icons.settings),
                  label: const Text('Bildirim Ayarlarını Düzenle'),
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
    switch (type) {
      case AlarmType.medicationAlarm:
        return 'İlaç Hatırlatıcı';
      case AlarmType.emergencyAlarm:
        return 'Acil Durum Alarmı';
      case AlarmType.gentleAlarm:
        return 'Nazik Alarm';
      case AlarmType.customAlarm:
        return 'Özel Alarm';
    }
  }
    void _showNotificationSettingsDialog(UserProfileProvider provider) {
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
          title: const Text('Bildirim ve Alarm Ayarları'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bildirimler açık/kapalı
                SwitchListTile(
                  title: const Text('Bildirimler'),
                  subtitle: const Text('İlaç hatırlatmaları için bildirimler'),
                  value: enableNotifications,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      enableNotifications = value;
                      if (!value) {
                        // Bildirimler kapatılırsa alarmlar da kapatılır
                        enableAlarms = false;
                      }
                    });
                  },
                ),
                
                const Divider(),
                
                // Alarmlar açık/kapalı
                SwitchListTile(
                  title: const Text('Sesli Alarmlar'),
                  subtitle: const Text('İlaç vakti geldiğinde alarm çal'),
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
                
                // Alarm tipi seçici (Bildirimler ve Alarmlar açıksa)
                if (enableNotifications && enableAlarms) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(
                      left: AppDimens.paddingM, 
                      top: AppDimens.paddingM,
                      bottom: AppDimens.paddingS,
                    ),
                    child: Text('Alarm Tipi'),
                  ),
                  RadioListTile<AlarmType>(
                    title: const Text('İlaç Hatırlatıcı'),
                    subtitle: const Text('Standart hatırlatma sesi'),
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
                    title: const Text('Acil Durum Alarmı'),
                    subtitle: const Text('Daha yüksek sesli alarm'),
                    value: AlarmType.emergencyAlarm,
                    groupValue: alarmType,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        alarmType = value!;
                      });
                    },
                  ),
                  RadioListTile<AlarmType>(
                    title: const Text('Nazik Alarm'),
                    subtitle: const Text('Daha yumuşak sesli alarm'),
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
                    title: const Text('Özel Alarm'),
                    subtitle: const Text('Farklı bildirim sesi kullan'),
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
                  
                  // Alarm süresi seçici
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alarm Süresi'),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          '${alarmDuration} saniye', 
                          style: AppTextStyles.bodyTextBold,
                        ),
                        Slider(
                          value: alarmDuration.toDouble(),
                          min: 10,
                          max: 60,
                          divisions: 5,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.primary.withOpacity(0.2),
                          label: '$alarmDuration saniye',
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
                  
                  // Titreşim açık/kapalı
                  SwitchListTile(
                    title: const Text('Titreşim'),
                    subtitle: const Text('Bildirim ile birlikte titreşim'),
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
                  
                  // Hatırlatma aralığı seçici
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tekrar Hatırlatma Aralığı'),
                        const SizedBox(height: AppDimens.paddingXS),
                        const Text(
                          'İlaç alınmadığında tekrar hatırlatma süresi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          '$reminderInterval dakika', 
                          style: AppTextStyles.bodyTextBold,
                        ),
                        Slider(
                          value: reminderInterval.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 6,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.primary.withOpacity(0.2),
                          label: '$reminderInterval dakika',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Yeni ayarları oluştur
                final newSettings = NotificationSettings(
                  enableNotifications: enableNotifications,
                  enableAlarms: enableAlarms,
                  alarmDuration: alarmDuration,
                  alarmType: alarmType,
                  vibrate: vibrate,
                  reminderInterval: reminderInterval,
                );
                
                // Kullanıcı profilini yeni ayarlarla güncelle
                _updateNotificationSettings(provider, newSettings);
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Notification ayarlarını güncellemek için
  Future<void> _updateNotificationSettings(
    UserProfileProvider provider, 
    NotificationSettings newSettings
  ) async {
    final updatedProfile = provider.userProfile!.copyWith(
      notificationSettings: newSettings,
    );
    
    await provider.updateUserProfile(updatedProfile);
    
    // Başarı mesajı göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim ayarları güncellendi'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  }