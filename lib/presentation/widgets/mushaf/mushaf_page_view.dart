import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../../core/mushaf/mushaf_page_cache.dart';
import '../../../core/mushaf/mushaf_page_renderer.dart';

typedef MushafVerseCallback = void Function(int surahNumber, int verseNumber);

/// Swipeable mushaf, one page per screen.
///
/// Each page is rendered once into a GPU image by [MushafPageRenderer]
/// (text shaping, stretching and tajweed colouring included), so a swipe
/// only translates two textures. The previous and next pages are rendered
/// ahead of the swipe and a few more are kept in [MushafPageCache].
class MushafPageView extends StatefulWidget {
  final PageController controller;
  final ValueChanged<int>? onPageChanged;
  final MushafVerseCallback? onLongPress;
  final Color pageBackgroundColor;
  final Color verseColor;
  final Color accentColor;
  final bool isDark;
  final bool isTajweed;

  const MushafPageView({
    super.key,
    required this.controller,
    required this.pageBackgroundColor,
    required this.verseColor,
    required this.accentColor,
    required this.isDark,
    required this.isTajweed,
    this.onPageChanged,
    this.onLongPress,
  });

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  final _cache = MushafPageCache();

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }

  MushafPageSpec _specFor(int page, Size size, double devicePixelRatio) {
    final orientation = size.width > size.height
        ? Orientation.landscape
        : Orientation.portrait;
    return MushafPageSpec(
      page: page,
      // In landscape the page keeps its portrait proportions and scrolls.
      size: orientation == Orientation.portrait
          ? size
          : Size(size.width, size.width),
      devicePixelRatio: devicePixelRatio,
      backgroundColor: widget.pageBackgroundColor,
      verseColor: widget.verseColor,
      accentColor: widget.accentColor,
      isDark: widget.isDark,
      isTajweed: widget.isTajweed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: widget.pageBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return PageView.builder(
              controller: widget.controller,
              // Builds, hence renders, the previous and next pages ahead.
              allowImplicitScrolling: true,
              itemCount: totalPagesCount,
              onPageChanged: (index) => widget.onPageChanged?.call(index + 1),
              itemBuilder: (context, index) => _MushafPage(
                key: ValueKey('mushaf_page_${index + 1}'),
                cache: _cache,
                controller: widget.controller,
                spec: _specFor(index + 1, size, devicePixelRatio),
                onLongPress: widget.onLongPress,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One page: blank until rendered, then a single image.
///
/// The previous and next pages are built by the PageView ahead of the
/// swipe; their rendering waits for the scroll to settle so the raster
/// thread is free during the animation.
class _MushafPage extends StatefulWidget {
  final MushafPageCache cache;
  final PageController controller;
  final MushafPageSpec spec;
  final MushafVerseCallback? onLongPress;

  const _MushafPage({
    super.key,
    required this.cache,
    required this.controller,
    required this.spec,
    required this.onLongPress,
  });

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  MushafPageRender? _render;

  @override
  void initState() {
    super.initState();
    widget.cache.retain(widget.spec);
    _load();
  }

  @override
  void didUpdateWidget(covariant _MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec != widget.spec) {
      _scrolling?.removeListener(_onScrollIdle);
      _scrolling = null;
      _render = null;
      widget.cache.retain(widget.spec);
      _load();
      oldWidget.cache.release(oldWidget.spec);
    }
  }

  ValueListenable<bool>? _scrolling;

  void _load() {
    final spec = widget.spec;
    final cached = widget.cache.peek(spec);
    if (cached != null) {
      _render = cached;
      return;
    }
    final scrolling = widget.controller.hasClients
        ? widget.controller.position.isScrollingNotifier
        : null;
    if (scrolling != null && scrolling.value) {
      _scrolling = scrolling..addListener(_onScrollIdle);
      return;
    }
    _startRender(spec);
  }

  void _onScrollIdle() {
    final scrolling = _scrolling;
    if (scrolling == null || scrolling.value) {
      return;
    }
    scrolling.removeListener(_onScrollIdle);
    _scrolling = null;
    if (mounted) {
      _startRender(widget.spec);
    }
  }

  void _startRender(MushafPageSpec spec) {
    widget.cache.get(spec).then((render) {
      if (mounted && widget.spec == spec) {
        setState(() => _render = render);
      }
    });
  }

  @override
  void dispose() {
    _scrolling?.removeListener(_onScrollIdle);
    widget.cache.release(widget.spec);
    super.dispose();
  }

  void _onLongPress(LongPressStartDetails details) {
    final verse = _render?.verseAt(details.localPosition);
    if (verse != null) {
      widget.onLongPress?.call(verse.$1, verse.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final render = _render;
    if (render == null) {
      return const SizedBox.expand();
    }
    final page = GestureDetector(
      onLongPressStart: widget.onLongPress == null ? null : _onLongPress,
      child: RawImage(
        image: render.image,
        width: widget.spec.size.width,
        height: widget.spec.size.height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
    final viewportHeight = MediaQuery.sizeOf(context).height;
    return widget.spec.size.height > viewportHeight
        ? SingleChildScrollView(child: page)
        : page;
  }
}
