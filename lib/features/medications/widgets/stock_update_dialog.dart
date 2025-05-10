import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/models/medication.dart';

class StockUpdateDialog extends StatefulWidget {
  final Medication medication;
  final Function(int newStock, bool isAddition) onUpdate;

  const StockUpdateDialog({
    super.key,
    required this.medication,
    required this.onUpdate,
  });

  @override
  State<StockUpdateDialog> createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<StockUpdateDialog> {
  late TextEditingController _stockController;
  bool _isAddition = true;
  int _newStock = 0;
  int _currentStock = 0;

  @override
  void initState() {
    super.initState();
    _currentStock = widget.medication.currentStock ?? 0;
    _stockController = TextEditingController(text: '');
    _calculateNewStock();
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _calculateNewStock() {
    final amount = int.tryParse(_stockController.text) ?? 0;
    setState(() {
      _newStock = _isAddition
          ? _currentStock + amount
          : (_currentStock - amount < 0 ? 0 : _currentStock - amount);
    });
  }

  Color _getStockColor() {
    if (_newStock <= 0) {
      return AppColors.error;
    } else if (_newStock <= (widget.medication.stockThreshold ?? 0)) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockColor = _getStockColor();
    final stockUnit = widget.medication.stockUnit ?? 'adet';
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.medication.color,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.medication.name} Stok Güncelleme',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.medication.dosage?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppDimens.paddingXS),
                        Text(
                          widget.medication.dosage ?? '',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimens.paddingL),
            
            // Mevcut stok bilgisi
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimens.paddingM),
                  Expanded(
                    child: Text(
                      'Mevcut stok: ${_currentStock > 0 ? '$_currentStock $stockUnit' : 'Stok yok'}',
                      style: AppTextStyles.bodyTextBold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimens.paddingL),
            
            // Ekleme/Çıkarma seçimi
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAddition = true;
                        _calculateNewStock();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: _isAddition
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        border: Border.all(
                          color: _isAddition
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle,
                            color: _isAddition
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Text(
                            'Stok Ekle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isAddition
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAddition = false;
                        _calculateNewStock();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: !_isAddition
                            ? AppColors.warning.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        border: Border.all(
                          color: !_isAddition
                              ? AppColors.warning
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.remove_circle,
                            color: !_isAddition
                                ? AppColors.warning
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: AppDimens.paddingS),
                          Text(
                            'Stok Düş',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isAddition
                                  ? AppColors.warning
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimens.paddingL),
            
            // Miktar girişi
            TextField(
              controller: _stockController,
              onChanged: (_) => _calculateNewStock(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Miktar ($stockUnit)',
                hintText: 'Güncelleme miktarını girin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  borderSide: BorderSide(
                    color: _isAddition ? AppColors.primary : AppColors.warning,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  borderSide: BorderSide(
                    color: _isAddition ? AppColors.primary : AppColors.warning,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  _isAddition ? Icons.add_box : Icons.indeterminate_check_box,
                  color: _isAddition ? AppColors.primary : AppColors.warning,
                ),
                suffixText: stockUnit,
              ),
            ),
            
            const SizedBox(height: AppDimens.paddingL),
            
            // Yeni durum önizleme
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: stockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(
                  color: stockColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yeni stok:',
                    style: AppTextStyles.bodyText,
                  ),
                  Text(
                    '$_newStock $stockUnit',
                    style: AppTextStyles.heading3.copyWith(
                      color: stockColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimens.paddingXL),
            
            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
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
                const SizedBox(width: AppDimens.paddingM),
                ElevatedButton(
                  onPressed: () {
                    final amount = int.tryParse(_stockController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen geçerli bir miktar girin.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    
                    widget.onUpdate(_newStock, _isAddition);
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingL,
                      vertical: AppDimens.paddingM,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                  ),
                  child: const Text(
                    'Güncelle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
