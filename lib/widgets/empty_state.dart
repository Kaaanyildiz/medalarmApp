import 'package:flutter/material.dart';
import 'package:medalarmm/constants/app_constants.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withAlpha(128), // 0.5 * 255 = 128
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              message,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppDimens.paddingL),
              SizedBox(
                height: 50,
                width: 200,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  child: Text(buttonText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}