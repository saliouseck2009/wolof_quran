import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/core/config/theme/app_color.dart';
import 'package:wolof_quran/core/helpers/revelation_place_enum.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../blocs/mushaf/mushaf_surah_list_bloc.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/surah_list/surah_card.dart';
import '../widgets/surah_list/surah_list_no_results.dart';

class MushafSurahPickerPage extends StatelessWidget {
  final int? currentSurahNumber;

  const MushafSurahPickerPage({
    super.key,
    this.currentSurahNumber,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MushafSurahListBloc()..add(const MushafSurahListLoaded()),
      child: _MushafSurahPickerView(currentSurahNumber: currentSurahNumber),
    );
  }
}

class _MushafSurahPickerView extends StatefulWidget {
  final int? currentSurahNumber;

  const _MushafSurahPickerView({this.currentSurahNumber});

  @override
  State<_MushafSurahPickerView> createState() => _MushafSurahPickerViewState();
}

class _MushafSurahPickerViewState extends State<_MushafSurahPickerView> {
  static const int _maxScrollAttempts = 6;

  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _surahKeys = <int, GlobalKey>{};
  bool _hasScrolledToCurrent = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForSurah(int surahNumber) {
    return _surahKeys.putIfAbsent(surahNumber, () => GlobalKey());
  }

  void _scrollToCurrentSurahIfNeeded(List<MushafSurahItem> surahs) {
    if (_hasScrolledToCurrent || widget.currentSurahNumber == null) {
      return;
    }

    final targetSurahNumber = widget.currentSurahNumber!;
    final targetIndex = surahs.indexWhere((s) => s.number == targetSurahNumber);
    if (targetIndex < 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScrollToSurah(targetSurahNumber, targetIndex, 0);
    });
  }

  void _attemptScrollToSurah(int surahNumber, int index, int attempt) {
    if (_hasScrolledToCurrent || !mounted) {
      return;
    }

    final targetContext = _surahKeys[surahNumber]?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
      _hasScrolledToCurrent = true;
      return;
    }

    if (!_scrollController.hasClients) {
      _scheduleRetry(surahNumber, index, attempt + 1);
      return;
    }

    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    if (maxExtent > 0) {
      final estimatedOffset = (maxExtent * (index / 114)).clamp(0.0, maxExtent);
      _scrollController.jumpTo(estimatedOffset);
    }

    _scheduleRetry(surahNumber, index, attempt + 1);
  }

  void _scheduleRetry(int surahNumber, int index, int nextAttempt) {
    if (nextAttempt >= _maxScrollAttempts) {
      _hasScrolledToCurrent = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScrollToSurah(surahNumber, index, nextAttempt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedTranslation = context.watch<QuranSettingsCubit>().currentTranslation;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations.selectSurah),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: BlocBuilder<MushafSurahListBloc, MushafSurahListState>(
              builder: (context, state) {
                return AppSearchBar(
                  controller: _searchController,
                  hintText: localizations.searchSurah,
                  isInAppBar: false,
                  hasActiveFilter: state.query.isNotEmpty,
                  onChanged: (value) {
                    context.read<MushafSurahListBloc>().add(
                      MushafSurahSearchChanged(value),
                    );
                  },
                  onClear: () {
                    _searchController.clear();
                    _hasScrolledToCurrent = false;
                    context.read<MushafSurahListBloc>().add(
                      const MushafSurahSearchChanged(''),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<MushafSurahListBloc, MushafSurahListState>(
              builder: (context, state) {
                final surahs = state.filteredSurahs;

                if (state.query.isEmpty) {
                  _scrollToCurrentSurahIfNeeded(surahs);
                }

                if (surahs.isEmpty) {
                  return const SurahListNoResults(asSliver: false);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    final isCurrentSurah = surah.number == widget.currentSurahNumber;
                    final translatedName =
                        QuranSettingsCubit.getSurahNameInTranslation(
                          surah.number,
                          selectedTranslation,
                        );
                    final revelationLabel =
                        surah.revelationType == RevelationPlaceEnum.meccan
                        ? localizations.meccan
                        : localizations.medinan;

                    return Container(
                      key: _keyForSurah(surah.number),
                      child: SurahCard(
                        surahNumber: surah.number,
                        translatedName: translatedName,
                        arabicName: surah.nameArabic,
                        versesLabel: '${surah.verseCount} ${localizations.verses}',
                        revelationLabel: revelationLabel,
                        revelationPlace: surah.revelationType,
                        isHighlighted: isCurrentSurah,
                        onTap: () => Navigator.pop(context, surah.number),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
