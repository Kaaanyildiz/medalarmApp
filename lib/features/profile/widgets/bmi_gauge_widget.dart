import 'package:flutter/material.dart';
import 'dart:math';
import 'package:medalarmm/common/constants/app_constants.dart';

class BMIGaugeWidget extends StatelessWidget {
  final double bmi;
  
  const BMIGaugeWidget({
    Key? key,
    required this.bmi,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // BMI durumları
    const double underweightThreshold = 18.5;
    const double normalThreshold = 25.0;
    const double overweightThreshold = 30.0;
    
    // Renk ve durum ayarlamaları
    Color gaugeColor;
    String statusText;
    String descriptionText;
    double progress;
    
    if (bmi < underweightThreshold) {
      gaugeColor = Colors.blue;
      statusText = 'Zayıf';
      descriptionText = 'Beslenmenizi çeşitlendirmelisiniz';
      progress = bmi / underweightThreshold;
    } else if (bmi < normalThreshold) {
      gaugeColor = AppColors.success;
      statusText = 'Normal';
      descriptionText = 'İdeal kilonuzdasınız, böyle devam edin';
      // 0.33-0.66 arası bir değer hesapla
      progress = 0.33 + ((bmi - underweightThreshold) / (normalThreshold - underweightThreshold)) * 0.33;
    } else if (bmi < overweightThreshold) {
      gaugeColor = AppColors.warning;
      statusText = 'Fazla Kilolu';
      descriptionText = 'Daha fazla hareket etmelisiniz';
      // 0.66-0.85 arası bir değer hesapla
      progress = 0.66 + ((bmi - normalThreshold) / (overweightThreshold - normalThreshold)) * 0.19;
    } else {
      gaugeColor = AppColors.error;
      statusText = 'Obez';
      descriptionText = 'Sağlığınız için kilo vermelisiniz';
      // 0.85-1.0 arası bir değer hesapla
      progress = 0.85 + min((bmi - overweightThreshold) / 10.0, 0.15);
    }
    
    // Progress değerini 0.0-1.0 arasında sınırla
    progress = progress.clamp(0.0, 1.0);
    
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
            // BMI başlık ve değeri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vücut Kitle İndeksi (VKİ)',
                  style: AppTextStyles.heading3,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: gaugeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(
                      color: gaugeColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${bmi.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: gaugeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
              // BMI Gauge göstergesi
            Container(
              height: 30,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                color: Colors.grey.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Zayıf bölgesi
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.radiusM),
                          bottomLeft: Radius.circular(AppDimens.radiusM),
                        ),
                        color: Colors.blue.withOpacity(0.5),
                      ),
                    ),
                  ),
                  // Normal bölgesi
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: AppColors.success.withOpacity(0.5),
                    ),
                  ),
                  // Fazla kilolu bölgesi
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: AppColors.warning.withOpacity(0.5),
                    ),
                  ),
                  // Obez bölgesi
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(AppDimens.radiusM),
                          bottomRight: Radius.circular(AppDimens.radiusM),
                        ),
                        color: AppColors.error.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              // BMI imleci
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: (progress * (MediaQuery.of(context).size.width - 64)) - 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_drop_down,
                    color: gaugeColor,
                    size: 32,
                  ),
                ],
              ),
            ),
            
            // BMI durum bilgisi
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: gaugeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(
                  color: gaugeColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(statusText),
                    color: gaugeColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: AppTextStyles.bodyTextBold.copyWith(
                            color: gaugeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          descriptionText,
                          style: AppTextStyles.bodyTextSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // BMI göstergesinin açıklamaları
            const SizedBox(height: AppDimens.paddingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBMILabel('Zayıf', '<18.5', Colors.blue),
                _buildBMILabel('Normal', '18.5-25', AppColors.success),
                _buildBMILabel('Fazla Kilolu', '25-30', AppColors.warning),
                _buildBMILabel('Obez', '>30', AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Zayıf':
        return Icons.sentiment_dissatisfied;
      case 'Normal':
        return Icons.sentiment_very_satisfied;
      case 'Fazla Kilolu':
        return Icons.sentiment_neutral;
      case 'Obez':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.info_outline;
    }
  }
  
  Widget _buildBMILabel(String text, String range, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          range,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  // Math.min yerine uygun alternatif
  double min(double a, double b) => a < b ? a : b;
}

