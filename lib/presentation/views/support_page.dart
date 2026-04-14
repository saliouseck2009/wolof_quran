import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/datasources/remote_config_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';

class SupportPage extends StatelessWidget {
  static const String routeName = '/support';
  static const String _contactEmail = 'saliouseck2009@gmail.com';

  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIos) {
      return _SupportUnavailableOnIosView(
        localizations: localizations,
        colorScheme: colorScheme,
        isDark: isDark,
        primary: primary,
        contactEmail: _contactEmail,
      );
    }

    final config = locator<RemoteConfigService>().config;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.supportPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? colorScheme.surface : primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero section ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerLow
                    : primary.withValues(alpha: 0.04),
              ),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                children: [
                  // Support icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainer
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/icon/soutien.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    localizations.supportPageTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    config.messageForLocale(languageCode),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),

            // ── Payment methods ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  // Wave card
                  _PaymentMethodCard(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    title: 'Wave',
                    subtitle: localizations.payWithWave,
                    iconAsset: 'assets/icon/wave.png',
                    accentColor: const Color(0xFF1DC4F0),
                    qrData: config.waveUrl,
                    actionLabel: config.waveLabel,
                    actionIcon: Icons.open_in_new_rounded,
                    onAction: () => _openUrl(config.waveUrl),
                  ),

                  const SizedBox(height: 16),

                  // PI SPI card
                  _PaymentMethodCard(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    title: 'PI SPI',
                    subtitle: localizations.piSpiPayment,
                    iconAsset: 'assets/icon/pi_spi.png',
                    accentColor: colorScheme.primary,
                    qrData: config.piSpiQrData,
                    copyableId: config.piSpiText,
                    copyLabel: localizations.copyId,
                    onCopy: () => _copyToClipboard(
                      context,
                      config.piSpiText,
                      localizations,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(
    BuildContext context,
    String text,
    AppLocalizations localizations,
  ) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.copiedToClipboard),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SupportUnavailableOnIosView extends StatelessWidget {
  final AppLocalizations localizations;
  final ColorScheme colorScheme;
  final bool isDark;
  final Color primary;
  final String contactEmail;

  const _SupportUnavailableOnIosView({
    required this.localizations,
    required this.colorScheme,
    required this.isDark,
    required this.primary,
    required this.contactEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.supportPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? colorScheme.surface : primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.supportUnavailableOnIosTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.supportUnavailableOnIosBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${localizations.contactEmailLabel}: $contactEmail',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Payment method card
// ─────────────────────────────────────────────────────────────

class _PaymentMethodCard extends StatefulWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final String title;
  final String subtitle;
  final String iconAsset;
  final Color accentColor;
  final String qrData;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? copyableId;
  final String? copyLabel;
  final VoidCallback? onCopy;

  const _PaymentMethodCard({
    required this.isDark,
    required this.colorScheme,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.accentColor,
    required this.qrData,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.copyableId,
    this.copyLabel,
    this.onCopy,
  });

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final cardColor = widget.isDark ? cs.surfaceContainer : Colors.white;
    final accent = widget.accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expanded
              ? accent.withValues(alpha: 0.3)
              : cs.onSurface.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // ── Tap header to expand/collapse QR ──
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(widget.iconAsset, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? (widget.copyableId != null
                                      ? widget.copyLabel ?? ''
                                      : widget.actionLabel ?? '')
                                : widget.subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),

                    // Expand indicator
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Expandable QR section ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context, cs, accent),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    ColorScheme cs,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          // Thin separator
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 20),
            color: cs.onSurface.withValues(alpha: 0.06),
          ),

          // QR Code
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: QrImageView(
              data: widget.qrData,
              version: QrVersions.auto,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action button (Wave link)
          if (widget.actionLabel != null && widget.onAction != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onAction,
                icon: Icon(widget.actionIcon, size: 18),
                label: Text(
                  widget.actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Copyable ID (PI SPI)
          if (widget.copyableId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? cs.surfaceContainerHigh
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.copyableId!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.3,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onCopy != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: widget.onCopy,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 14, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                widget.copyLabel ?? '',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
