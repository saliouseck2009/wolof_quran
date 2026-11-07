import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter/services.dart';

import '../../../core/mushaf/quran_page_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'surah_picker_sheet.dart';

/// Number field for a mushaf page: a label above, the page in large digits,
/// a button opening the surah picker and the juz and surah of that page as
/// helper text below.
class PagePickerField extends StatefulWidget {
  final String label;
  final int? value;
  final int totalPages;
  final ValueChanged<int?> onChanged;
  final bool autofocus;

  const PagePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.totalPages,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<PagePickerField> createState() => _PagePickerFieldState();
}

class _PagePickerFieldState extends State<PagePickerField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void didUpdateWidget(covariant PagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value?.toString() ?? '';
    if (widget.value != oldWidget.value && _controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid =>
      widget.value != null &&
      widget.value! >= 1 &&
      widget.value! <= widget.totalPages;

  Future<void> _pickSurah() async {
    final surahNumber = await showSurahPickerSheet(
      context,
      selectedSurah: _isValid
          ? getPageInfo(widget.value!).primarySurahNumber
          : null,
    );
    if (surahNumber == null || !mounted) {
      return;
    }
    final page = getFirstPageOfSurah(surahNumber);
    _controller.text = '$page';
    widget.onChanged(page);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final value = widget.value;
    final hasError = !_isValid && _controller.text.isNotEmpty;
    final String? helper;
    if (_isValid) {
      final info = getPageInfo(value!);
      helper =
          '${localizations.juzLabel(info.juzNumber)} · ${quran.getSurahName(info.primarySurahNumber)}';
    } else if (hasError) {
      helper = localizations.invalidPage(widget.totalPages);
    } else {
      helper = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: (text) => widget.onChanged(int.tryParse(text)),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '1',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: hasError
                  ? BorderSide(color: colorScheme.error, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? colorScheme.error : colorScheme.primary,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              tooltip: localizations.chooseSurah,
              icon: Icon(
                Icons.bookmark_border_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: _pickSurah,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasError
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
