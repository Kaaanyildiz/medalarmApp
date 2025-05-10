import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/medications/screens/add_medication_screen.dart';
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
          // Edit icon kaldırıldı, düzenleme artık ilaç kartındaki düzenle butonu ile yapılacak
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
  }  Widget _buildMedicationHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: _currentMedication.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: _currentMedication.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _currentMedication.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _currentMedication.color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: _currentMedication.color,
              child: const Icon(
                Icons.medication,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentMedication.name,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppDimens.paddingXS),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingS,
                        vertical: AppDimens.paddingXS / 2,
                      ),
                      decoration: BoxDecoration(
                        color: _currentMedication.isActive
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      ),
                      child: Text(
                        _currentMedication.isActive ? 'Aktif' : 'Pasif',
                        style: AppTextStyles.captionBold.copyWith(
                          color: _currentMedication.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                    if (_currentMedication.dosage != null) ...[
                      const SizedBox(width: AppDimens.paddingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingS,
                          vertical: AppDimens.paddingXS / 2,
                        ),
                        decoration: BoxDecoration(
                          color: _currentMedication.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: Text(
                          _currentMedication.dosage!,
                          style: AppTextStyles.caption.copyWith(
                            color: _currentMedication.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
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
      elevation: 3,
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
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Kullanım Programı',
                  style: AppTextStyles.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),_buildInfoRow('Sıklık', _formatFrequency()),
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
              runSpacing: AppDimens.paddingS,
              children: _currentMedication.timesOfDay.map((time) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: _currentMedication.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(
                      color: _currentMedication.color.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time, 
                        size: 18, 
                        color: _currentMedication.color,
                      ),
                      const SizedBox(width: AppDimens.paddingXS),
                      Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.bodyTextBold.copyWith(
                          color: _currentMedication.color,
                        ),
                      ),
                    ],
                  ),
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
      elevation: 3,
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
              children: [
                const Icon(
                  Icons.inventory_2,
                  color: AppColors.secondary,
                  size: 24,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Stok Durumu',
                  style: AppTextStyles.heading3,
                ),
              ],
            ),            const SizedBox(height: AppDimens.paddingM),
            if (_currentMedication.currentStock != null) ...[
              _buildInfoRow(
                'Mevcut Stok',
                '${_currentMedication.currentStock} ${_currentMedication.stockUnit ?? 'adet'}',
              ),
              _buildInfoRow(
                'Uyarı Eşiği',
                '${_currentMedication.stockThreshold} ${_currentMedication.stockUnit ?? 'adet'}',
              ),
              if (_currentMedication.lastRefillDate != null)
                _buildInfoRow(
                  'Son Tedarik',
                  _formatDate(_currentMedication.lastRefillDate),
                ),
              if (_currentMedication.daysUntilEmpty != null) ...[
                _buildInfoRow(
                  'Kalan Süre',
                  '${_currentMedication.daysUntilEmpty} gün',
                ),
                // Kalan gün göstergesi ilerleme çubuğu
                const SizedBox(height: AppDimens.paddingS),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stok Durumu',
                            style: AppTextStyles.bodyTextSmall,
                          ),
                          Text(
                            _getStockStatusText(),
                            style: AppTextStyles.bodyTextSmallBold.copyWith(
                              color: _getStockStatusColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.paddingXS),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                        child: LinearProgressIndicator(
                          value: _calculateStockPercentage(),
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          color: _getStockStatusColor(),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stok takibi yapılmıyor',
                            style: AppTextStyles.bodyTextBold,
                          ),
                          const SizedBox(height: AppDimens.paddingXS),
                          Text(
                            'Stok takibi için ilaç düzenleme ekranından bilgileri ekleyebilirsiniz',
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
          ],
        ),
      ),
    );
  }  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
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
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _confirmDeleteMedication();
                },
                icon: const Icon(Icons.delete),
                label: const Text('Sil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
        // İlacı düzenle butonu
        const SizedBox(height: AppDimens.paddingM),
        if (_currentMedication.currentStock != null) 
          OutlinedButton.icon(
            onPressed: () {
              // Stok güncelleme fonksiyonu ileride eklenebilir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu özellik yakında eklenecektir'),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Stok Güncelle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingS),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyTextBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
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

  // Stok durumu rengini döndürür
  Color _getStockStatusColor() {
    if (_currentMedication.currentStock == null || _currentMedication.stockThreshold == null) {
      return AppColors.textSecondary;
    }
    
    if (_currentMedication.currentStock! <= 0) {
      return AppColors.error;
    } else if (_currentMedication.currentStock! <= _currentMedication.stockThreshold!) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }
  
  // Stok durumu metni
  String _getStockStatusText() {
    if (_currentMedication.currentStock == null || _currentMedication.stockThreshold == null) {
      return 'Belirtilmemiş';
    }
    
    if (_currentMedication.currentStock! <= 0) {
      return 'Stok tükendi';
    } else if (_currentMedication.currentStock! <= _currentMedication.stockThreshold!) {
      return 'Stok azalıyor';
    } else {
      return 'Stok yeterli';
    }
  }
  
  // Stok ilerleme çubuğu yüzdesi
  double _calculateStockPercentage() {
    if (_currentMedication.currentStock == null || 
        _currentMedication.stockThreshold == null || 
        _currentMedication.currentStock! <= 0) {
      return 0.0;
    }
    
    // Eşiğin 3 katı maksimum olarak düşünülür
    final maxStock = _currentMedication.stockThreshold! * 3;
    return (_currentMedication.currentStock! / maxStock).clamp(0.0, 1.0);
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