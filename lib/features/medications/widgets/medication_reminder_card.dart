import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/notifications/widgets/notification_widget.dart';
import 'package:provider/provider.dart';

class MedicationReminderCard extends StatelessWidget {
  final Medication medication;
  final MedicationLog log;
  final VoidCallback? onRefresh;

  const MedicationReminderCard({
    super.key, // Updated from Key? key to super.key
    required this.medication,
    required this.log,
    this.onRefresh,
  }); // Removed the : super(key: key); as it's now included in the parameter list

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final timeFormat = DateFormat('HH:mm');

    // İlaç durumu
    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool canTake = false;

    if (log.isTaken) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'Alındı';
    } else if (log.isSkipped) {
      statusColor = AppColors.warning;
      statusIcon = Icons.cancel_outlined;
      statusText = 'Atlandı';
    } else if (DateTime.now().isAfter(log.scheduledTime)) {
      statusColor = AppColors.error;
      statusIcon = Icons.error_outline;
      statusText = 'Alınmadı';
      canTake = true;
    } else {
      statusColor = AppColors.primary;
      statusIcon = Icons.schedule;
      statusText = 'Bekliyor';

      // Eğer planlanan zamana 30 dakika veya daha az kaldıysa, şimdiden alınabilir
      final timeUntil = log.scheduledTime.difference(DateTime.now());
      if (timeUntil.inMinutes <= 30) {
        canTake = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: medication.color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Expanded(
                      child: Text(
                        statusText,
                        style: AppTextStyles.bodyTextBold.copyWith(
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      timeFormat.format(log.scheduledTime),
                      style: AppTextStyles.bodyTextBold.copyWith(
                        color: medication.color,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // İlaç bilgisi
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: medication.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.medication,
                          color: medication.color,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (medication.dosage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              medication.dosage!,
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (medication.instructions != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              medication.instructions!,
                              style: AppTextStyles.bodyTextSmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Alım butonları
              if (!log.isTaken && !log.isSkipped) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimens.paddingM,
                    right: AppDimens.paddingM,
                    bottom: AppDimens.paddingM,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canTake ? () => _showSkipDialog(context) : null,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Atla'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: BorderSide(
                              color: canTake ? AppColors.warning : AppColors.warning.withOpacity(0.3),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canTake ? () => _markAsTaken(context) : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aldım'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusM),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Alındı bilgisi
              if (log.isTaken && log.takenTime != null) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimens.paddingM,
                    right: AppDimens.paddingM,
                    bottom: AppDimens.paddingM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM,
                      vertical: AppDimens.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimens.paddingS),
                        Expanded(
                          child: Text(
                            'Alındı: ${timeFormat.format(log.takenTime!)}',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (log.delayInMinutes != null && log.delayInMinutes! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: log.delayInMinutes! > 30
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimens.radiusL),
                            ),
                            child: Text(
                              '+${log.delayInMinutes} dk',
                              style: AppTextStyles.captionBold.copyWith(
                                color: log.delayInMinutes! > 30
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              // Atlandı bilgisi
              if (log.isSkipped) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimens.paddingM,
                    right: AppDimens.paddingM,
                    bottom: AppDimens.paddingM,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM,
                      vertical: AppDimens.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimens.paddingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atlandı',
                                style: AppTextStyles.bodyText.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Not: ${log.notes}',
                                  style: AppTextStyles.bodyTextSmall.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // İlacı alındı olarak işaretle
  Future<void> _markAsTaken(BuildContext context) async {
    final provider = Provider.of<MedicationProvider>(context, listen: false);

    try {
      await provider.markMedicationAsTaken(
        medicationId: medication.id,
        scheduledTime: log.scheduledTime,
      );

      if (context.mounted) {
        NotificationWidget.showSnackBar(
          context: context,
          message: '${medication.name} alındı olarak işaretlendi',
          type: NotificationType.success,
        );

        if (onRefresh != null) {
          onRefresh!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationWidget.showSnackBar(
          context: context,
          message: 'Hata: İlaç alındı olarak işaretlenemedi',
          type: NotificationType.error,
        );
      }
    }
  }

  // İlacı atlamak için onay al
  Future<void> _showSkipDialog(BuildContext context) async {
    final TextEditingController noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlacı Atla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu ilacı almayı atlamak istediğinizden emin misiniz?',
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: 'Atlama nedenini belirtebilirsiniz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  borderSide: BorderSide(
                    color: AppColors.primaryLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.primaryLight.withOpacity(0.2), // Changed from backgroundLight to primaryLight with opacity
              ),
              maxLines: 2,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Atla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final provider = Provider.of<MedicationProvider>(context, listen: false);

      try {
        await provider.markMedicationAsSkipped(
          medicationId: medication.id,
          scheduledTime: log.scheduledTime,
          notes: noteController.text.isNotEmpty ? noteController.text : null,
        );

        if (context.mounted) {
          NotificationWidget.showSnackBar(
            context: context,
            message: '${medication.name} atlandı olarak işaretlendi',
            type: NotificationType.warning,
          );

          if (onRefresh != null) {
            onRefresh!();
          }
        }
      } catch (e) {
        if (context.mounted) {
          NotificationWidget.showSnackBar(
            context: context,
            message: 'Hata: İlaç atlandı olarak işaretlenemedi',
            type: NotificationType.error,
          );
        }
      }
    }
  }
}
