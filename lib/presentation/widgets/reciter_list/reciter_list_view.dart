import 'package:flutter/material.dart';

import '../../../domain/entities/reciter.dart';
import 'reciter_list_header.dart';
import 'reciter_list_item.dart';

class ReciterListView extends StatelessWidget {
  const ReciterListView({
    super.key,
    required this.reciters,
    required this.selectedReciter,
    required this.onSelectReciter,
    required this.onOpenChapters,
  });

  final List<Reciter> reciters;
  final Reciter? selectedReciter;
  final ValueChanged<Reciter> onSelectReciter;
  final ValueChanged<Reciter> onOpenChapters;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: ReciterListHeader()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
            final reciter = reciters[index];
            final isSelected = selectedReciter?.id == reciter.id;

            return ReciterListItem(
              reciter: reciter,
              isSelected: isSelected,
              onSelect: () => onSelectReciter(reciter),
              onOpenChapters: () => onOpenChapters(reciter),
            );
            },
            childCount: reciters.length,
          ),
        ),
      ],
    );
  }
}
