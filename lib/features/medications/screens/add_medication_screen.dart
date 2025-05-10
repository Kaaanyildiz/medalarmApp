import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication; // Düzenleme için varolan ilaç

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _stockThresholdController = TextEditingController();
  final TextEditingController _stockUnitController = TextEditingController();
  final TextEditingController _durationDaysController = TextEditingController();
  
  bool _isEditing = false;
  String? _medicationId;
  String _selectedMedicationType = 'Hap';
  MedicationFrequency _frequency = MedicationFrequency.daily;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  int _timesPerDay = 1;
  int _dosesPerTime = 1;
  bool _remindRefill = true;
  bool _isActive = true;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  final List<DayOfWeek> _selectedDays = [];
  
  final List<String> _medicationTypes = [
    'Hap',
    'Şurup',
    'İğne',
    'Damla',
    'Sprey',
    'Merhem',
    'Krem',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    
    // Eğer düzenleme modundaysak
    if (widget.medication != null) {
      _isEditing = true;
      _populateFormWithExistingData();
    } else {
      // Varsayılan gün seçimleri (Her gün)
      for (var day in DayOfWeek.values) {
        _selectedDays.add(day);
      }
    }
  }
  
  void _populateFormWithExistingData() {
    final med = widget.medication!;
    
    _medicationId = med.id;
    _nameController.text = med.name;
    _dosageController.text = med.dosage ?? '';
    _instructionsController.text = med.instructions ?? '';
    _notesController.text = med.notes ?? '';
    
    _selectedMedicationType = med.medicationType ?? 'Hap';
    _frequency = med.frequency;
    _startDate = med.startDate ?? DateTime.now();
    _endDate = med.endDate;
    _hasEndDate = med.endDate != null;
    
    _currentStockController.text = med.currentStock?.toString() ?? '';
    _stockThresholdController.text = med.stockThreshold?.toString() ?? '5';
    _stockUnitController.text = med.stockUnit ?? 'tablet';
    _durationDaysController.text = med.durationDays?.toString() ?? '';
    
    _remindRefill = med.remindRefill;
    _timesPerDay = med.timesPerDay;
    _dosesPerTime = med.dosesPerTime;
    _isActive = med.isActive;
    
    // Saatlerin kopyasını oluştur
    _times.clear();
    if (med.timesOfDay.isNotEmpty) {
      _times.addAll(med.timesOfDay);
    } else {
      _times.add(const TimeOfDay(hour: 8, minute: 0));
    }
    
    // Günlerin kopyasını oluştur
    _selectedDays.clear();
    if (med.daysOfWeek.isNotEmpty) {
      _selectedDays.addAll(med.daysOfWeek);
    } else {
      // Varsayılan olarak tüm günleri seç
      _selectedDays.addAll(DayOfWeek.values);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _currentStockController.dispose();
    _stockThresholdController.dispose();
    _stockUnitController.dispose();
    _durationDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'İlaç Düzenle' : 'Yeni İlaç Ekle'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const Divider(height: AppDimens.paddingL),
              _buildScheduleInfo(),
              const Divider(height: AppDimens.paddingL),
              _buildStockInfo(),
              const Divider(height: AppDimens.paddingL),
              _buildAdditionalInfo(),
              const SizedBox(height: AppDimens.paddingL),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temel Bilgiler',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppDimens.paddingM),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'İlaç Adı *',
            hintText: 'Örn: Parol, Aspirin',
            prefixIcon: Icon(Icons.medication),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'İlaç adı zorunludur';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dozaj',
                  hintText: 'Örn: 500mg, 1 tablet',
                  prefixIcon: Icon(Icons.scale),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMedicationType,
                decoration: const InputDecoration(
                  labelText: 'İlaç Tipi',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _medicationTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMedicationType = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        TextFormField(
          controller: _instructionsController,
          decoration: const InputDecoration(
            labelText: 'Kullanım Talimatları',
            hintText: 'Örn: Yemeklerden sonra, aç karnına',
            prefixIcon: Icon(Icons.info_outline),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kullanım Programı',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppDimens.paddingM),
        // Kullanım sıklığı
        DropdownButtonFormField<MedicationFrequency>(
          value: _frequency,
          decoration: const InputDecoration(
            labelText: 'Kullanım Sıklığı',
            prefixIcon: Icon(Icons.repeat),
            border: OutlineInputBorder(),
          ),
          items: MedicationFrequency.values.map((freq) {
            String label = '';
            switch (freq) {
              case MedicationFrequency.daily:
                label = 'Her gün';
                break;
              case MedicationFrequency.specificDays:
                label = 'Belirli günler';
                break;
              case MedicationFrequency.asNeeded:
                label = 'Gerektiğinde';
                break;
              case MedicationFrequency.cyclical:
                label = 'Döngüsel';
                break;
            }
            return DropdownMenuItem<MedicationFrequency>(
              value: freq,
              child: Text(label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _frequency = value;
                // Sadece belirli günler seçildiğinde, default günleri boşalt
                if (value == MedicationFrequency.specificDays && _selectedDays.length == 7) {
                  _selectedDays.clear();
                }
              });
            }
          },
        ),
        const SizedBox(height: AppDimens.paddingM),
        
        // Belirli günler seçimi
        if (_frequency == MedicationFrequency.specificDays)
          _buildDaySelector(),
        
        const SizedBox(height: AppDimens.paddingM),
        
        // Kullanım süresi
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Başlangıç Tarihi'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null && picked != _startDate) {
                    setState(() {
                      _startDate = picked;
                      // Eğer bitiş tarihi başlangıçtan önce ise güncelle
                      if (_hasEndDate && _endDate != null && _endDate!.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 30));
                      }
                    });
                  }
                },
                leading: const Icon(Icons.calendar_today),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Bitiş Tarihi'),
                    value: _hasEndDate,
                    onChanged: (bool value) {
                      setState(() {
                        _hasEndDate = value;
                        if (value) {
                          _endDate = _startDate.add(const Duration(days: 30));
                        } else {
                          _endDate = null;
                        }
                      });
                    },
                  ),
                  if (_hasEndDate)
                    ListTile(
                      title: Text(
                        DateFormat('dd.MM.yyyy').format(_endDate ?? _startDate.add(const Duration(days: 30))),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                          firstDate: _startDate,
                          lastDate: _startDate.add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            _endDate = picked;
                          });
                        }
                      },
                      leading: const Icon(Icons.event),
                    ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppDimens.paddingM),
        
        // Kullanım süresi (gün)
        if (!_hasEndDate)
          TextFormField(
            controller: _durationDaysController,
            decoration: const InputDecoration(
              labelText: 'Kullanım Süresi (Gün)',
              hintText: 'Kaç gün kullanılacak',
              prefixIcon: Icon(Icons.hourglass_empty),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        
        const SizedBox(height: AppDimens.paddingM),
        
        // Günlük kullanım sayısı ve doz
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _timesPerDay,
                decoration: const InputDecoration(
                  labelText: 'Günde Kaç Kez',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (index) => index + 1).map((count) {
                  return DropdownMenuItem<int>(
                    value: count,
                    child: Text('$count kez'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _timesPerDay = value;
                      
                      // Saat listesini güncelle
                      if (_times.length > value) {
                        _times.removeRange(value, _times.length);
                      } else if (_times.length < value) {
                        // Saatleri dengeli dağıt
                        final int hoursInDay = 14; // 8:00 - 22:00 arası
                        final int intervalHours = hoursInDay ~/ value;
                        
                        for (int i = _times.length; i < value; i++) {
                          final int newHour = 8 + (i * intervalHours);
                          _times.add(TimeOfDay(hour: newHour, minute: 0));
                        }
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _dosesPerTime,
                decoration: const InputDecoration(
                  labelText: 'Her Seferde',
                  prefixIcon: Icon(Icons.line_weight),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (index) => index + 1).map((count) {
                  return DropdownMenuItem<int>(
                    value: count,
                    child: Text('$count doz'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _dosesPerTime = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppDimens.paddingM),
        
        // İlaç saatleri
        Text(
          'İlaç Saatleri',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppDimens.paddingS),
        Wrap(
          spacing: AppDimens.paddingS,
          children: List.generate(_times.length, (index) {
            return ActionChip(
              label: Text(
                '${_times[index].hour.toString().padLeft(2, '0')}:${_times[index].minute.toString().padLeft(2, '0')}',
              ),
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _times[index],
                );
                if (picked != null) {
                  setState(() {
                    _times[index] = picked;
                    // Saatleri sırala
                    _times.sort((a, b) {
                      final aMinutes = a.hour * 60 + a.minute;
                      final bMinutes = b.hour * 60 + b.minute;
                      return aMinutes.compareTo(bMinutes);
                    });
                  });
                }
              },
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hangi günler alınacak?',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppDimens.paddingS),
        Wrap(
          spacing: AppDimens.paddingS,
          children: DayOfWeek.values.map((day) {
            final bool isSelected = _selectedDays.contains(day);
            final String dayName = AppConstants.weekDaysMap[AppConstants.weekDays[day.index]] ?? AppConstants.weekDays[day.index];
            
            return FilterChip(
              label: Text(dayName),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stok Bilgileri',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _currentStockController,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Stok',
                  hintText: 'Kaç adet kaldı',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: TextFormField(
                controller: _stockUnitController,
                decoration: const InputDecoration(
                  labelText: 'Stok Birimi',
                  hintText: 'tablet, şişe, ampul',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingM),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockThresholdController,
                decoration: const InputDecoration(
                  labelText: 'Uyarı Eşiği',
                  hintText: 'Kaç adet kalınca uyarı',
                  prefixIcon: Icon(Icons.warning),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: SwitchListTile(
                title: const Text('Stok Hatırlatma'),
                value: _remindRefill,
                onChanged: (bool value) {
                  setState(() {
                    _remindRefill = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ek Bilgiler',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppDimens.paddingM),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notlar',
            hintText: 'İlaçla ilgili ek bilgiler',
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: AppDimens.paddingM),
        if (_isEditing)
          SwitchListTile(
            title: const Text('İlaç Aktif'),
            subtitle: const Text('İlaç hatırlatmaları aktif mi?'),
            value: _isActive,
            onChanged: (bool value) {
              setState(() {
                _isActive = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveMedication,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: Text(
          _isEditing ? 'İlacı Güncelle' : 'İlacı Kaydet',
          style: AppTextStyles.button,
        ),
      ),
    );
  }

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      
      // Spesifik günler için, en az bir gün seçilmiş olmalı
      if (_frequency == MedicationFrequency.specificDays && _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen en az bir gün seçin')),
        );
        return;
      }
      
      // Kullanım süresi değerini al
      int? durationDays;
      if (!_hasEndDate && _durationDaysController.text.isNotEmpty) {
        durationDays = int.tryParse(_durationDaysController.text);
      }
      
      // Stok bilgilerini al
      int? currentStock, stockThreshold;
      if (_currentStockController.text.isNotEmpty) {
        currentStock = int.tryParse(_currentStockController.text);
      }
      if (_stockThresholdController.text.isNotEmpty) {
        stockThreshold = int.tryParse(_stockThresholdController.text);
      }
      
      // Medication nesnesi oluştur
      final medication = Medication(
        id: _isEditing ? _medicationId : null,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim().isNotEmpty ? _dosageController.text.trim() : null,
        instructions: _instructionsController.text.trim().isNotEmpty ? _instructionsController.text.trim() : null,
        medicationType: _selectedMedicationType,
        frequency: _frequency,
        timesOfDay: _times,
        daysOfWeek: _selectedDays,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        durationDays: durationDays,
        currentStock: currentStock,
        stockThreshold: stockThreshold,
        stockUnit: _stockUnitController.text.trim().isNotEmpty ? _stockUnitController.text.trim() : 'tablet',
        remindRefill: _remindRefill,
        timesPerDay: _timesPerDay,
        dosesPerTime: _dosesPerTime,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        isActive: _isActive,
      );
      
      // Veritabanına kaydet
      if (_isEditing) {
        medicationProvider.updateMedication(medication).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlaç güncellendi')),
          );
          Navigator.pop(context, true);
        });
      } else {
        medicationProvider.addMedication(medication).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlaç eklendi')),
          );
          Navigator.pop(context, true);
        });
      }
    }
  }
}