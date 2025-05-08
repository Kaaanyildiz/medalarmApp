// filepath: c:\Users\Msi\medalarm\lib\screens\reports_screen.dart
import 'package:flutter/material.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/models/medication.dart';
import 'package:medalarmm/providers/medication_provider.dart';
import 'package:medalarmm/services/report_service.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Kullanım Raporları'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel Bakış'),
            Tab(text: 'Uyum Raporları'),
            Tab(text: 'İlaç Detayları'),
          ],
        ),
        actions: [
          PopupMenuButton<ReportPeriod>(
            icon: const Icon(Icons.calendar_today),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAdherenceReportsTab(),
                _buildMedicationDetailsTab(),
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
        children: [
          // Dönem bilgisi
          Text(
            _getReportPeriodTitle(),
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),
          
          // Genel uyum kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel İlaç Uyum Oranı',
                    style: AppTextStyles.subtitle,
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
                  const SizedBox(height: 8),
                  Text(
                    '%${(overallAdherence * 100).round()}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAdherenceColor(overallAdherence),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toplam $totalTakenDoses / $totalPlannedDoses doz alındı',
                    style: AppTextStyles.caption,
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
          const Text(
            'Dikkat Edilmesi Gereken İlaçlar',
            style: AppTextStyles.subtitle,
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
        child: Column(
          children: [
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: AppTextStyles.headline.copyWith(
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
}

enum ReportPeriod {
  week,
  month,
  year,
}