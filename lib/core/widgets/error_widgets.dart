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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(
                height: 1.5,
              ),
            ),
            if (technicalDetails != null && technicalDetails!.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Show technical detail collapsed
              Text(
                technicalDetails!,
                style: AppTheme.caption.copyWith(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (onRetry != null)
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.warningColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 16, color: AppTheme.warningColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tidak ada koneksi internet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.warningColor,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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

/// Inline error snackbar helper
class ErrorSnackbar {
  static void show(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error.isOffline
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(error.userMessage)),
          ],
        ),
        backgroundColor: error.isOffline
            ? AppTheme.warningColor
            : AppTheme.lossColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static void showMessage(BuildContext context, String message,
      {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? AppTheme.lossColor : AppTheme.profitColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
