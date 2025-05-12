// filepath: c:\Users\Msi\medalarm\lib\screens\inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/common/widgets/empty_state.dart';
import 'package:medalarmm/common/widgets/loading_indicator.dart';
import 'package:medalarmm/features/medications/widgets/stock_update_dialog.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedications();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
    Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // İlaçları provider üzerinden yükle
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      await provider.loadMedications();
    } catch (e) {
      print('Error loading medications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }@override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          loc.translate('medication_inventory'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _loadMedications,
            tooltip: loc.translate('refresh'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: AppTextStyles.bodyTextBold.copyWith(
            fontSize: 14,
          ),
          unselectedLabelStyle: AppTextStyles.bodyText.copyWith(
            fontSize: 14,
          ),
          tabs: [
            Tab(
              text: loc.translate('all_medications'),
              icon: const Icon(Icons.medication_rounded),
            ),
            Tab(
              text: loc.translate('low_stock'),
              icon: const Icon(Icons.warning_amber_rounded),
            ),
            Tab(
              text: loc.translate('out_of_stock'),
              icon: const Icon(Icons.error_outline),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Consumer<MedicationProvider>(
              builder: (context, provider, child) {
                final medications = provider.medications;
                  if (medications.isEmpty) {
                  return EmptyState(
                    icon: Icons.medication_outlined,
                    title: loc.translate('no_medications_added'),
                    message: loc.translate('add_medications_prompt'),
                  );
                }
                
                // İlaçları filtrele
                final lowStockMedications = medications
                    .where((med) => 
                        med.currentStock != null && 
                        med.stockThreshold != null && 
                        med.currentStock! <= med.stockThreshold! &&
                        med.currentStock! > 0)
                    .toList();
                
                final outOfStockMedications = medications
                    .where((med) => 
                        med.currentStock != null && 
                        med.currentStock! <= 0)
                    .toList();
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tüm İlaçlar sekmesi
                    _buildMedicationList(medications),
                      // Az Kalan sekmesi
                    lowStockMedications.isEmpty
                        ? EmptyState(
                            icon: Icons.check_circle_outline,
                            title: loc.translate('stock_status_good'),
                            message: loc.translate('no_low_stock'),
                          )
                        : _buildMedicationList(lowStockMedications),
                      // Biten sekmesi
                    outOfStockMedications.isEmpty
                        ? EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: loc.translate('stock_complete'),
                            message: loc.translate('no_out_of_stock'),
                          )
                        : _buildMedicationList(outOfStockMedications),
                  ],
                );
              },
      ),      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUpdateStockDialog,
        tooltip: loc.translate('update_stock'),
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(loc.translate('update_stock')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
    );
  }    Widget _buildMedicationList(List<Medication> medications) {
    final loc = AppLocalizations.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingL,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: medications.length + 1, // +1 for header
      itemBuilder: (context, index) {
        // Header kısmı
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: AppDimens.paddingM,
            ),
            child: Row(
              children: [                Text(
                  loc.translate('medications_count').replaceAll('{count}', medications.length.toString()),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort,
                        size: AppDimens.iconSizeS,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimens.paddingS),                      Text(
                        loc.translate('sort_by'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // İlaç kartları
        final medication = medications[index - 1]; // -1 because of header
        return _buildMedicationStockCard(medication);
      },
    );
  }
    Widget _buildMedicationStockCard(Medication medication) {
    // Stok durumunu belirle
    bool hasStock = medication.currentStock != null;
    int stock = medication.currentStock ?? 0;
    int? daysLeft = medication.daysUntilEmpty;
    
    // Stok rengi
    Color stockColor;
    IconData stockIcon;
    if (!hasStock) {
      stockColor = Colors.grey;
      stockIcon = Icons.help_outline;
    } else if (stock <= 0) {
      stockColor = AppColors.error;
      stockIcon = Icons.error_outline;
    } else if (medication.stockThreshold != null && stock <= medication.stockThreshold!) {
      stockColor = AppColors.warning;
      stockIcon = Icons.warning_amber_rounded;
    } else {
      stockColor = AppColors.success;
      stockIcon = Icons.check_circle_outline;
    }
      // Stok metni
    String stockText;
    final loc = AppLocalizations.of(context);
    if (!hasStock) {
      stockText = loc.translate('no_stock_info');
    } else if (stock <= 0) {
      stockText = loc.translate('stock_depleted');
    } else {
      stockText = '$stock ${medication.stockUnit ?? loc.translate('units')} ${loc.translate('remaining')}';
      if (daysLeft != null) {
        stockText += ' (${loc.translate('approx')} $daysLeft ${loc.translate('days')})';
      }
    }
      // Son yenileme tarihi
    String lastRefillText = loc.translate('no_last_refill');
    if (medication.lastRefillDate != null) {
      // Yerelleştirmeyi kullanıcı diline göre ayarla
      final locale = Localizations.localeOf(context).languageCode;
      final localeCode = locale == 'en' ? 'en_US' : 'tr_TR';
      final dateFormat = DateFormat('dd/MM/yyyy', localeCode);
      lastRefillText = '${loc.translate('last_refill')}: ${dateFormat.format(medication.lastRefillDate!)}';
    }
    
    // İlaç alım zamanı formatı
    final dosageText = '${loc.translate('times_per_day_format')
        .replaceAll('{times}', (medication.timesPerDay ?? 0).toString())
        .replaceAll('{doses}', (medication.dosesPerTime ?? 1).toString())}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      elevation: 4,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      child: InkWell(
        onTap: () => _showUpdateStockDialog(medication: medication),
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısmı - başlık ve renk şeridi
            Container(
              decoration: BoxDecoration(
                color: medication.color.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.radiusL),
                  topRight: Radius.circular(AppDimens.radiusL),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // İlaç ikonu
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: medication.color,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: medication.color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          hasStock && stock <= 0
                              ? Icons.warning_amber_rounded
                              : Icons.medication_rounded,
                          color: Colors.white,
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
                          Text(
                            medication.name,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (medication.dosage?.isNotEmpty ?? false) ...[
                            const SizedBox(height: AppDimens.paddingXS),
                            Text(
                              medication.dosage ?? '',
                              style: AppTextStyles.bodyText.copyWith(
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
            
            // Orta kısım - içerik
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.paddingM,
                AppDimens.paddingM,
                AppDimens.paddingM,
                AppDimens.paddingM / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stok detayları
                  Row(
                    children: [
                      // Stok durum ikonu
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          stockIcon,
                          color: stockColor,
                          size: AppDimens.iconSizeM,
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      
                      // Stok durum metni
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stockText,
                              style: AppTextStyles.bodyTextBold.copyWith(
                                color: stockColor,
                              ),
                            ),
                            const SizedBox(height: AppDimens.paddingXS / 2),
                            Text(
                              lastRefillText,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // İlerleme çubuğu
                  if (hasStock && medication.stockThreshold != null && medication.stockThreshold! > 0) ...[
                    const SizedBox(height: AppDimens.paddingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stok Durumu',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              stock > 0 
                                  ? '${(stock / medication.stockThreshold! * 100).round()}%'
                                  : '0%',
                              style: AppTextStyles.caption.copyWith(
                                color: stockColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.paddingXS),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                          child: LinearProgressIndicator(
                            value: stock > 0 
                                ? (stock / (medication.stockThreshold! * 3)).clamp(0.0, 1.0) 
                                : 0.0,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Alt kısım - kullanım bilgisi
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimens.radiusL),
                  bottomRight: Radius.circular(AppDimens.radiusL),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingM,
                vertical: AppDimens.paddingS,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppDimens.iconSizeS,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Text(
                      dosageText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (medication.notes != null && medication.notes!.isNotEmpty)
                    Tooltip(
                      message: medication.notes!,
                      child: const Icon(
                        Icons.info_outline,
                        size: AppDimens.iconSizeS,
                        color: AppColors.textLight,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
    Future<void> _showUpdateStockDialog({Medication? medication}) async {
    if (medication == null) {
      // Eğer belirli bir ilaç seçilmediyse, ilaç seçme ekranı göster
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      final medications = provider.medications;
      
      if (medications.isEmpty) {
        // Eğer ilaç yoksa, kullanıcıyı ilaç eklemeye yönlendir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok güncellemesi için önce ilaç eklemelisiniz.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // İlaç seçme diyaloğu göster
      final selected = await showDialog<Medication>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingM),
                      Text(
                        'İlaç Seçin',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: AppDimens.paddingS),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                          onTap: () => Navigator.of(context).pop(med),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingS),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: med.color,
                                child: const Icon(
                                  Icons.medication,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                med.name,
                                style: AppTextStyles.bodyTextBold,
                              ),
                              subtitle: med.dosage != null && med.dosage!.isNotEmpty 
                                  ? Text(
                                      med.dosage!,
                                      style: AppTextStyles.caption,
                                    ) 
                                  : null,
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: AppDimens.iconSizeS,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingL,
                        vertical: AppDimens.paddingM,
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      if (selected == null) return;
      medication = selected;
    }
      // Yeni stok güncelleme diyaloğunu kullan
    await showDialog<bool>(
      context: context,
      builder: (context) => StockUpdateDialog(
        medication: medication!,
        onUpdate: (newStock, isAddition) async {
          // Stok güncelleme
          final provider = Provider.of<MedicationProvider>(context, listen: false);
          
          final updatedMedication = medication!.copyWith(
            currentStock: newStock,
            lastRefillDate: isAddition ? DateTime.now() : medication.lastRefillDate,
          );
          
          await provider.updateMedication(updatedMedication);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medication.name} stok durumu güncellendi.'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}