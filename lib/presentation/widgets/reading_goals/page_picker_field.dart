import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter/services.dart';

import '../../../core/mushaf/quran_page_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'surah_picker_sheet.dart';

/// Number field for a mushaf page, with the surah and juz of that page as
/// helper text and a button to jump to the first page of a surah.
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
    final surahNumber = await showSurahPickerSheet(context);
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
    final colorScheme = Theme.of(context).colorScheme;
    final value = widget.value;
    final String? helper;
    if (_isValid) {
      final info = getPageInfo(value!);
      helper =
          '${localizations.juzLabel(info.juzNumber)} · ${quran.getSurahName(info.primarySurahNumber)}';
    } else if (_controller.text.isEmpty) {
      helper = null;
    } else {
      helper = localizations.invalidPage(widget.totalPages);
    }

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (text) => widget.onChanged(int.tryParse(text)),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: helper,
        helperMaxLines: 1,
        errorText: _isValid || _controller.text.isEmpty
            ? null
            : localizations.invalidPage(widget.totalPages),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          tooltip: localizations.chooseSurah,
          icon: const Icon(Icons.menu_book_rounded),
          onPressed: _pickSurah,
        ),
      ),
    );
  }
}
