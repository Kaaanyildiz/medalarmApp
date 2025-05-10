import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/onboarding/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      elevation: 4,
      shadowColor: AppColorScheme.shadow,
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
                Icon(
                  Icons.palette_outlined,
                  color: AppColorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Görünüm',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColorScheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: AppColorScheme.textSecondary,
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      themeProvider.isDarkMode ? 'Koyu tema' : 'Açık tema',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: AppColorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              themeProvider.isDarkMode 
                ? 'Koyu tema, göz yorgunluğunu azaltıp, gece kullanımında rahatlık sağlar.'
                : 'Açık tema, gündüz kullanımı için daha uygundur ve içeriği daha belirgin yapar.',
              style: AppTextStyles.bodyTextSmall.copyWith(
                color: AppColorScheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
