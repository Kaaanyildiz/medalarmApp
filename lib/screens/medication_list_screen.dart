import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/models/medication.dart';
import 'package:medalarmm/providers/medication_provider.dart';
import 'package:medalarmm/screens/add_medication_screen.dart';
import 'package:medalarmm/screens/medication_detail_screen.dart';
import 'package:medalarmm/widgets/empty_state.dart';
import 'package:medalarmm/widgets/loading_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaçlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshData();
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          if (provider.medications.isEmpty) {
            return EmptyState(
              icon: Icons.medication,
              title: 'Henüz İlaç Eklenmemiş',
              message: 'İlaçlarınızı eklemek için aşağıdaki butona tıklayın.',
              buttonText: 'İlaç Ekle',
              onButtonPressed: () => _navigateToAddMedication(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugünkü İlaçlarınız',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppDimens.paddingM),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.medications.length,
                    itemBuilder: (context, index) {
                      final medication = provider.medications[index];
                      return _buildMedicationCard(medication, provider);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMedication,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // İlaç kartını oluştur
  Widget _buildMedicationCard(Medication medication, MedicationProvider provider) {
    final adherencePercentage = provider.getMedicationAdherencePercentage(medication.id);
    final missedDosesCount = provider.getMissedDosesCount(medication.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      child: InkWell(
        onTap: () => _navigateToMedicationDetail(medication),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircularPercentIndicator(
                radius: 35.0,
                lineWidth: 8.0,
                percent: adherencePercentage / 100,
                center: Text(
                  '${adherencePercentage.toInt()}%',
                  style: AppTextStyles.heading3,
                ),
                progressColor: _getProgressColor(adherencePercentage),
                backgroundColor: AppColors.background,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: AppTextStyles.heading3,                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    Text(
                      'Dozaj: ${medication.dosage}',
                      style: AppTextStyles.bodyText,
                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    Text(
                      'Günde ${medication.timesPerDay} kez',
                      style: AppTextStyles.bodyTextSmall,
                    ),
                    const SizedBox(height: AppDimens.paddingXS),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: AppDimens.iconSizeS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimens.paddingXS),
                        Text(
                          _formatDays(medication.daysOfWeek),
                          style: AppTextStyles.bodyTextSmall,
                        ),
                      ],
                    ),
                    if (missedDosesCount > 0) ...[
                      const SizedBox(height: AppDimens.paddingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingS,
                          vertical: AppDimens.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(26), // 0.1 * 255 = ~26
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: Text(
                          '$missedDosesCount doz alınmadı',
                          style: AppTextStyles.bodyTextSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS,
                      vertical: AppDimens.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: medication.isActive
                          ? AppColors.success.withAlpha(26)  // 0.1 * 255 = ~26
                          : AppColors.error.withAlpha(26),   // 0.1 * 255 = ~26
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: Text(
                      medication.isActive ? 'Aktif' : 'Pasif',
                      style: AppTextStyles.bodyTextSmall.copyWith(
                        color: medication.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                  if (medication.currentStock != null && medication.currentStock! > 0) ...[
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      '${medication.currentStock} adet',
                      style: AppTextStyles.bodyTextSmall.copyWith(
                        color: medication.stockThreshold != null && medication.currentStock! < medication.stockThreshold!
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // İlerleme çubuğu rengi
  Color _getProgressColor(double percentage) {
    if (percentage < 50) {
      return AppColors.error;
    } else if (percentage < 80) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  // Günleri formatla
  String _formatDays(List<DayOfWeek> days) {
    if (days.length == 7) {
      return 'Her gün';
    }
    
    List<String> formattedDays = days.map((dayEnum) {
      final index = dayEnum.index;
      final dayStr = AppConstants.weekDays[index];
      return AppConstants.weekDaysMap[dayStr] ?? dayStr;
    }).toList();
    
    if (formattedDays.length <= 3) {
      return formattedDays.join(', ');
    } else {
      return '${formattedDays.length} gün';
    }
  }

  // Veriyi yenile
  Future<void> _refreshData() async {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    await provider.loadMedications();
    await provider.loadMedicationLogs();
  }

  // İlaç ekleme ekranına git
  void _navigateToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
      ),
    ).then((_) => _refreshData());
  }

  // İlaç detay ekranına git
  void _navigateToMedicationDetail(Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(medication: medication),
      ),
    ).then((_) => _refreshData());
  }
}