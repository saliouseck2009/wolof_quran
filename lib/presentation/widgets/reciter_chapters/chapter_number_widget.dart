import 'package:flutter/material.dart';

class ChapterNumberWidget extends StatelessWidget {
  const ChapterNumberWidget({
    super.key,
    required this.color,
    required this.surahNumber,
    required this.textTheme,
    required this.backgroundColor,
  });

  final Color color;
  final int surahNumber;
  final TextTheme textTheme;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
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
