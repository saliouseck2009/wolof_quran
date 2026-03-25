import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import '../blocs/mushaf/mushaf_surah_list_bloc.dart';

class MushafSurahPickerPage extends StatelessWidget {
  const MushafSurahPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MushafSurahListBloc()..add(const MushafSurahListLoaded()),
      child: const _MushafSurahPickerView(),
    );
  }
}

class _MushafSurahPickerView extends StatelessWidget {
  const _MushafSurahPickerView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.selectSurah)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: localizations.searchSurah,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                context.read<MushafSurahListBloc>().add(
                  MushafSurahSearchChanged(value),
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<MushafSurahListBloc, MushafSurahListState>(
              builder: (context, state) {
                final surahs = state.filteredSurahs;
                if (surahs.isEmpty) {
                  return Center(child: Text(localizations.noSurahFound));
                }

                return ListView.separated(
                  itemCount: surahs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${surah.number}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        surah.nameArabic,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${surah.nameEnglish} - ${surah.verseCount} ${localizations.verses}',
                      ),
                      trailing: Text(
                        surah.revelationType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, surah.number),
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
