import '../../l10n/generated/app_localizations.dart';

/// Maps technical audio/download errors to localized, user-friendly messages.
String formatAudioError(String error, AppLocalizations localizations) {
  final trimmed = error.trim();
  if (trimmed.isEmpty) return localizations.downloadFailed;

  final lower = trimmed.toLowerCase();
  if (lower.contains('download_in_progress')) {
    return localizations.downloadInProgress;
  }
  const dio404Signature = 'status code of 404 and requestoptions.validatestatus';

  if (lower.contains(dio404Signature) ||
      (lower.contains('requestoptions.validatestatus') &&
          lower.contains('404'))) {
    return localizations.dioStatus404;
  }
  if (lower.contains('socketexception') || lower.contains('connection')) {
    return localizations.checkInternetConnection;
  }
  if (lower.contains('timeout')) {
    return localizations.connectionTimeout;
  }
  if (lower.contains('404') || lower.contains('not found')) {
    return localizations.audioFileNotFound;
  }
  if (lower.contains('403') || lower.contains('forbidden')) {
    return localizations.accessDeniedToAudio;
  }
  if (lower.contains('storage') || lower.contains('space')) {
    return localizations.notEnoughStorage;
  }

  return localizations.downloadFailed;
}
