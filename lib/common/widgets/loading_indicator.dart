import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            message ?? 'Yükleniyor...',
            style: AppTextStyles.bodyTextBold.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Lütfen bekleyin',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}