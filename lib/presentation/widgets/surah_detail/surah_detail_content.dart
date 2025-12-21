import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/audio_management_cubit.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../cubits/surah_detail_cubit.dart';
import 'surah_ayahs_list.dart';
import 'surah_basmala_widget.dart';
import 'surah_detail_app_bar.dart';

class SurahDetailContent extends StatefulWidget {
  final SurahDetailLoaded state;
  final int surahNumber;
  final int? initialAyahNumber;

  const SurahDetailContent({
    super.key,
    required this.state,
    required this.surahNumber,
    this.initialAyahNumber,
  });

  @override
  State<SurahDetailContent> createState() => _SurahDetailContentState();
}

class _SurahDetailContentState extends State<SurahDetailContent> {
  late final ScrollController _scrollController;
  late List<GlobalKey> _ayahKeys;
  bool _hasScrolledToInitialAyah = false;

  static const int _maxScrollAttempts = 6;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _buildAyahKeys();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudioManagement();
      _scrollToInitialAyahIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant SurahDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasAyahCountChanged =
        widget.state.ayahs.length != oldWidget.state.ayahs.length;
    final hasSurahChanged =
        widget.state.surahNumber != oldWidget.state.surahNumber;
    if (hasAyahCountChanged || hasSurahChanged) {
      _buildAyahKeys();
      _hasScrolledToInitialAyah = false;
    }

    if (widget.initialAyahNumber != oldWidget.initialAyahNumber) {
      _hasScrolledToInitialAyah = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialAyahIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _buildAyahKeys() {
    _ayahKeys = List.generate(
      widget.state.ayahs.length,
      (_) => GlobalKey(),
    );
  }

  void _initializeAudioManagement() {
    final audioManagementCubit = context.read<AudioManagementCubit>();
    final currentState = audioManagementCubit.state;

    if (currentState is! AudioManagementLoaded) {
      audioManagementCubit.initialize();
    }

    final quranSettingsCubit = context.read<QuranSettingsCubit>();
    final quranSettingsState = quranSettingsCubit.state;

    if (quranSettingsState.selectedReciter != null) {
      audioManagementCubit.loadAyahAudios(
        quranSettingsState.selectedReciter!.id,
        widget.surahNumber,
      );
    }
  }

  void _scrollToInitialAyahIfNeeded() {
    if (_hasScrolledToInitialAyah || widget.initialAyahNumber == null) {
      return;
    }

    final targetIndex = widget.initialAyahNumber! - 1;
    if (targetIndex < 0 || targetIndex >= _ayahKeys.length) {
      _hasScrolledToInitialAyah = true;
      return;
    }

    _attemptScrollToAyah(targetIndex, 0);
  }

  void _attemptScrollToAyah(int index, int attempt) {
    if (_hasScrolledToInitialAyah) return;

    if (!_scrollController.hasClients) {
      _scheduleRetry(index, attempt + 1);
      return;
    }

    final ayahContext = _ayahKeys[index].currentContext;
    if (ayahContext != null) {
      Scrollable.ensureVisible(
        ayahContext,
        duration: const Duration(milliseconds: 450),
        alignment: 0.08,
        curve: Curves.easeInOut,
      );
      _hasScrolledToInitialAyah = true;
      return;
    }

    final position = _scrollController.position;
    final maxScrollExtent = position.maxScrollExtent;
    if (maxScrollExtent > 0) {
      final estimatedOffset = (maxScrollExtent * (index / _ayahKeys.length))
          .clamp(0.0, maxScrollExtent);
      _scrollController.jumpTo(estimatedOffset);
    }

    _scheduleRetry(index, attempt + 1);
  }

  void _scheduleRetry(int index, int nextAttempt) {
    if (nextAttempt >= _maxScrollAttempts) {
      _hasScrolledToInitialAyah = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScrollToAyah(index, nextAttempt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SurahDetailAppBar(state: widget.state),
          if (widget.surahNumber != 9 &&
              (widget.state.displayMode == AyahDisplayMode.both ||
                  widget.state.displayMode == AyahDisplayMode.arabicOnly))
            const SurahBasmalaWidget(),
          SurahAyahsList(
            surahNumber: widget.surahNumber,
            ayahs: widget.state.ayahs,
            translationSource: widget.state.translationSource,
            displayMode: widget.state.displayMode,
            ayahKeys: _ayahKeys,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 64)),
        ],
      ),
    );
  }
}
