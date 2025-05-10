import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/medications/screens/add_medication_screen.dart';
import 'package:medalarmm/features/medications/screens/medication_detail_screen.dart';
import 'package:medalarmm/features/medications/widgets/medication_list.dart';
import 'package:medalarmm/common/widgets/loading_indicator.dart';
import 'package:medalarmm/features/notifications/widgets/notification_widget.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  @override
  void initState() {
    super.initState();
    // Uygulama açıldığında ilaç verilerini yükle
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İlaçlarım',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Verileri Yenile',
            onPressed: () {
              _refreshData();
              NotificationWidget.showSnackBar(
                context: context,
                message: 'İlaç verileri yenilendi',
                type: NotificationType.info,
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(message: 'İlaçlar yükleniyor...');
          }

          // MedicationList widget'ını kullan
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  'İlaçlarınız',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  'Tüm ilaçlarınızı buradan yönetebilirsiniz',
                  style: AppTextStyles.bodyTextSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
                Expanded(
                  child: MedicationList(
                    medications: provider.medications,
                    showEmpty: true,
                    emptyTitle: 'Henüz İlaç Eklenmemiş',
                    emptyMessage: 'İlaçlarınızı eklemek için aşağıdaki butona tıklayın.',
                    emptyActionText: 'İlaç Ekle',
                    onEmptyActionPressed: _navigateToAddMedication,
                    onRefresh: _refreshData,
                    onMedicationTap: _navigateToMedicationDetail,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddMedication,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İlaç'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
    );
  }

  // İlaç kartını oluştur
  Widget _buildMedicationCard(Medication medication, MedicationProvider provider) {
    final adherencePercentage = provider.getMedicationAdherencePercentage(medication.id);
    final missedDosesCount = provider.getMissedDosesCount(medication.id);
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      elevation: 4,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(
          color: medication.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToMedicationDetail(medication),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Stack(
          children: [
            if (!medication.isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(AppDimens.radiusM),
                      bottomLeft: Radius.circular(AppDimens.radiusS),
                    ),
                  ),
                  child: Text(
                    'Pasif',
                    style: AppTextStyles.captionBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircularPercentIndicator(
                    radius: 40.0,
                    lineWidth: 8.0,
                    percent: adherencePercentage / 100,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${adherencePercentage.toInt()}%',
                          style: AppTextStyles.heading3.copyWith(
                            color: _getProgressColor(adherencePercentage),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'uyum',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    progressColor: _getProgressColor(adherencePercentage),
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 600,
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medication.name,
                                style: AppTextStyles.heading3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingS,
                                vertical: AppDimens.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: medication.isActive
                                    ? AppColors.success.withAlpha(26)
                                    : AppColors.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                              ),
                              child: Text(
                                medication.isActive ? 'Aktif' : 'Pasif',
                                style: AppTextStyles.captionBold.copyWith(
                                  color: medication.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingS,
                            vertical: AppDimens.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppDimens.radiusS),
                          ),
                          child: Text(
                            'Dozaj: ${medication.dosage}',
                            style: AppTextStyles.bodyTextSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingS),
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
                              color: AppColors.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(AppDimens.radiusS),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$missedDosesCount doz alınmadı',
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (medication.currentStock != null && medication.currentStock! > 0) ...[
                          const SizedBox(height: AppDimens.paddingS),
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: AppDimens.iconSizeS,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppDimens.paddingXS),
                              Text(
                                'Stok: ${medication.currentStock} adet',
                                style: AppTextStyles.bodyTextSmall.copyWith(
                                  color: medication.stockThreshold != null && 
                                        medication.currentStock! < medication.stockThreshold!
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                  fontWeight: medication.stockThreshold != null && 
                                              medication.currentStock! < medication.stockThreshold!
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // İlerleme çubuğu rengi
  Color _getProgressColor(double percentage) {
    if (percentage >= 80) {
      return AppColors.success;
    } else if (percentage >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.error;
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