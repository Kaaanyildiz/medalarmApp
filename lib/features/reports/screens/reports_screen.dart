import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/core/models/user_profile.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/profile/providers/user_profile_provider.dart';
import 'package:medalarmm/features/reports/services/report_service.dart';
import 'package:medalarmm/features/profile/widgets/health_metrics_chart_widget.dart';
import 'package:medalarmm/common/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  
  // Raporlama dönemi
  ReportPeriod _reportPeriod = ReportPeriod.week;
  
  // Durumlar
  bool _isLoading = true;
  List<MedicationAdherenceReport> _adherenceReports = [];
  List<Medication> _medications = [];
  String? _selectedMedicationId;
    @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Verileri yükle
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Dönem başlangıç ve bitiş tarihlerini belirle
      final DateTime now = DateTime.now();
      DateTime startDate;
      
      switch (_reportPeriod) {
        case ReportPeriod.week:
          startDate = DateTime(
            now.year, now.month, now.day - 7);
          break;
        case ReportPeriod.month:
          startDate = DateTime(
            now.year, now.month - 1, now.day);
          break;
        case ReportPeriod.year:
          startDate = DateTime(
            now.year - 1, now.month, now.day);
          break;
      }
      
      // İlaç listesini al
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      _medications = medicationProvider.medications;
      
      if (_medications.isNotEmpty && _selectedMedicationId == null) {
        _selectedMedicationId = _medications.first.id;
      }
      
      // Tüm ilaçlar için uyum raporlarını al
      _adherenceReports = await _reportService.getAllMedicationsAdherenceReport(
        startDate: startDate,
        endDate: now,
      );
    } catch (e) {
      print('Rapor verileri yüklenirken hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Raporlar'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: AppTextStyles.caption.copyWith(
            fontSize: 12,
          ),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_rounded, size: 20),
              text: 'Genel Bakış',
            ),
            Tab(
              icon: Icon(Icons.trending_up_rounded, size: 20),
              text: 'Uyum Raporları',
            ),
            Tab(
              icon: Icon(Icons.medication_rounded, size: 20),
              text: 'İlaç Detayları',
            ),
            Tab(
              icon: Icon(Icons.monitor_heart_rounded, size: 20),
              text: 'Sağlık Metrikleri',
            ),
          ],
        ),        actions: [
          PopupMenuButton<ReportPeriod>(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Rapor dönemini seç',
            onSelected: (ReportPeriod period) {
              setState(() {
                _reportPeriod = period;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ReportPeriod.week,
                child: Text('Son 7 Gün'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.month,
                child: Text('Son 30 Gün'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.year,
                child: Text('Son 365 Gün'),
              ),
            ],
          ),
        ],
      ),      body: _isLoading
          ? const Center(child: LoadingIndicator(message: 'Raporlar yükleniyor...'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAdherenceReportsTab(),
                _buildMedicationDetailsTab(),
                _buildHealthMetricsTab(),
              ],
            ),
    );
  }
  
  Widget _buildOverviewTab() {
    // Başarılı ilaç sayısı (uyum oranı > %80)
    final successfulMedications = _adherenceReports
        .where((report) => report.adherenceRate >= 0.8)
        .length;
    
    // Kısmen başarılı ilaç sayısı (uyum oranı %50-80)
    final partialSuccessMedications = _adherenceReports
        .where((report) => report.adherenceRate >= 0.5 && report.adherenceRate < 0.8)
        .length;
    
    // Düşük performanslı ilaç sayısı (uyum oranı < %50)
    final lowPerformanceMedications = _adherenceReports
        .where((report) => report.adherenceRate < 0.5)
        .length;
    
    // Genel uyum oranı (tüm ilaçların ortalaması)
    final double overallAdherence = _adherenceReports.isEmpty
        ? 0.0
        : _adherenceReports.fold(0.0, (sum, report) => sum + report.adherenceRate) / _adherenceReports.length;
    
    // Toplam planlanan ve alınan dozlar
    final int totalPlannedDoses = _adherenceReports.fold(0, (sum, report) => sum + report.totalDoses);
    final int totalTakenDoses = _adherenceReports.fold(0, (sum, report) => sum + report.takenDoses);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          // Dönem bilgisi
          Text(
            _getReportPeriodTitle(),
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          
          // Genel uyum kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  const Text(
                    'Genel İlaç Uyum Oranı',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: overallAdherence,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAdherenceColor(overallAdherence),
                    ),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),                  Text(
                    '%${(overallAdherence * 100).round()}',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAdherenceColor(overallAdherence),
                    ),
                  ),
                  const SizedBox(height: 8),                  Text(
                    'Toplam $totalTakenDoses / $totalPlannedDoses doz alındı',
                    style: AppTextStyles.bodyTextSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Performans kartları
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'İyi',
                  successfulMedications,
                  _adherenceReports.length,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPerformanceCard(
                  'Orta',
                  partialSuccessMedications,
                  _adherenceReports.length,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPerformanceCard(
                  'Düşük',
                  lowPerformanceMedications,
                  _adherenceReports.length,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
            // En kötü performanslı ilaçlar
          Text(
            'Dikkat Edilmesi Gereken İlaçlar',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          ..._buildWorstPerformingMedicationsWidgets(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceCard(String title, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(          children: [
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: AppTextStyles.heading2.copyWith(
                color: color,
                fontSize: 24,
              ),
            ),
            Text(
              'ilaç (%$percentage)',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildWorstPerformingMedicationsWidgets() {
    // En düşük uyum oranlı 3 ilaç
    final worstReports = List.of(_adherenceReports)
      ..sort((a, b) => a.adherenceRate.compareTo(b.adherenceRate));
    
    final displayReports = worstReports.take(3).toList();
    
    if (displayReports.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Henüz yeterli ilaç kullanım verisi bulunmuyor.'),
          ),
        ),
      ];
    }
    
    return displayReports.map((report) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: report.medication.color,
            child: Text(
              report.medication.name.substring(0, 1),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(report.medication.name),
          subtitle: Text(
            'Uyum: %${(report.adherenceRate * 100).round()} - ${report.takenDoses}/${report.totalDoses} doz',
          ),
          trailing: Icon(
            Icons.warning,
            color: _getAdherenceColor(report.adherenceRate),
          ),
        ),
      );
    }).toList();
  }
  
  Widget _buildAdherenceReportsTab() {
    if (_adherenceReports.isEmpty) {
      return const Center(
        child: Text('Henüz ilaç kullanım verisi bulunmuyor.'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _adherenceReports.length,
      itemBuilder: (context, index) {
        final report = _adherenceReports[index];
        final adherencePercentage = (report.adherenceRate * 100).round();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: report.medication.color,
                      child: Text(
                        report.medication.name.substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.medication.name,
                            style: AppTextStyles.subtitle,
                          ),
                          if (report.medication.dosage != null)
                            Text(
                              report.medication.dosage!,
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: _getAdherenceColor(report.adherenceRate).withAlpha(26), // 0.1 * 255 = ~26
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getAdherenceColor(report.adherenceRate),
                        ),
                      ),
                      child: Text(
                        '%$adherencePercentage',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getAdherenceColor(report.adherenceRate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: report.adherenceRate,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAdherenceColor(report.adherenceRate),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Alınan',
                      report.takenDoses,
                      Colors.green,
                    ),
                    _buildStatColumn(
                      'Atlanmış',
                      report.skippedDoses,
                      Colors.red,
                    ),
                    _buildStatColumn(
                      'Gecikmiş',
                      report.delayedDoses,
                      Colors.orange,
                    ),
                    _buildStatColumn(
                      'Toplam',
                      report.totalDoses,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
  
  Widget _buildMedicationDetailsTab() {
    if (_medications.isEmpty) {
      return const Center(
        child: Text('Henüz ilaç kaydı bulunmuyor.'),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'İlaç Seçin',
              border: OutlineInputBorder(),
            ),
            value: _selectedMedicationId,
            items: _medications.map((medication) {
              return DropdownMenuItem<String>(
                value: medication.id,
                child: Text(medication.name),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedMedicationId = newValue;
                });
              }
            },
          ),
        ),
        if (_selectedMedicationId != null)
          Expanded(
            child: FutureBuilder<List<DailyAdherenceDetail>>(
              future: _reportService.getDailyAdherenceDetails(
                _selectedMedicationId!,
                startDate: _getStartDateForPeriod(),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }
                
                final details = snapshot.data ?? [];
                
                if (details.isEmpty) {
                  return const Center(
                    child: Text('Bu ilaç için kayıt bulunamadı.'),
                  );
                }
                
                return _buildDailyAdherenceChart(details);
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildDailyAdherenceChart(List<DailyAdherenceDetail> details) {
    // Tarih formatı
    final dateFormat = DateFormat('dd/MM');
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Günlük İlaç Uyum Grafiği',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final detail = details[groupIndex];
                          return BarTooltipItem(
                            '${dateFormat.format(detail.date)}\n${detail.takenDoses}/${detail.totalDoses}',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < details.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: 45 * 3.1415927 / 180,
                                  child: Text(
                                    dateFormat.format(details[index].date),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container();
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            String text = '';
                            if (value == 0) text = '0%';
                            else if (value == 0.5) text = '50%';
                            else if (value == 1) text = '100%';
                            
                            return Text(text, style: const TextStyle(fontSize: 10));
                          },
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: details.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detail = entry.value;
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: detail.adherenceRate,
                            color: _getAdherenceColor(detail.adherenceRate),
                            width: 15,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Renk açıklamaları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('İyi', Colors.green),
                  const SizedBox(width: 16),
                  _buildLegendItem('Orta', Colors.orange),
                  const SizedBox(width: 16),
                  _buildLegendItem('Düşük', Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
  
  // Uyum oranına göre renk döndür
  Color _getAdherenceColor(double adherenceRate) {
    if (adherenceRate >= 0.8) {
      return Colors.green;
    } else if (adherenceRate >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Rapor dönemi başlığını al
  String _getReportPeriodTitle() {
    final now = DateTime.now();
    final startDate = _getStartDateForPeriod();
    
    final startText = DateFormat('d MMMM').format(startDate);
    final endText = DateFormat('d MMMM yyyy').format(now);
    
    return '$startText - $endText Dönemi';
  }
    // Dönem başlangıç tarihini al
  DateTime _getStartDateForPeriod() {
    final now = DateTime.now();
    
    switch (_reportPeriod) {
      case ReportPeriod.week:
        return DateTime(now.year, now.month, now.day - 7);
      case ReportPeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
      case ReportPeriod.year:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }
  
  // Sağlık metrikleri sekmesi
  Widget _buildHealthMetricsTab() {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        if (userProfileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final userProfile = userProfileProvider.userProfile;
        if (userProfile == null || userProfile.height == null || userProfile.weight == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sağlık metrikleriniz görüntülenemedi',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Boy ve kilo bilgilerinizi profilinizden ekleyerek\nsağlık metriklerinizi görüntüleyebilirsiniz.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Profil sekmesine yönlendir (bottom tab'ı seç)
                    Navigator.of(context).pushNamed('/profile');
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('Profil Bilgilerimi Düzenle'),
                ),
              ],
            ),
          );
        }
        
        // Örnek ağırlık geçmişi - Gerçek uygulamada veritabanından çekilecek
        final now = DateTime.now();
        final List<Map<String, dynamic>> weightHistory = [
          {
            'date': now.subtract(const Duration(days: 30)),
            'weight': userProfile.weight! + 1.5
          },
          {
            'date': now.subtract(const Duration(days: 20)),
            'weight': userProfile.weight! + 0.8
          },
          {
            'date': now.subtract(const Duration(days: 10)),
            'weight': userProfile.weight! + 0.2
          },
          {
            'date': now,
            'weight': userProfile.weight!
          },
        ];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vücut Ölçümleri',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      Row(
                        children: [
                          _buildMetricCard(
                            icon: Icons.height,
                            title: 'Boy',
                            value: '${userProfile.height!.toStringAsFixed(0)} cm',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          _buildMetricCard(
                            icon: Icons.monitor_weight,
                            title: 'Kilo',
                            value: '${userProfile.weight!.toStringAsFixed(1)} kg',
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: AppDimens.paddingM),
                          _buildMetricCard(
                            icon: Icons.favorite,
                            title: 'VKİ',
                            value: userProfile.bmi!.toStringAsFixed(1),
                            color: _getBmiStatusColor(userProfile.bmi!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.paddingM),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: HealthMetricsChartWidget(
                    userProfile: userProfile,
                    weightHistory: weightHistory,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.paddingM),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sağlık Tavsiyeleri',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppDimens.paddingM),
                      _buildHealthAdvice(userProfile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              title,
              style: AppTextStyles.bodyTextSmall,
            ),
            const SizedBox(height: AppDimens.paddingXS),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthAdvice(UserProfile userProfile) {
    final bmi = userProfile.bmi;
    
    if (bmi == null) {
      return const Text('Boy ve kilo bilgilerinizi girerek kişiselleştirilmiş sağlık tavsiyelerine erişebilirsiniz.');
    }
    
    String advice;
    IconData icon;
    Color color;
    
    if (bmi < 18.5) {
      advice = 'Vücut kitle indeksiniz düşük seviyede. Sağlıklı kilo almak için dengeli beslenmeye özen göstermeniz ve protein açısından zengin gıdalar tüketmeniz önerilir.';
      icon = Icons.arrow_downward;
      color = Colors.blue;
    } else if (bmi < 25) {
      advice = 'Vücut kitle indeksiniz normal aralıkta. Mevcut sağlıklı yaşam tarzınızı sürdürün ve düzenli fiziksel aktivitenizi devam ettirin.';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (bmi < 30) {
      advice = 'Vücut kitle indeksiniz fazla kilolu aralığında. Dengeli beslenmeye dikkat edin ve düzenli egzersizle kilonuzu kontrol altında tutmaya çalışın.';
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      advice = 'Vücut kitle indeksiniz obezite aralığında. Doktor kontrolünde kilo vermeyi hedefleyin ve beslenme alışkanlıklarınızı gözden geçirin.';
      icon = Icons.error;
      color = Colors.red;
    }
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        _getBmiStatusText(bmi),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimens.paddingS),
        child: Text(advice),
      ),
      isThreeLine: true,
    );
  }
  
  String _getBmiStatusText(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }
  
  Color _getBmiStatusColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

enum ReportPeriod {
  week,
  month,
  year,
}