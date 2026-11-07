import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_links.dart';
import '../../data/datasources/remote_config_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../service_locator.dart';

class SupportPage extends StatelessWidget {
  static const String routeName = '/support';
  static const String _contactEmail = 'saliouseck2009@gmail.com';

  /// Apple in-app contribution. Off until the App Store Connect product
  /// (`_AppleSupportViewState._productId`), the paid-apps agreement and the
  /// banking details are configured; the settings entries stay hidden on
  /// iOS meanwhile.
  static const bool appleContributionEnabled = false;

  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIos) {
      if (appleContributionEnabled) {
        return const _AppleSupportView();
      }
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

/// Shown on iOS while the Apple contribution is off.
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
            color: isDark
                ? colorScheme.surfaceContainer
                : colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.supportUnavailableOnIosTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

enum _SupportError { storeUnavailable, productUnavailable, paymentFailed }

class _AppleSupportView extends StatefulWidget {
  const _AppleSupportView();

  @override
  State<_AppleSupportView> createState() => _AppleSupportViewState();
}

class _AppleSupportViewState extends State<_AppleSupportView> {
  // Create this consumable product in App Store Connect with this exact ID.
  static const _productId = 'com.saliouseck.wolofquran.support';
  final _iap = InAppPurchase.instance;
  ProductDetails? _product;
  _SupportError? _error;
  bool _loading = true;
  bool _purchasing = false;
  bool _thanked = false;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _error = _SupportError.paymentFailed;
            _purchasing = false;
          });
        }
      },
    );
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    ProductDetails? product;
    _SupportError? error;
    try {
      if (!await _iap.isAvailable()) {
        error = _SupportError.storeUnavailable;
      } else {
        final response = await _iap.queryProductDetails({_productId});
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
        } else {
          error = _SupportError.productUnavailable;
        }
      }
    } catch (_) {
      error = _SupportError.productUnavailable;
    }
    if (!mounted) return;
    setState(() {
      _product = product;
      _error = error;
      _loading = false;
    });
  }

  Future<void> _buy() async {
    final product = _product;
    if (product == null || _purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    var started = false;
    try {
      started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      started = false;
    }
    if (!started && mounted) {
      setState(() {
        _purchasing = false;
        _error = _SupportError.paymentFailed;
      });
    }
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (mounted) {
          setState(() {
            _thanked = true;
            _error = null;
          });
        }
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        if (mounted) {
          setState(() {
            _error = purchase.status == PurchaseStatus.error
                ? _SupportError.paymentFailed
                : null;
          });
        }
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (_) {
          // Nothing the user can do; the store will retry on next launch.
        }
      }
    }
    if (mounted) setState(() => _purchasing = false);
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          localizations.supportPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cs.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? cs.surface : cs.primary,
        iconTheme: IconThemeData(color: cs.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _thanked
              ? _ThankYouView(
                  onShare: () => Share.share(
                    '${localizations.supportShareText}\n\n'
                    'Android: ${AppLinks.playStoreUrl}\n'
                    'iOS: ${AppLinks.appStoreUrl}',
                  ),
                  onMore: () => setState(() => _thanked = false),
                )
              : Column(
                  children: [
                    Image.asset(
                      'assets/icon/soutien.png',
                      width: 88,
                      height: 88,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.supportPageTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.supportAppleBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_product != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _purchasing ? null : _buy,
                          icon: _purchasing
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.favorite_rounded),
                          label: Text(
                            _purchasing
                                ? localizations.supportProcessing
                                : localizations.supportContribute(
                                    _product!.price,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.supportSecurePayment,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        switch (_error!) {
                          _SupportError.storeUnavailable =>
                            localizations.supportIapUnavailable,
                          _SupportError.productUnavailable =>
                            localizations.supportProductUnavailable,
                          _SupportError.paymentFailed =>
                            localizations.supportPaymentFailed,
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      '${localizations.contactEmailLabel}: ${SupportPage._contactEmail}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Shown once a contribution went through: thanks, and an invitation to
/// share the app, which is the other way to support it.
class _ThankYouView extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onMore;

  const _ThankYouView({required this.onShare, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, size: 48, color: cs.primary),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          localizations.supportThankYouTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          localizations.supportThankYouBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded),
            label: Text(localizations.supportShareApp),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onMore,
          child: Text(localizations.supportContributeAgain),
        ),
      ],
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
