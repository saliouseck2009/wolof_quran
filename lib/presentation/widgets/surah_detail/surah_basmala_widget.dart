import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class SurahBasmalaWidget extends StatelessWidget {
  const SurahBasmalaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          quran.basmala,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Hafs',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
