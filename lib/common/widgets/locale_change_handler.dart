import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
import 'package:medalarmm/features/onboarding/providers/locale_provider.dart';
import 'package:provider/provider.dart';

/// This helper widget is designed to force reload the entire app when locale changes.
/// Place this widget at the top of your widget tree to properly handle locale changes.
class LocaleChangeHandler extends StatefulWidget {
  final Widget child;

  const LocaleChangeHandler({Key? key, required this.child}) : super(key: key);

  @override
  State<LocaleChangeHandler> createState() => _LocaleChangeHandlerState();
}

class _LocaleChangeHandlerState extends State<LocaleChangeHandler> {
  String _currentLocale = 'tr'; // Varsayılan değer olarak 'tr' atıyoruz

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<LocaleProvider>(context, listen: false);
        _currentLocale = provider.locale.languageCode;
        setState(() {}); // UI'ı güncelle
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final newLocale = provider.locale.languageCode;
        if (_currentLocale != newLocale) {
          _currentLocale = newLocale;
          // Dil değiştiğinde widget ağacını yeniden oluştur
          return KeyedSubtree(
            key: ValueKey('locale_$newLocale'),
            child: widget.child,
          );
        }

        return widget.child;
      },
    );
  }
}

/// ÇÖZÜM KILAVUZU
/// 
/// Dil değişiminin doğru çalışması için aşağıdaki adımları uygulayın:
/// 
/// 1. Uygulamanızı main.dart içinde aşağıdaki gibi sarmalayın:
/// 
/// ```dart
/// void main() {
///   runApp(
///     LocaleChangeHandler(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
/// 
/// 2. language_settings_screen.dart içinde dil değişirken uygulamayı tamamen yeniden başlatın:
/// 
/// ```dart
/// onTap: () async {
///   await localeProvider.setTurkish(); // veya setEnglish()
///   if (context.mounted) {
///     Navigator.pop(context, true);
///     // Yeniden başlatma işlemi
///     Navigator.pushNamedAndRemoveUntil(
///       context,
///       '/',
///       (route) => false,
///     );
///   }
/// },
/// ```
/// 
/// 3. ProfileScreen ve diğer ekranlarda dil değişimine duyarlı metinleri Consumer<LocaleProvider> içinde tanımlayın.
/// 
/// ```dart
/// Consumer<LocaleProvider>(
///   builder: (context, localeProvider, _) {
///     final loc = AppLocalizations.of(context);
///     return Text(loc.translate('some_key'));
///   }
/// )
/// ```
///
/// Bu değişiklikleri yaptıktan sonra dil değişikliği tüm ekranlarda doğru şekilde çalışacaktır.
