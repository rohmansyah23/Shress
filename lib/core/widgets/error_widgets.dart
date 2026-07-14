import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';

/// Full-screen error state with icon, message, and retry button
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color iconColor;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.technicalDetails,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
    this.iconColor = AppTheme.lossColor,
  });

  factory ErrorRetryWidget.fromAppError(AppError error, {VoidCallback? onRetry}) {
    return ErrorRetryWidget(
      message: error.userMessage,
      technicalDetails: error.technicalMessage,
      onRetry: onRetry,
      icon: error.isOffline
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      iconColor: error.isOffline
          ? AppTheme.warningColor
          : AppTheme.lossColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: AppTheme.s20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(
                height: 1.5,
              ),
            ),
            if (technicalDetails != null && technicalDetails!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.s8),
              Text(
                technicalDetails!,
                style: AppTheme.labelSmall.copyWith(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppTheme.s24),
            if (onRetry != null)
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.s24,
                    vertical: AppTheme.s12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A persistent offline banner at the top of the content
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.s12, vertical: AppTheme.s8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.warning.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 16, color: AppTheme.warning),
          const SizedBox(width: AppTheme.s8),
          Expanded(
            child: Text(
              'Tidak ada koneksi internet',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.warning,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Coba lagi',
                  style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

/// Inline snackbar helper with theme-aware colors
class ErrorSnackbar {
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppTheme.s8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void show(BuildContext context, AppError error) {
    _show(
      context,
      message: error.userMessage,
      backgroundColor: error.isOffline
          ? AppTheme.warningColorTheme(context)
          : AppTheme.lossColorTheme(context),
      icon: error.isOffline
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      actionLabel: 'Tutup',
    );
  }

  static void showMessage(BuildContext context, String message,
      {bool isError = true}) {
    if (isError) {
      showError(context, message);
    } else {
      showSuccess(context, message);
    }
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.profitColorTheme(context),
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.lossColorTheme(context),
      icon: Icons.error_outline_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.warningColorTheme(context),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.infoColorTheme(context),
      icon: Icons.info_outline_rounded,
    );
  }
}
