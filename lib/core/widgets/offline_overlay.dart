import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity_service.dart';
import '../theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/theme/app_icon_size.dart';

/// Duration the app must be offline before the full-screen overlay appears.
const _offlineOverlayDelay = Duration(seconds: 5);

/// A full-screen overlay that covers the entire app when the device has been
/// offline for longer than [OfflineOverlay.delay].
///
/// The overlay has a delayed trigger (default 5 seconds) so brief connection
/// drops don't cause a disruptive full-screen flash. It dismisses immediately
/// when connectivity is restored.
class OfflineOverlay extends ConsumerStatefulWidget {
  /// Delay before the overlay appears after losing connectivity.
  final Duration delay;

  /// Optional callback when the overlay appears.
  final VoidCallback? onOverlayShown;

  /// Optional callback when the overlay dismisses.
  final VoidCallback? onOverlayDismissed;

  const OfflineOverlay({
    super.key,
    this.delay = _offlineOverlayDelay,
    this.onOverlayShown,
    this.onOverlayDismissed,
  });

  @override
  ConsumerState<OfflineOverlay> createState() => _OfflineOverlayState();
}

class _OfflineOverlayState extends ConsumerState<OfflineOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _delayTimer;
  bool _showOverlay = false;

  // Fade animation
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _startOfflineTimer() {
    _delayTimer?.cancel();
    _delayTimer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() => _showOverlay = true);
      _animCtrl.forward();
      widget.onOverlayShown?.call();
    });
  }

  void _cancelOfflineTimer() {
    _delayTimer?.cancel();
    if (_showOverlay) {
      _animCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _showOverlay = false);
        widget.onOverlayDismissed?.call();
      });
    }
  }

  Future<void> _handleRetry() async {
    // Re-check connectivity manually (lightweight — no re-subscription)
    await ConnectivityService.instance.retry();
    // If still offline the stream will re-trigger the timer
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (next == false) {
        // Went offline — start the delay timer
        _startOfflineTimer();
      } else if (next == true) {
        // Back online — cancel timer and dismiss overlay
        _cancelOfflineTimer();
      }
    });

    if (!_showOverlay) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        // Use a transparent color so the app content is visible but dimmed
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing wifi-off icon
                  _AnimatedWifiOffIcon(),
                  const SizedBox(height: AppSpacing.s24),
                  Text(
                    'Tidak Ada Koneksi Internet',
                    style: AppTheme.heading2.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s48),
                    child: Text(
                      'Aplikasi membutuhkan koneksi internet untuk berfungsi.\n'
                      'Periksa koneksi Wi-Fi atau data seluler Anda.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  // Small indicator that we're watching
                  Text(
                    ref.watch(isOnlineProvider)
                        ? 'Tersambung kembali...'
                        : 'Menunggu koneksi...',
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s40),
                  _RetryButton(onRetry: _handleRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated wifi-off icon that pulses gently to draw attention.
class _AnimatedWifiOffIcon extends StatefulWidget {
  @override
  State<_AnimatedWifiOffIcon> createState() => _AnimatedWifiOffIconState();
}

class _AnimatedWifiOffIconState extends State<_AnimatedWifiOffIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.wifi_off_rounded,
          size: AppIconSize.s52,
          color: AppTheme.warningColor,
        ),
      ),
    );
  }
}

/// Retry button styled for the dark overlay background.
class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.refresh_rounded, size: AppIconSize.s20),
      label: const Text('Coba Lagi'),
      onPressed: onRetry,        style: FilledButton.styleFrom(
        backgroundColor: AppTheme.surfaceColorTheme(context),
        foregroundColor: AppTheme.onSurfaceColorTheme(context),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32, vertical: AppSpacing.s16),
      ),
    );
  }
}
