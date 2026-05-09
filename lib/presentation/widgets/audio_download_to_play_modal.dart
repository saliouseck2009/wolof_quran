import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cubits/audio_management_cubit.dart';
import '../utils/audio_error_formatter.dart';
import '../utils/download_network_guard.dart';
import 'snackbar.dart';

Future<bool> showAudioDownloadToPlayModal({
  required BuildContext context,
  required String reciterId,
  required int surahNumber,
  required String surahName,
  required bool isAvailableRemotely,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _AudioDownloadToPlayModal(
      reciterId: reciterId,
      surahNumber: surahNumber,
      surahName: surahName,
      isAvailableRemotely: isAvailableRemotely,
    ),
  );

  return result ?? false;
}

enum _DownloadModalStep { prompt, downloading, completed, failed }

class _AudioDownloadToPlayModal extends StatefulWidget {
  final String reciterId;
  final int surahNumber;
  final String surahName;
  final bool isAvailableRemotely;

  const _AudioDownloadToPlayModal({
    required this.reciterId,
    required this.surahNumber,
    required this.surahName,
    required this.isAvailableRemotely,
  });

  @override
  State<_AudioDownloadToPlayModal> createState() =>
      _AudioDownloadToPlayModalState();
}

class _AudioDownloadToPlayModalState extends State<_AudioDownloadToPlayModal> {
  late _DownloadModalStep _step;
  var _trackDownloadLifecycle = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _step = _resolveInitialStep();
  }

  _DownloadModalStep _resolveInitialStep() {
    if (!widget.isAvailableRemotely) {
      return _DownloadModalStep.prompt;
    }

    final audioState = context.read<AudioManagementCubit>().state;
    if (_isTargetDownloading(audioState) ||
        _isTargetMarkedInProgress(audioState)) {
      _trackDownloadLifecycle = true;
      return _DownloadModalStep.downloading;
    }

    return _DownloadModalStep.prompt;
  }

  bool _isTargetDownloading(AudioManagementState state) {
    return state is AudioDownloading &&
        state.reciterId == widget.reciterId &&
        state.surahNumber == widget.surahNumber;
  }

  bool _isTargetMarkedInProgress(AudioManagementState state) {
    return state is AudioDownloadAlreadyInProgress &&
        state.reciterId == widget.reciterId &&
        state.surahNumber == widget.surahNumber;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    final commonButtonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final commonButtonTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final secondaryButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: commonButtonShape,
      textStyle: commonButtonTextStyle,
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurface,
    );
    final primaryButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: commonButtonShape,
      textStyle: commonButtonTextStyle,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );

    return BlocListener<AudioManagementCubit, AudioManagementState>(
      listener: (context, state) {
        if (!_trackDownloadLifecycle) {
          return;
        }

        if (_isTargetDownloading(state) || _isTargetMarkedInProgress(state)) {
          if (_step != _DownloadModalStep.downloading) {
            setState(() {
              _step = _DownloadModalStep.downloading;
              _errorMessage = null;
            });
          }
          return;
        }

        if (state is AudioManagementLoaded) {
          final isDownloaded =
              state
                  .getSurahStatus(widget.reciterId, widget.surahNumber)
                  ?.isDownloaded ==
              true;
          if (isDownloaded && _step != _DownloadModalStep.completed) {
            setState(() {
              _step = _DownloadModalStep.completed;
              _errorMessage = null;
            });
          }
          return;
        }

        if (state is AudioManagementError) {
          setState(() {
            _step = _DownloadModalStep.failed;
            _errorMessage = formatAudioError(state.message, localizations);
          });
        }
      },
      child: SafeArea(
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
            child: BlocBuilder<AudioManagementCubit, AudioManagementState>(
              builder: (context, audioState) {
                final progress = _isTargetDownloading(audioState)
                    ? (audioState as AudioDownloading).progress
                    : null;
                final progressPercent = progress == null
                    ? null
                    : (progress * 100).clamp(0, 100).toInt();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStepIcon(colorScheme),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.surahName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _buildMessage(localizations, progressPercent),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    if (_step == _DownloadModalStep.downloading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: progress),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: _buildActions(
                        context: context,
                        localizations: localizations,
                        secondaryButtonStyle: secondaryButtonStyle,
                        primaryButtonStyle: primaryButtonStyle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon(ColorScheme colorScheme) {
    switch (_step) {
      case _DownloadModalStep.completed:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green),
        );
      case _DownloadModalStep.failed:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.error_outline_rounded, color: colorScheme.error),
        );
      case _DownloadModalStep.downloading:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.downloading_rounded, color: colorScheme.primary),
        );
      case _DownloadModalStep.prompt:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.isAvailableRemotely
                ? Icons.download_for_offline_outlined
                : Icons.info_outline_rounded,
            color: colorScheme.primary,
          ),
        );
    }
  }

  String _buildMessage(AppLocalizations localizations, int? progressPercent) {
    switch (_step) {
      case _DownloadModalStep.prompt:
        return widget.isAvailableRemotely
            ? localizations.audioNotAvailable
            : localizations.audioNotYetAvailable;
      case _DownloadModalStep.downloading:
        return progressPercent == null
            ? localizations.downloading
            : '${localizations.downloading} $progressPercent%';
      case _DownloadModalStep.completed:
        return localizations.downloadedSuccessfully(widget.surahName);
      case _DownloadModalStep.failed:
        return _errorMessage == null
            ? localizations.downloadFailed
            : localizations.downloadFailedWithError(_errorMessage!);
    }
  }

  List<Widget> _buildActions({
    required BuildContext context,
    required AppLocalizations localizations,
    required ButtonStyle secondaryButtonStyle,
    required ButtonStyle primaryButtonStyle,
  }) {
    switch (_step) {
      case _DownloadModalStep.prompt:
        return [
          Expanded(
            flex: 4,
            child: FilledButton(
              style: secondaryButtonStyle,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: FilledButton(
              style: primaryButtonStyle,
              onPressed: widget.isAvailableRemotely
                  ? () => _handleDownloadPressed(context)
                  : () => Navigator.of(context).pop(false),
              child: Text(
                widget.isAvailableRemotely
                    ? localizations.downloadLabel
                    : localizations.close,
              ),
            ),
          ),
        ];
      case _DownloadModalStep.downloading:
        return [
          Expanded(
            child: FilledButton(
              style: secondaryButtonStyle,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.close),
            ),
          ),
        ];
      case _DownloadModalStep.completed:
        return [
          Expanded(
            child: FilledButton(
              style: primaryButtonStyle,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ),
        ];
      case _DownloadModalStep.failed:
        return [
          Expanded(
            child: FilledButton(
              style: secondaryButtonStyle,
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.close),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: primaryButtonStyle,
              onPressed: () => _handleDownloadPressed(context),
              child: Text(localizations.retry),
            ),
          ),
        ];
    }
  }

  Future<void> _handleDownloadPressed(BuildContext context) async {
    final canProceed = await DownloadNetworkGuard.confirmManualDownload(
      context,
    );
    if (!canProceed || !context.mounted) {
      return;
    }

    final localizations = AppLocalizations.of(context)!;
    final audioState = context.read<AudioManagementCubit>().state;
    if (audioState is AudioDownloading) {
      final isSameSurah =
          audioState.reciterId == widget.reciterId &&
          audioState.surahNumber == widget.surahNumber;
      CustomSnackbar.showSnackbar(
        context,
        isSameSurah
            ? localizations.surahDownloadAlreadyInProgress
            : localizations.downloadInProgress,
        duration: 2,
      );

      if (isSameSurah && mounted) {
        setState(() {
          _trackDownloadLifecycle = true;
          _step = _DownloadModalStep.downloading;
        });
      }
      return;
    }

    if (audioState is AudioDownloadAlreadyInProgress) {
      final isSameSurah =
          audioState.reciterId == widget.reciterId &&
          audioState.surahNumber == widget.surahNumber;
      CustomSnackbar.showSnackbar(
        context,
        isSameSurah
            ? localizations.surahDownloadAlreadyInProgress
            : localizations.downloadInProgress,
        duration: 2,
      );

      if (isSameSurah && mounted) {
        setState(() {
          _trackDownloadLifecycle = true;
          _step = _DownloadModalStep.downloading;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _trackDownloadLifecycle = true;
      _step = _DownloadModalStep.downloading;
      _errorMessage = null;
    });

    context.read<AudioManagementCubit>().downloadSurahAudio(
      widget.reciterId,
      widget.surahNumber,
    );
  }
}
