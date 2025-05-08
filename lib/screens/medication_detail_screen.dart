import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/models/medication.dart';
import 'package:medalarmm/providers/medication_provider.dart';
import 'package:medalarmm/screens/add_medication_screen.dart';
import 'package:provider/provider.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  // Güncel ilacı saklamak için bir değişken
  late Medication _currentMedication;

  @override
  void initState() {
    super.initState();
    _currentMedication = widget.medication;
  }

  // İlaç verilerini yenile
  Future<void> _refreshMedication() async {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    try {
      // İlaçları yeniden yükle
      await provider.loadMedications();
      
      // Güncel ilaç verisini bul
      final updatedMed = await provider.getMedicationById(_currentMedication.id);
      
      if (updatedMed != null && mounted) {
        setState(() {
          _currentMedication = updatedMed;
        });
      }
    } catch (e) {
      print('İlaç verileri yüklenirken hata: $e');
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Detayları'),
        actions: [          
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // İlaç düzenleme ekranına git
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMedicationScreen(medication: widget.medication),
                ),              ).then((value) {
                // Eğer değişiklik yapıldıysa, sayfayı yeniden yükle
                if (value == true) {
                  _refreshMedication();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedicationHeader(),
            const SizedBox(height: AppDimens.paddingL),
            _buildInfoCard(),
            const SizedBox(height: AppDimens.paddingM),
            _buildScheduleCard(),
            const SizedBox(height: AppDimens.paddingM),
            _buildStockCard(),
            const SizedBox(height: AppDimens.paddingM),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  Widget _buildMedicationHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: _currentMedication.color.withOpacity(0.2),
          child: Icon(
            Icons.medication,
            color: _currentMedication.color,
            size: 32,
          ),
        ),
        const SizedBox(width: AppDimens.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              Text(
                _currentMedication.name,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppDimens.paddingXS),
              Text(
                _currentMedication.isActive ? 'Aktif' : 'Pasif',
                style: AppTextStyles.bodyText.copyWith(
                  color: _currentMedication.isActive
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İlaç Bilgileri',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppDimens.paddingM),            _buildInfoRow('Dozaj', _currentMedication.dosage ?? 'Belirtilmemiş'),
            _buildInfoRow('Talimatlar', _currentMedication.instructions ?? 'Belirtilmemiş'),
            _buildInfoRow('Tipi', _currentMedication.medicationType ?? 'Belirtilmemiş'),
            if (_currentMedication.notes?.isNotEmpty ?? false)
              _buildInfoRow('Notlar', _currentMedication.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kullanım Programı',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppDimens.paddingM),            _buildInfoRow('Sıklık', _formatFrequency()),
            _buildInfoRow('Günde', '${_currentMedication.timesPerDay} kez'),
            _buildInfoRow('Başlangıç', _formatDate(_currentMedication.startDate)),
            if (_currentMedication.endDate != null)
              _buildInfoRow('Bitiş', _formatDate(_currentMedication.endDate)),
            if (_currentMedication.durationDays != null)
              _buildInfoRow('Süre', '${_currentMedication.durationDays} gün'),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Alma Zamanları:',
              style: AppTextStyles.bodyTextBold,
            ),
            const SizedBox(height: AppDimens.paddingS),            Wrap(
              spacing: AppDimens.paddingS,
              children: _currentMedication.timesOfDay.map((time) {
                return Chip(
                  label: Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyTextSmall,
                  ),
                  backgroundColor: AppColors.background,
                  avatar: const Icon(Icons.access_time, size: 16),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stok Durumu',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppDimens.paddingM),            if (_currentMedication.currentStock != null) ...[
              _buildInfoRow(
                'Mevcut Stok',
                '${_currentMedication.currentStock} ${_currentMedication.stockUnit ?? 'adet'}',
              ),
              _buildInfoRow(
                'Uyarı Eşiği',
                '${_currentMedication.stockThreshold} ${_currentMedication.stockUnit ?? 'adet'}',
              ),              if (_currentMedication.lastRefillDate != null)
                _buildInfoRow(
                  'Son Tedarik',
                  _formatDate(_currentMedication.lastRefillDate),
                ),
              if (_currentMedication.daysUntilEmpty != null)
                _buildInfoRow(
                  'Kalan Süre',
                  '${_currentMedication.daysUntilEmpty} gün',
                ),
            ] else
              const Text(
                'Stok takibi yapılmıyor',
                style: AppTextStyles.bodyText,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _toggleMedicationStatus();
          },
          icon: Icon(
            widget.medication.isActive ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            widget.medication.isActive ? 'Pasife Al' : 'Aktifleştir',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.medication.isActive ? AppColors.warning : AppColors.success,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _confirmDeleteMedication();
          },
          icon: const Icon(Icons.delete),
          label: const Text('Sil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyTextBold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText,
            ),
          ),
        ],
      ),
    );
  }
  String _formatFrequency() {
    switch (widget.medication.frequency) {
      case MedicationFrequency.daily:
        return 'Her gün';
      case MedicationFrequency.specificDays:
        return 'Belirli günler';
      case MedicationFrequency.asNeeded:
        return 'Gerektiğinde';
      case MedicationFrequency.cyclical:
        return 'Döngüsel';
    }
  }String _formatDate(DateTime? date) {
    if (date == null) return 'Belirtilmemiş';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  void _toggleMedicationStatus() {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    
    final updatedMedication = widget.medication.copyWith(
      isActive: !widget.medication.isActive,
    );
    
    provider.updateMedication(updatedMedication).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.medication.isActive ? 'İlaç pasife alındı' : 'İlaç aktifleştirildi',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    });
  }

  void _confirmDeleteMedication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlacı Sil'),
        content: const Text(
          'Bu ilaç ve tüm kayıtları silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              _deleteMedication();
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMedication() {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    
    provider.deleteMedication(widget.medication.id).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlaç silindi'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    });
  }
}