import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';

/// Uygulamada kullanılabilecek farklı bildirim tipleri
enum NotificationType {
  success,
  warning,
  error,
  info
}

/// Kullanıcıya bilgilendirme mesajları göstermek için widget
class NotificationWidget extends StatelessWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onAction;
  final String? actionText;
  final bool isDismissible;
  final Duration duration;

  const NotificationWidget({
    Key? key, 
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.onAction,
    this.actionText,
    this.isDismissible = true,
    this.duration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: _getIconColor(),
                    size: 24,
                  ),
                  const SizedBox(width: AppDimens.paddingS),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyTextBold.copyWith(
                        color: _getIconColor(),
                      ),
                    ),
                  ),
                  if (isDismissible)
                    InkWell(
                      onTap: () {
                        // Bildirim konteynerini kapat
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          color: _getIconColor().withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingS),
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Text(
                  message,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onAction != null && actionText != null) ...[
                const SizedBox(height: AppDimens.paddingM),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: _getIconColor(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingM,
                        vertical: AppDimens.paddingS,
                      ),
                    ),
                    child: Text(
                      actionText!,
                      style: AppTextStyles.bodyTextBold.copyWith(
                        color: _getIconColor(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Bildirim tipine göre ikon seç
  IconData _getIcon() {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
    }
  }

  // Bildirim tipine göre renk seç
  Color _getIconColor() {
    switch (type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.info:
        return AppColors.primary;
    }
  }

  // Bildirim tipine göre arkaplan rengi seç
  Color _getBackgroundColor() {
    switch (type) {
      case NotificationType.success:
        return AppColors.success.withOpacity(0.05);
      case NotificationType.warning:
        return AppColors.warning.withOpacity(0.05);
      case NotificationType.error:
        return AppColors.error.withOpacity(0.05);
      case NotificationType.info:
        return AppColors.primary.withOpacity(0.05);
    }
  }

  // Bildirim tipine göre kenarlık rengi seç
  Color _getBorderColor() {
    switch (type) {
      case NotificationType.success:
        return AppColors.success.withOpacity(0.3);
      case NotificationType.warning:
        return AppColors.warning.withOpacity(0.3);
      case NotificationType.error:
        return AppColors.error.withOpacity(0.3);
      case NotificationType.info:
        return AppColors.primary.withOpacity(0.3);
    }
  }

  /// Bildirim göstermek için yardımcı metod
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    VoidCallback? onAction,
    String? actionText,
    bool isDismissible = true,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + AppDimens.paddingL,
        left: 0,
        right: 0,
        child: NotificationWidget(
          title: title,
          message: message,
          type: type,
          onAction: onAction,
          actionText: actionText,
          isDismissible: isDismissible,
          duration: duration,
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    if (isDismissible) {
      Future.delayed(duration, () {
        overlayEntry.remove();
      });
    }
  }

  /// Snackbar olarak bildirim göstermek için yardımcı metod
  static void showSnackBar({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    VoidCallback? onAction,
    String? actionText,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconStatic(type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppDimens.paddingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getSnackbarColor(type),
        duration: duration,
        action: actionText != null && onAction != null
            ? SnackBarAction(
                label: actionText,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        margin: const EdgeInsets.all(AppDimens.paddingM),
      ),
    );
  }

  // Statik ikon seçici
  static IconData _getIconStatic(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
    }
  }

  // Snackbar için renk seçici
  static Color _getSnackbarColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.info:
        return AppColors.primary;
    }
  }
}
