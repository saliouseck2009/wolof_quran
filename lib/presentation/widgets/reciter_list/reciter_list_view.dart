import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reciter.dart';
import '../../cubits/audio_availability_cubit.dart';
import 'reciter_list_header.dart';
import 'reciter_list_item.dart';

class ReciterListView extends StatelessWidget {
  const ReciterListView({
    super.key,
    required this.reciters,
    required this.selectedReciter,
    required this.onSelectReciter,
    required this.onOpenChapters,
    required this.onOpenUpdates,
  });

  final List<Reciter> reciters;
  final Reciter? selectedReciter;
  final ValueChanged<Reciter> onSelectReciter;
  final ValueChanged<Reciter> onOpenChapters;
  final ValueChanged<Reciter> onOpenUpdates;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioAvailabilityCubit, AudioAvailabilityState>(
      builder: (context, availabilityState) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: ReciterListHeader()),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final reciter = reciters[index];
                final isSelected = selectedReciter?.id == reciter.id;
                final unreadCount = availabilityState.unreadCountForReciter(
                  reciter.id,
                );

                return ReciterListItem(
                  reciter: reciter,
                  isSelected: isSelected,
                  unreadNewCount: unreadCount,
                  onSelect: () => onSelectReciter(reciter),
                  onOpenChapters: () => onOpenChapters(reciter),
                  onOpenUpdates: () => onOpenUpdates(reciter),
                );
              }, childCount: reciters.length),
            ),
          ],
        );
      },
    );
  }
}
