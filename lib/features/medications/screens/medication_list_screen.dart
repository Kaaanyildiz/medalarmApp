import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
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
  late AppLocalizations loc;

  @override
  void initState() {
    super.initState();
    // Load medication data when app opens
    _refreshData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loc = AppLocalizations.of(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('medications'),
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
            tooltip: loc.translate('refresh_data'),
            onPressed: () {
              _refreshData();
              NotificationWidget.showSnackBar(
                context: context,
                message: loc.translate('medications_refreshed'),
                type: NotificationType.info,
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {          if (provider.isLoading) {
            return LoadingIndicator(message: loc.translate('loading') + '...');
          }          // Use MedicationList widget
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  loc.translate('medications'),
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Text(
                  loc.translate('add_medications_prompt'),
                  style: AppTextStyles.bodyTextSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),                Expanded(
                  child: MedicationList(
                    medications: provider.medications,
                    showEmpty: true,
                    emptyTitle: loc.translate('no_medications'),
                    emptyMessage: loc.translate('add_medications_prompt'),
                    emptyActionText: loc.translate('add_medication'),
                    onEmptyActionPressed: _navigateToAddMedication,
                    onRefresh: _refreshData,
                    onMedicationTap: _navigateToMedicationDetail,
                  ),
                ),
              ],
            ),
          );
        },
      ),      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddMedication,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(loc.translate('add_medication')),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
    );
  }
  // Create medication card
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
                  ),                  child: Text(
                    loc.translate('inactive'),
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
                        ),                        Text(
                          loc.translate('adherence'),
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
                              ),                              child: Text(
                                medication.isActive ? loc.translate('active') : loc.translate('inactive'),
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
                          ),                          child: Text(
                            '${loc.translate('dosage')}: ${medication.dosage}',
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
                                const SizedBox(width: 4),                                Text(
                                  '$missedDosesCount ${loc.translate('missed_doses')}',
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
                              const SizedBox(width: AppDimens.paddingXS),                              Text(
                                '${loc.translate('stock')}: ${medication.currentStock} ${loc.translate('inventory_units_count')}',
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
  // Progress bar color
  Color _getProgressColor(double percentage) {
    if (percentage >= 80) {
      return AppColors.success;
    } else if (percentage >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
  // Format days
  String _formatDays(List<DayOfWeek> days) {
    if (days.length == 7) {
      return loc.translate('daily');
    }
    
    List<String> formattedDays = days.map((dayEnum) {
      final index = dayEnum.index;
      final dayStr = AppConstants.weekDays[index];
      return AppConstants.weekDaysMap[dayStr] ?? dayStr;
    }).toList();
    
    if (formattedDays.length <= 3) {
      return formattedDays.join(', ');
    } else {
      return '${formattedDays.length} ${loc.translate('days')}';
    }
  }
  // Refresh data
  Future<void> _refreshData() async {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    await provider.loadMedications();
    await provider.loadMedicationLogs();
  }
  // Navigate to add medication screen
  void _navigateToAddMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
      ),
    ).then((_) => _refreshData());
  }
  // Navigate to medication detail screen
  void _navigateToMedicationDetail(Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(medication: medication),
      ),
    ).then((_) => _refreshData());
  }
}