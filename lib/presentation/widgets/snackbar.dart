import 'dart:ui';

import 'package:flutter/material.dart';

class CustomSnackbar {
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    int duration = 2,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (context) =>
          _buildCustomSnackbar(message, icon: Icons.error_outline),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    int duration = 2,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (context) =>
          _buildCustomSnackbar(message, icon: Icons.check_circle_rounded),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  static Widget _buildCustomSnackbar(
    String message, {
    Color backgroundColor = Colors.black87,
    IconData? icon,
  }) {
    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                color: backgroundColor.withValues(alpha: 0.85),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                    Flexible(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showSnackbarAction(
    BuildContext context,
    String message,
    Function()? onPressed,
  ) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  color: Colors.black87.withValues(alpha: 0.85),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                          overlayEntry.remove();
                          if (onPressed != null) onPressed();
                        },
                        child: const Text(
                          'Voir',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void showSnackbar(
    BuildContext context,
    String message, {
    int duration = 2,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (context) => _buildCustomSnackbar(message),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: duration), () {
      overlayEntry.remove();
    });
  }
}
