import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/models/medication_log.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/common/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<MedicationLog> _selectedDayLogs = [];
  bool _isLoading = false;
  
  // Tüm takvim günleri için ilaç logları
  Map<DateTime, List<MedicationLog>> _events = {};
  
  // İlaç - renk eşleştirmeleri
  Map<String, Color> _medicationColors = {};
  
  @override
  void initState() {
    super.initState();
    _loadLogsForCalendar();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Yerelleştirme verilerini başlat
    final locale = Localizations.localeOf(context).languageCode;
    final localeCode = locale == 'en' ? 'en_US' : 'tr_TR';
    initializeDateFormatting(localeCode, null);
  }
  
  // Takvim için tüm logları yükle
  Future<void> _loadLogsForCalendar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      
      // Son 3 ay ve gelecek 3 ay için ilaç loglarını oluştur
      final now = DateTime.now();
      
      // Mevcut ay için logları oluştur
      await provider.generateMedicationLogsForDate(now);
      
      // Gelecekteki 7 gün için logları oluştur
      for (int i = 1; i <= 7; i++) {
        final futureDate = now.add(Duration(days: i));
        await provider.generateMedicationLogsForDate(futureDate);
      }
      
      // Son 3 ay ve gelecek 3 ay için ilaç loglarını yükle
      final startDate = DateTime(now.year, now.month - 3, 1);
      final endDate = DateTime(now.year, now.month + 3, 31);
      
      final logs = await provider.loadMedicationLogsByDateRange(
        startDate: startDate, 
        endDate: endDate
      );
      
      // Günlere göre logları ayır
      final Map<DateTime, List<MedicationLog>> events = {};
      
      for (final log in logs) {
        final day = DateTime(
          log.scheduledTime.year,
          log.scheduledTime.month,
          log.scheduledTime.day,
        );
        
        if (!events.containsKey(day)) {
          events[day] = [];
        }
        
        events[day]!.add(log);
      }
      
      // İlaçların renklerini al
      final medications = await provider.loadMedications();
      final Map<String, Color> medicationColors = {};
      
      for (final medication in medications) {
        medicationColors[medication.id] = medication.color;
      }
      
      // Seçili gün için logları yükle
      final selectedDayLogs = await provider.loadMedicationLogsByDate(
        date: _selectedDay
      );
      
      if (mounted) {
        setState(() {
          _events = events;
          _medicationColors = medicationColors;
          _selectedDayLogs = selectedDayLogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading calendar data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadLogsForSelectedDay() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      final logs = await provider.loadMedicationLogsByDate(
        date: _selectedDay
      );

      if (mounted) {
        setState(() {
          _selectedDayLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading selected day data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('calendar')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogsForCalendar,
            tooltip: loc.translate('refresh'),
          ),
        ],
      ),
      body: _isLoading && _events.isEmpty
          ? Center(
              child: LoadingIndicator(
                message: loc.translate('loading') + '...',
              ),
            )
          : Column(
              children: [
                // Takvim bölümü
                Container(
                  margin: const EdgeInsets.all(AppDimens.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildCalendar(),
                ),
                const Divider(thickness: 1, height: 1),
                // Günlük çizelge başlığı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM, 
                    vertical: AppDimens.paddingM
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: AppDimens.paddingS),
                      Text(
                        loc.translate('daily_medication_schedule'),
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Günlük çizelge içeriği
                Expanded(
                  child: _buildDailySchedule(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        // Seçilen gün için ilaç kayıtlarını yükle
        _loadLogsForSelectedDay();
      },
      onPageChanged: (focusedDay) {
        // Sayfa değiştiğinde, ilgili ayın loglarını oluştur
        _focusedDay = focusedDay;
        
        // Ayın ilk günü ve son günü
        final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
        final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
        
        // Ay içindeki ilk ve son gün için otomatik ilaç kayıtları oluştur
        Provider.of<MedicationProvider>(context, listen: false)
            .generateMedicationLogsForDate(firstDay);
        Provider.of<MedicationProvider>(context, listen: false)
            .generateMedicationLogsForDate(lastDay);
      },
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: AppTextStyles.heading3,
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withAlpha(76), // 0.3 * 255 = 76
          shape: BoxShape.circle,
        ),
        markersMaxCount: 4,
        markerSize: 8,
        markerDecoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          
          final day = DateTime(date.year, date.month, date.day);
          final dayLogs = _events[day] ?? [];
          
          if (dayLogs.isEmpty) return const SizedBox.shrink();
          
          // İlaçlara göre logları grupla
          final Map<String, List<MedicationLog>> medicationLogs = {};
          for (final log in dayLogs) {
            if (!medicationLogs.containsKey(log.medicationId)) {
              medicationLogs[log.medicationId] = [];
            }
            medicationLogs[log.medicationId]!.add(log);
          }
          
          // Her ilaç için bir marker göster (maksimum 4)
          final markers = <Widget>[];
          int count = 0;
          
          medicationLogs.forEach((medicationId, logs) {
            if (count >= 4) return;
            
            // Tüm dozlar alındı mı?
            final allTaken = logs.every((log) => log.isTaken);
            // Bazı dozlar alındı mı?
            final someTaken = logs.any((log) => log.isTaken);
            // Hiç alınmadı mı?
            final noneTaken = logs.every((log) => !log.isTaken);
            
            // İlaç rengi
            final Color medicationColor = _medicationColors[medicationId] ?? AppColors.primary;
            
            // Duruma göre renk ve ikon
            Color markerColor;
            if (allTaken) {
              markerColor = Colors.green;
            } else if (someTaken) {
              markerColor = Colors.orange;
            } else if (DateTime.now().isAfter(day) && noneTaken) {
              markerColor = Colors.red;
            } else {
              markerColor = medicationColor;
            }
            
            markers.add(
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: markerColor,
                ),
              ),
            );
            count++;
          });
            
          // Positioned widget'ı bir Stack içinde olmalı ve Stack'e boyut verilmeli
          return SizedBox(
            height: 20, // Marker'lar için yeterli yükseklik
            child: Stack(
              clipBehavior: Clip.none, // Taşma durumlarında çizim yapılmasına izin ver
              children: [
                Positioned(
                  bottom: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: markers,
                  ),
                ),
              ],
            ),
          );
        },
        dowBuilder: (context, day) {
          // Yerelleştirme hatalarını önlemek için try/catch kullanıyoruz
          String text;
          try {
            final locale = Localizations.localeOf(context).languageCode;
            final localeCode = locale == 'en' ? 'en_US' : 'tr_TR';
            text = DateFormat.E(localeCode).format(day);
          } catch (e) {
            // Yerelleştirme verisi yüklenemezse, varsayılan formatı kullan
            text = DateFormat.E().format(day);
          }
          
          return Center(
            child: Text(
              text.substring(0, text.length >= 3 ? 3 : text.length),
              style: TextStyle(
                color: day.weekday == DateTime.sunday ? Colors.red : null,
              ),
            ),
          );
        },
      ),
      eventLoader: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);
        final list = _events[normalizedDay];
        return list ?? [];
      },
    );
  }
  
  Widget _buildDailySchedule() {
    final loc = AppLocalizations.of(context);
    
    // Yerelleştirme ile ilgili hataları önlemek için try/catch kullanıyoruz
    DateFormat dateFormat;
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final localeCode = locale == 'en' ? 'en_US' : 'tr_TR';
      dateFormat = DateFormat('d MMMM yyyy EEEE', localeCode);
    } catch (e) {
      // Yerelleştirme verisi yüklenemezse, varsayılan yerelleştirmeyi kullan
      dateFormat = DateFormat('d MMMM yyyy EEEE');
    }
    
    final timeFormat = DateFormat('HH:mm');
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih başlığı ve ilaç sayısı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateFormat.format(_selectedDay),
                    style: AppTextStyles.heading2,
                  ),
                ),
                if (_selectedDayLogs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM,
                      vertical: AppDimens.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    ),
                    child: Text(
                      loc.translate('medication_count').replaceFirst('{count}', _selectedDayLogs.length.toString()),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            // İlaç listesi - Expanded widget kullanımı düzeltildi
            Flexible(
              fit: FlexFit.tight,
              child: _isLoading
                      ? LoadingIndicator(
                      message: loc.translate('loading_medication_info'),
                    )
                  : _selectedDayLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppDimens.paddingM),
                              Text(
                                loc.translate('no_medication_planned'),
                                style: AppTextStyles.bodyText.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppDimens.paddingL),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Seçili gün için ilaç kaydı oluşturmak için gerekli yönlendirme
                                  Navigator.pushNamed(context, '/medications/add');
                                },
                                icon: const Icon(Icons.add),
                                label: Text(loc.translate('add_new_medication')),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _selectedDayLogs.length,
                          itemBuilder: (context, index) {
                            final log = _selectedDayLogs[index];
                            return FutureBuilder<Medication?>(
                              future: Provider.of<MedicationProvider>(context, listen: false)
                                  .getMedicationById(log.medicationId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(AppDimens.paddingM),
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  );
                                }
                                
                                final medication = snapshot.data;
                                final medicationName = medication?.name ?? loc.translate('unknown_medication');
                                final medicationDosage = medication?.dosage ?? '';
                                final medicationColor = medication?.color ?? AppColors.primary;
                                
                                // İlacın durumu
                                Color statusColor;
                                IconData statusIcon;
                                String statusText;
                                
                                if (log.isTaken) {
                                  statusColor = AppColors.success;
                                  statusIcon = Icons.check_circle;
                                  statusText = loc.translate('status_taken');
                                } else if (log.isSkipped) {
                                  statusColor = AppColors.warning;
                                  statusIcon = Icons.cancel_outlined;
                                  statusText = loc.translate('status_skipped');
                                } else if (DateTime.now().isAfter(log.scheduledTime)) {
                                  statusColor = AppColors.error;
                                  statusIcon = Icons.error_outline;
                                  statusText = loc.translate('status_missed');
                                } else {
                                  statusColor = AppColors.primary;
                                  statusIcon = Icons.schedule;
                                  statusText = loc.translate('status_waiting');
                                }
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                    side: BorderSide(
                                      color: medicationColor.withAlpha(76), // 0.3 * 255 = 76
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppDimens.paddingM),
                                    child: Row(
                                      children: [
                                        // İlaç durumu ikonu
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: medicationColor.withAlpha(26), // 0.1 * 255 = 26
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              statusIcon,
                                              color: statusColor,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppDimens.paddingM),
                                        // İlaç bilgileri
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      medicationName,
                                                      style: AppTextStyles.heading3,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: AppDimens.paddingS,
                                                      vertical: AppDimens.paddingXS,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withAlpha(26), // 0.1 * 255 = 26
                                                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: AppDimens.paddingXS),
                                              if (medicationDosage.isNotEmpty)
                                                Text(
                                                  medicationDosage,
                                                  style: AppTextStyles.bodyText,
                                                ),
                                              const SizedBox(height: AppDimens.paddingXS),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: AppDimens.iconSizeS,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: AppDimens.paddingXS),
                                                  Text(
                                                    '${loc.translate('scheduled')}: ${timeFormat.format(log.scheduledTime)}',
                                                    style: AppTextStyles.bodyTextSmall,
                                                  ),
                                                ],
                                              ),
                                              if (log.isTaken && log.takenTime != null) ...[
                                                const SizedBox(height: AppDimens.paddingXS),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle_outline,
                                                      size: AppDimens.iconSizeS,
                                                      color: AppColors.success,
                                                    ),
                                                    const SizedBox(width: AppDimens.paddingXS),
                                                    Text(
                                                      '${loc.translate('taken')}: ${timeFormat.format(log.takenTime!)}',
                                                      style: AppTextStyles.bodyTextSmall.copyWith(
                                                        color: AppColors.success,
                                                      ),
                                                    ),
                                                    if (log.delayInMinutes != null && log.delayInMinutes! > 0) ...[
                                                      const SizedBox(width: AppDimens.paddingS),
                                                      Text(
                                                        '(${log.delayInMinutes} ${loc.translate('minute_abbreviation')} ${loc.translate('delay')})',
                                                        style: AppTextStyles.bodyTextSmall.copyWith(
                                                          color: log.delayInMinutes! > 30 
                                                              ? AppColors.error 
                                                              : AppColors.warning,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                              if (log.isSkipped && log.notes != null) ...[
                                                const SizedBox(height: AppDimens.paddingXS),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.note,
                                                      size: AppDimens.iconSizeS,
                                                      color: AppColors.warning,
                                                    ),
                                                    const SizedBox(width: AppDimens.paddingXS),
                                                    Expanded(
                                                      child: Text(
                                                        '${loc.translate('note')}: ${log.notes}',
                                                        style: AppTextStyles.bodyTextSmall.copyWith(
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (!log.isTaken && !log.isSkipped) ...[
                                          Column(
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _markAsTaken(log),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.success,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: AppDimens.paddingM,
                                                    vertical: AppDimens.paddingS,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.check, size: 16),
                                                label: Text(loc.translate('take')),
                                              ),
                                              const SizedBox(height: AppDimens.paddingXS),
                                              TextButton.icon(
                                                onPressed: () => _showSkipDialog(log),
                                                icon: const Icon(Icons.remove_circle_outline, size: 16),
                                                label: Text(loc.translate('skip')),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _markAsTaken(MedicationLog log) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      final loc = AppLocalizations.of(context);
      
      await provider.markMedicationAsTaken(
        medicationId: log.medicationId, 
        scheduledTime: log.scheduledTime
      );
      
      // Kullanıcıya bilgilendirme göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(loc.translate('medication_marked_as_taken')),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Takvimi ve seçili günü yenile
      await _loadLogsForCalendar();
    } catch (e) {
      print('Error marking medication as taken: $e');
      
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('error')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showSkipDialog(MedicationLog log) async {
    final TextEditingController noteController = TextEditingController();
    final loc = AppLocalizations.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('skip_medication')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.translate('skip_confirmation')),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: loc.translate('optional_note'),
                hintText: loc.translate('skip_reason_hint'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text(loc.translate('skip')),
          ),
        ],
      ),
    );
    
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final provider = Provider.of<MedicationProvider>(context, listen: false);
        await provider.markMedicationAsSkipped(
          medicationId: log.medicationId, 
          scheduledTime: log.scheduledTime,
          notes: noteController.text.isNotEmpty ? noteController.text : null,
        );
        
        // Kullanıcıya bilgilendirme göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('medication_marked_as_skipped')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        
        // Takvimi ve seçili günü yenile
        await _loadLogsForCalendar();
      } catch (e) {
        print('Error marking medication as skipped: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.translate('error')}: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
