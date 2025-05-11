import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
import 'package:medalarmm/features/onboarding/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('language')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimens.paddingM),
            Text(
              loc.translate('select_language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingL),
            
            // Türkçe dil seçeneği
            _buildLanguageOption(
              context: context,
              title: 'Türkçe',
              subtitle: loc.translate('turkish'),
              isSelected: localeProvider.isTurkish,
              onTap: () => localeProvider.setTurkish(),
              flagEmoji: '🇹🇷',
            ),
            
            const Divider(),
            
            // İngilizce dil seçeneği
            _buildLanguageOption(
              context: context,
              title: 'English',
              subtitle: loc.translate('english'),
              isSelected: localeProvider.isEnglish, 
              onTap: () => localeProvider.setEnglish(),
              flagEmoji: '🇺🇸',
            ),
            
            const Divider(),
            
            const SizedBox(height: AppDimens.paddingXL),
            
            // Dil hakkında bilgi notu
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Text(
                loc.translate('language_info_note'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required String flagEmoji,
  }) {
    return ListTile(
      title: Row(
        children: [
          Text(
            flagEmoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppDimens.paddingM),
          Text(title),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
    );
  }
}
