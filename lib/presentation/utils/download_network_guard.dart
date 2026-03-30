import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/snackbar.dart';

class DownloadNetworkGuard {
  const DownloadNetworkGuard._();

  static Future<bool> confirmManualDownload(BuildContext context) async {
    final status = await _currentStatus();
    if (!context.mounted) {
      return false;
    }
    if (status == _DownloadConnectionStatus.wifiLike) {
      return true;
    }

    final localizations = AppLocalizations.of(context)!;

    if (status == _DownloadConnectionStatus.offline) {
      CustomSnackbar.showErrorSnackbar(
        context,
        localizations.checkInternetConnection,
        duration: 3,
      );
      return false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final buttonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        );
        final secondaryButtonStyle = FilledButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: buttonShape,
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );
        final primaryButtonStyle = FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: buttonShape,
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.network_cell_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.mobileDataDownloadTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.mobileDataDownloadMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: secondaryButtonStyle,
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          child: Text(localizations.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: primaryButtonStyle,
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          child: Text(localizations.continueDownload),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted) {
      return false;
    }
    return result ?? false;
  }

  static Future<bool> canAutoDownload() async {
    final status = await _currentStatus();
    return status == _DownloadConnectionStatus.wifiLike;
  }

  static Future<_DownloadConnectionStatus> _currentStatus() async {
    final results = await Connectivity().checkConnectivity();

    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return _DownloadConnectionStatus.wifiLike;
    }

    final hasAnyNetwork = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasAnyNetwork) {
      return _DownloadConnectionStatus.offline;
    }

    return _DownloadConnectionStatus.meteredOrUnknown;
  }
}

enum _DownloadConnectionStatus { wifiLike, meteredOrUnknown, offline }
