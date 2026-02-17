import 'package:flutter/material.dart';
import 'package:wolof_quran/presentation/widgets/snackbar.dart';

/// Utility class for showing toast messages
class ToastService {
  static void showError(BuildContext context, String message) {
    CustomSnackbar.showErrorSnackbar(context, message);
  }

  static void showSuccess(BuildContext context, String message) {
    CustomSnackbar.showSuccessSnackbar(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    CustomSnackbar.showSnackbar(context, message);
  }

  static void showWarning(BuildContext context, String message) {
    CustomSnackbar.showSnackbar(context, message);
  }
}
