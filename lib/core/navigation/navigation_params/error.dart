import 'package:flutter/widgets.dart';

class ErrorPageParams {
  final String title;
  final String error;
  final void Function()? onRetry;
  final void Function() onCancel;
  final IconData icon;

  const ErrorPageParams({
    required this.title,
    required this.error,
    this.onRetry,
    required this.onCancel,
    required this.icon,
  });
}
