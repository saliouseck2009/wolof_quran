import 'package:flutter/material.dart';

class ChapterNumberWidget extends StatelessWidget {
  const ChapterNumberWidget({
    super.key,
    required this.color,
    required this.surahNumber,
    required this.textTheme,
  });

  final Color color;
  final int surahNumber;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Text(
          '$surahNumber',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
