// filepath: c:\Users\Msi\medalarm\lib\screens\inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/models/medication.dart';
import 'package:medalarmm/providers/medication_provider.dart';
import 'package:medalarmm/widgets/empty_state.dart';
import 'package:medalarmm/widgets/loading_indicator.dart';
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
      print('İlaçlar yüklenirken hata: $e');
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
        title: const Text('İlaç Stok Takibi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tüm İlaçlar'),
            Tab(text: 'Az Kalan'),
            Tab(text: 'Biten'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Consumer<MedicationProvider>(
              builder: (context, provider, child) {
                final medications = provider.medications;
                
                if (medications.isEmpty) {
                  return const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Henüz İlaç Eklenmemiş',
                    message: 'Stok takibi için ilaçlarınızı ekleyin.',
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
                        ? const EmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Stok Durumu İyi',
                            message: 'Şu anda stok seviyesi düşük olan ilaç bulunmuyor.',
                          )
                        : _buildMedicationList(lowStockMedications),
                    
                    // Biten sekmesi
                    outOfStockMedications.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'Stok Tamam',
                            message: 'Şu anda stoku biten ilaç bulunmuyor.',
                          )
                        : _buildMedicationList(outOfStockMedications),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUpdateStockDialog,
        tooltip: 'İlaç Stoku Güncelle',
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
  
  Widget _buildMedicationList(List<Medication> medications) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
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
    if (!hasStock) {
      stockColor = Colors.grey;
    } else if (stock <= 0) {
      stockColor = Colors.red;
    } else if (medication.stockThreshold != null && stock <= medication.stockThreshold!) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }
    
    // Stok metni
    String stockText;
    if (!hasStock) {
      stockText = 'Stok bilgisi yok';
    } else if (stock <= 0) {
      stockText = 'Stok tükendi!';
    } else {
      stockText = '$stock ${medication.stockUnit ?? 'adet'} kaldı';
      if (daysLeft != null) {
        stockText += ' (yaklaşık $daysLeft gün)';
      }
    }
    
    // Son yenileme tarihi
    String lastRefillText = 'Son stok girişi yok';
    if (medication.lastRefillDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy', 'tr_TR');
      lastRefillText = 'Son stok: ${dateFormat.format(medication.lastRefillDate!)}';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: InkWell(
        onTap: () => _showUpdateStockDialog(medication: medication),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İlaç renk etiketi
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: medication.color ?? Colors.blue,
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: Center(
                      child: Icon(
                        hasStock && stock <= 0
                            ? Icons.warning_amber_rounded
                            : Icons.medication_rounded,
                        color: Colors.white,
                        size: 30,
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
                          style: AppTextStyles.heading3,
                        ),
                        if (medication.dosage?.isNotEmpty ?? false) ...[
                          const SizedBox(height: AppDimens.paddingXS),
                          Text(
                            medication.dosage ?? '',
                            style: AppTextStyles.bodyText,
                          ),
                        ],
                        if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppDimens.paddingXS),
                          Text(
                            medication.notes!,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Stok durumu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingS,
                      vertical: AppDimens.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        stockColor.red, 
                        stockColor.green, 
                        stockColor.blue, 
                        0.1
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      border: Border.all(color: stockColor),
                    ),
                    child: Text(
                      stockText,
                      style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    lastRefillText,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              
              // İlerleme çubuğu (eğer stok eşiği tanımlıysa)
              if (hasStock && medication.stockThreshold != null && medication.stockThreshold! > 0) ...[
                const SizedBox(height: AppDimens.paddingM),
                LinearProgressIndicator(
                  value: stock > 0 
                      ? (stock / (medication.stockThreshold! * 3)).clamp(0.0, 1.0) 
                      : 0.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                  minHeight: 8,
                ),
              ],
              
              // Kullanım bilgisi
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: AppDimens.iconSizeS,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimens.paddingXS),
                  Text(
                    'Günde ${medication.timesPerDay ?? 0} kez, her seferde ${medication.dosesPerTime ?? 1} doz',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
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
        builder: (context) => AlertDialog(
          title: const Text('İlaç Seçin'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: med.color ?? Colors.blue,
                    child: const Icon(Icons.medication, color: Colors.white),
                  ),
                  title: Text(med.name),
                  subtitle: med.dosage != null && med.dosage!.isNotEmpty 
                      ? Text(med.dosage!) 
                      : null,
                  onTap: () => Navigator.of(context).pop(med),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        ),
      );
      
      if (selected == null) return;
      medication = selected;
    }
    
    // Stok güncelleme diyaloğu
    final TextEditingController stockController = TextEditingController(
      text: medication.currentStock?.toString() ?? '',
    );
    
    final currentStock = medication.currentStock ?? 0;
    int newStock = currentStock;
    bool isAddition = true;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('${medication!.name} Stok Güncelleme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut stok: ${currentStock > 0 ? '$currentStock ${medication?.stockUnit ?? 'adet'}' : 'Stok yok'}',
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: AppDimens.paddingM),
                
                // Ekleme/Çıkarma seçimi
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Stok Ekle'),
                        value: true,
                        groupValue: isAddition,
                        onChanged: (value) {
                          setState(() {
                            isAddition = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Stok Düş'),
                        value: false,
                        groupValue: isAddition,
                        onChanged: (value) {
                          setState(() {
                            isAddition = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                // Miktar girişi
                TextField(
                  controller: stockController,
                  decoration: InputDecoration(
                    labelText: 'Miktar (${medication?.stockUnit ?? 'adet'})',
                    border: const OutlineInputBorder(),
                    hintText: 'Güncelleme miktarını girin',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppDimens.paddingM),
                
                // Yeni durum önizleme
                Builder(
                  builder: (context) {
                    final amount = int.tryParse(stockController.text) ?? 0;
                    newStock = isAddition 
                        ? currentStock + amount 
                        : (currentStock - amount < 0 ? 0 : currentStock - amount);
                    
                    return Text(
                      'Yeni stok: $newStock ${medication?.stockUnit ?? 'adet'}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: newStock <= (medication?.stockThreshold ?? 0) ? Colors.orange : Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(stockController.text) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen geçerli bir miktar girin.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  
                  newStock = isAddition 
                      ? currentStock + amount 
                      : (currentStock - amount < 0 ? 0 : currentStock - amount);
                  
                  Navigator.of(context).pop(true);
                },
                child: const Text('Güncelle'),
              ),
            ],
          );
        },
      ),
    ).then((updated) async {
      if (updated == true) {
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
          ),
        );
      }
    });
  }
}