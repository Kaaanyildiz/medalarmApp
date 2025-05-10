import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/core/models/user_profile.dart';
import 'package:medalarmm/features/profile/widgets/bmi_gauge_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthMetricsChartWidget extends StatelessWidget {
  final UserProfile userProfile;
  final List<Map<String, dynamic>> weightHistory; // {date: DateTime, weight: double}
  
  const HealthMetricsChartWidget({
    Key? key,
    required this.userProfile,
    required this.weightHistory,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BMI Göstergesi
        if (userProfile.bmi != null) ...[
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: BMIGaugeWidget(bmi: userProfile.bmi!),
          ),
          const SizedBox(height: AppDimens.paddingM),
        ],
        
        // Ağırlık Grafiği
        if (weightHistory.length > 1) ...[
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: _buildWeightChart(),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Henüz yeterli ağırlık geçmişi bulunmuyor',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    Text(
                      'Ağırlık verilerinizi düzenli olarak güncelleyerek zaman içinde değişimleri görebilirsiniz.',
                      style: AppTextStyles.bodyTextSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
    
  Widget _buildWeightChart() {
    // En düşük ve en yüksek değerleri hesapla
    final minWeight = weightHistory.map((e) => e['weight'] as double).reduce((a, b) => a < b ? a : b);
    final maxWeight = weightHistory.map((e) => e['weight'] as double).reduce((a, b) => a > b ? a : b);
    
    // Y ekseni için değer aralığı belirle
    final minY = (minWeight - 5).roundToDouble();
    final maxY = (maxWeight + 5).roundToDouble();
    
    // X ekseni için tarihleri sırala
    final sortedHistory = List<Map<String, dynamic>>.from(weightHistory)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Grafik noktaları oluştur
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedHistory[i]['weight'] as double));
    }
    
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ağırlık Değişimi',
                  style: AppTextStyles.heading3,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: AppDimens.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: Text(
                    'Son: ${sortedHistory.last['weight']} kg',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Şu anki durum: ${_getWeightTrendText()}',
              style: AppTextStyles.bodyTextSmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 5,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedHistory.length) {
                            return const SizedBox();
                          }
                          final date = sortedHistory[index]['date'] as DateTime;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${date.day}/${date.month}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()} kg',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.divider),
                  ),
                  minX: 0,
                  maxX: (sortedHistory.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
            // Trend bilgisi
            const SizedBox(height: AppDimens.paddingM),
            Row(
              children: [
                Icon(
                  _getWeightTrendIcon(),
                  color: _getWeightTrendColor(),
                  size: 20,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  _getWeightTrendText(),
                  style: AppTextStyles.bodyTextSmall.copyWith(
                    color: _getWeightTrendColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Ağırlık trendi ikonu
  IconData _getWeightTrendIcon() {
    if (weightHistory.length < 2) return Icons.horizontal_rule;
    
    final sortedHistory = List<Map<String, dynamic>>.from(weightHistory)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    final firstWeight = sortedHistory.first['weight'] as double;
    final lastWeight = sortedHistory.last['weight'] as double;
    
    final difference = lastWeight - firstWeight;
    
    if (difference > 1) return Icons.arrow_upward;
    if (difference < -1) return Icons.arrow_downward;
    return Icons.horizontal_rule;
  }
  
  // Ağırlık trendi rengi
  Color _getWeightTrendColor() {
    if (weightHistory.length < 2) return AppColors.textSecondary;
    
    final sortedHistory = List<Map<String, dynamic>>.from(weightHistory)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    final firstWeight = sortedHistory.first['weight'] as double;
    final lastWeight = sortedHistory.last['weight'] as double;
    
    final difference = lastWeight - firstWeight;
    
    // BMI'ya göre renk değişimi
    if (userProfile.bmi != null) {
      final bmi = userProfile.bmi!;
      
      if (bmi < 18.5) { // Zayıf
        return difference > 0 ? Colors.green : Colors.red;
      } else if (bmi < 25) { // Normal
        return difference.abs() < 1 ? Colors.green : (difference > 0 ? Colors.orange : Colors.blue);
      } else if (bmi < 30) { // Fazla kilolu
        return difference < 0 ? Colors.green : Colors.orange;
      } else { // Obez
        return difference < 0 ? Colors.green : Colors.red;
      }
    }
    
    return AppColors.textSecondary;
  }
  
  // Ağırlık trendi metni
  String _getWeightTrendText() {
    if (weightHistory.length < 2) return 'Trend bilgisi için en az iki ölçüm gerekir';
    
    final sortedHistory = List<Map<String, dynamic>>.from(weightHistory)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    final firstWeight = sortedHistory.first['weight'] as double;
    final lastWeight = sortedHistory.last['weight'] as double;
    final firstDate = sortedHistory.first['date'] as DateTime;
    final lastDate = sortedHistory.last['date'] as DateTime;
    
    final difference = lastWeight - firstWeight;
    final days = lastDate.difference(firstDate).inDays;
    
    if (difference.abs() < 0.5) {
      return 'Son $days günde kilonuz stabil kalmış';
    } else if (difference > 0) {
      return 'Son $days günde ${difference.toStringAsFixed(1)} kg almışsınız';
    } else {
      return 'Son $days günde ${(-difference).toStringAsFixed(1)} kg vermişsiniz';
    }
  }
}
