import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/medications/screens/medication_detail_screen.dart';
import 'package:medalarmm/features/medications/screens/add_medication_screen.dart';
import 'package:medalarmm/common/widgets/empty_state.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Updated import for percent_indicator
import 'package:provider/provider.dart';

/// İlaç listesi widget'ı
/// Bu widget kullanılarak uygulama içindeki farklı bölümlerde
/// ilaç listesini tutarlı bir görsel tarzla gösterebiliriz
class MedicationList extends StatelessWidget {
  final List<Medication> medications;
  final bool showEmpty;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback? onEmptyActionPressed;
  final String? emptyActionText;
  final VoidCallback? onRefresh;
  final Function(Medication)? onMedicationTap;

  const MedicationList({
    super.key, // Changed from Key? key to super.key
    required this.medications,
    this.showEmpty = true,
    this.emptyTitle = 'İlaç Bulunamadı',
    this.emptyMessage = 'Henüz ilaç eklenmemiş',
    this.onEmptyActionPressed,
    this.emptyActionText = 'İlaç Ekle',
    this.onRefresh,
    this.onMedicationTap,
  }); // Removed the : super(key: key); as it's now included directly in the parameter list

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty && showEmpty) {
      return EmptyState(
        icon: Icons.medication,
        title: emptyTitle,
        message: emptyMessage,
        buttonText: emptyActionText,
        onButtonPressed: onEmptyActionPressed,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return _buildMedicationCard(medication, context);
      },
    );
  }

  /// İlaç kartı widget'ı
  Widget _buildMedicationCard(Medication medication, BuildContext context) {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final adherencePercentage = provider.getMedicationAdherencePercentage(medication.id);
    final missedDosesCount = provider.getMissedDosesCount(medication.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: InkWell(
          onTap: () {
            if (onMedicationTap != null) {
              onMedicationTap!(medication);
            } else {
              _navigateToMedicationDetail(medication, context);
            }
          },
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(
                color: medication.color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                if (!medication.isActive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(AppDimens.radiusM - 1),
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
                Column(
                  children: [
                    // Üst bilgi çubuğu
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingM,
                        vertical: AppDimens.paddingS,
                      ),
                      decoration: BoxDecoration(
                        color: medication.color.withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.radiusM - 1),
                          topRight: Radius.circular(AppDimens.radiusM - 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication,
                            color: medication.color,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimens.paddingXS),
                          Expanded(
                            child: Text(
                              medication.name,
                              style: AppTextStyles.bodyTextBold.copyWith(
                                color: medication.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (medication.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                              ),
                              child: Text(
                                'Aktif',
                                style: AppTextStyles.captionBold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // İlaç bilgileri
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingM),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Uyum yüzdesi göstergesi
                          CircularPercentIndicator(
                            radius: 36.0,
                            lineWidth: 6.0,
                            percent: adherencePercentage / 100,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${adherencePercentage.toInt()}%',
                                  style: AppTextStyles.bodyTextBold.copyWith(
                                    color: _getProgressColor(adherencePercentage),
                                  ),
                                ),
                                Text(
                                  'uyum',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textLight,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            progressColor: _getProgressColor(adherencePercentage),
                            backgroundColor: AppColors.primaryLight.withOpacity(0.3), // Changed from backgroundLight to primaryLight with opacity
                            circularStrokeCap: CircularStrokeCap.round,
                            animation: true,
                            animationDuration: 600,
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          // İlaç detayları
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dozaj bilgisi
                                if (medication.dosage != null && medication.dosage!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingS,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: medication.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                    ),
                                    child: Text(
                                      medication.dosage!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: medication.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                
                                // Alım zamanları
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: AppDimens.iconSizeS,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: AppDimens.paddingXS),
                                    Expanded(
                                      child: Text(
                                        _formatTimes(medication.timesOfDay),
                                        style: AppTextStyles.bodyTextSmall.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: AppDimens.paddingXS),
                                
                                // Alım günleri
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
                                
                                // Kaçırılan doz uyarısı
                                if (missedDosesCount > 0) ...[
                                  const SizedBox(height: AppDimens.paddingS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingS,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                        width: 1,
                                      ),
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
                                  // Stok durumu
                                if (medication.currentStock != null) ...[
                                  const SizedBox(height: AppDimens.paddingS),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: AppDimens.iconSizeS,
                                        color: _getStockColor(medication),
                                      ),
                                      const SizedBox(width: AppDimens.paddingXS),
                                      Text(
                                        'Stok: ${medication.currentStock} ${medication.stockUnit ?? 'adet'}',
                                        style: AppTextStyles.bodyTextSmall.copyWith(
                                          color: _getStockColor(medication),
                                          fontWeight: _isLowStock(medication) ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                  // Düzenle ve Detay butonları
                                const SizedBox(height: AppDimens.paddingM),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Düzenle butonu
                                    OutlinedButton.icon(
                                      onPressed: () => _navigateToEditMedication(medication, context),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Düzenle'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: medication.color,
                                        side: BorderSide(
                                          color: medication.color.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimens.paddingM,
                                          vertical: AppDimens.paddingXS,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppDimens.paddingS),
                                    // Detay butonu
                                    OutlinedButton.icon(
                                      onPressed: () => _navigateToMedicationDetail(medication, context),
                                      icon: const Icon(Icons.visibility, size: 18),
                                      label: const Text('Detay'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                          color: AppColors.primary.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimens.paddingM,
                                          vertical: AppDimens.paddingXS,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// İlerleme çubuğu rengi
  Color _getProgressColor(double percentage) {
    if (percentage >= 80) {
      return AppColors.success;
    } else if (percentage >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  /// Stok rengi
  Color _getStockColor(Medication medication) {
    if (_isLowStock(medication)) {
      return AppColors.warning;
    }
    return AppColors.textSecondary;
  }

  /// Düşük stok kontrolü
  bool _isLowStock(Medication medication) {
    return medication.stockThreshold != null && 
           medication.currentStock != null &&
           medication.currentStock! <= medication.stockThreshold!;
  }

  /// Zamanları formatla
  String _formatTimes(List<TimeOfDay> times) {
    if (times.isEmpty) return 'Zaman belirtilmemiş';
    
    List<String> timeStrings = times.map((time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }).toList();
    
    return timeStrings.join(', ');
  }

  /// Günleri formatla
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
  /// İlaç detay ekranına git
  void _navigateToMedicationDetail(Medication medication, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(medication: medication),
      ),
    ).then((_) {
      if (onRefresh != null) {
        onRefresh!();
      }
    });
  }
  
  /// İlaç düzenleme ekranına git
  void _navigateToEditMedication(Medication medication, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(medication: medication),
      ),
    ).then((value) {
      if (value == true && onRefresh != null) {
        onRefresh!();
      }
    });
  }
}