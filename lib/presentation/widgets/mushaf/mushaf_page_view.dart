import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/mushaf/mushaf_page_cache.dart';
import '../../../core/mushaf/mushaf_page_renderer.dart';

typedef MushafVerseCallback = void Function(int surahNumber, int verseNumber);

/// How the pages are laid out in the space given to the mushaf.
enum MushafLayout {
  /// One page that fits the viewport: phones and tablets in portrait.
  single,

  /// One page as wide as the viewport, scrolling vertically: a phone
  /// held in landscape, too short to show a whole page.
  scrolling,

  /// Two facing pages, like an open mushaf: tablets in landscape.
  spread;

  /// A glyph keeps its natural proportions when a page is about this
  /// wide for its height; wider than that, the lines are stretched.
  static const double pageAspectRatio = 0.72;

  /// Below this height two facing pages have lines too thin to read.
  static const double minSpreadHeight = 480;

  static MushafLayout of(Size viewport) {
    if (viewport.width <= viewport.height) {
      return MushafLayout.single;
    }
    if (viewport.width >= Breakpoints.expanded &&
        viewport.height >= minSpreadHeight) {
      return MushafLayout.spread;
    }
    return MushafLayout.scrolling;
  }

  /// Logical size of one rendered page in a [viewport].
  Size pageSize(Size viewport) {
    switch (this) {
      case MushafLayout.single:
        final width = viewport.height * pageAspectRatio;
        return Size(
          width < viewport.width ? width : viewport.width,
          viewport.height,
        );
      case MushafLayout.scrolling:
        // The page keeps portrait proportions and scrolls.
        return Size(viewport.width, viewport.width);
      case MushafLayout.spread:
        final half = (viewport.width - MushafPageView.spineWidth) / 2;
        final width = viewport.height * pageAspectRatio;
        return Size(width < half ? width : half, viewport.height);
    }
  }

  int get pagesPerView => this == MushafLayout.spread ? 2 : 1;

  /// Index, in the swipeable view, of the screen showing [page].
  int indexOf(int page) => (page - 1) ~/ pagesPerView;

  /// Pages shown at [index], in reading order.
  List<int> pagesAt(int index) => [
    for (var i = 0; i < pagesPerView; i++) index * pagesPerView + i + 1,
  ];
}

/// Drives a [MushafPageView] in page numbers, whatever its layout.
///
/// [page] is the page being read; [visiblePages] also holds the facing
/// page when two are shown. Listeners are told when either changes.
class MushafViewController extends ChangeNotifier {
  MushafViewController({required int initialPage})
    : _page = initialPage,
      _visiblePages = [initialPage];

  int _page;
  List<int> _visiblePages;
  void Function(int page)? _jump;

  int get page => _page;

  /// The pages on screen, in reading order.
  List<int> get visiblePages => List.unmodifiable(_visiblePages);

  /// The visible pages other than [page].
  List<int> get facingPages => [
    for (final visible in _visiblePages)
      if (visible != _page) visible,
  ];

  void jumpToPage(int page) {
    final jump = _jump;
    if (jump == null) {
      _page = page;
      _visiblePages = [page];
      return;
    }
    jump(page);
  }

  void _update(int page, List<int> visiblePages) {
    if (page == _page && listEquals(visiblePages, _visiblePages)) {
      return;
    }
    _page = page;
    _visiblePages = visiblePages;
    notifyListeners();
  }
}

/// Swipeable mushaf: one page per screen, or two facing pages on a
/// tablet in landscape (see [MushafLayout]).
///
/// Each page is rendered once into a GPU image by [MushafPageRenderer]
/// (text shaping, stretching and tajweed colouring included), so a swipe
/// only translates textures. The previous and next screens are rendered
/// ahead of the swipe and a few more pages are kept in [MushafPageCache].
class MushafPageView extends StatefulWidget {
  /// Gap between two facing pages, with the fold line in its middle.
  static const double spineWidth = 17;

  final MushafViewController controller;

  /// Called with the page being read when a swipe or a jump changes it.
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

  /// The swipe controller of the current layout: its index counts pages
  /// or spreads, so it is replaced when the layout changes.
  PageController? _pageController;
  MushafLayout? _layout;

  @override
  void initState() {
    super.initState();
    widget.controller._jump = _jumpToPage;
  }

  @override
  void didUpdateWidget(covariant MushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._jump = null;
      widget.controller._jump = _jumpToPage;
    }
  }

  @override
  void dispose() {
    widget.controller._jump = null;
    _pageController?.dispose();
    _cache.clear();
    super.dispose();
  }

  /// The swipe controller for [layout], opened on the page being read.
  PageController _controllerFor(MushafLayout layout) {
    final current = _pageController;
    if (current != null && _layout == layout) {
      return current;
    }
    final page = widget.controller.page;
    final index = layout.indexOf(page);
    _layout = layout;
    final created = _pageController = PageController(initialPage: index);
    // Rotating keeps the page being read; only its neighbour changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      current?.dispose();
      if (mounted && _layout == layout) {
        widget.controller._update(page, layout.pagesAt(index));
      }
    });
    return created;
  }

  void _jumpToPage(int page) {
    final layout = _layout;
    final pageController = _pageController;
    if (layout == null || pageController == null) {
      widget.controller._update(page, [page]);
      return;
    }
    final index = layout.indexOf(page);
    // Set first: the swipe callback then sees the target is on screen
    // and keeps it, instead of falling back to the first page shown.
    widget.controller._update(page, layout.pagesAt(index));
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
    }
  }

  void _onIndexChanged(int index) {
    final layout = _layout;
    if (layout == null) {
      return;
    }
    final pages = layout.pagesAt(index);
    final current = widget.controller.page;
    final page = pages.contains(current) ? current : pages.first;
    widget.controller._update(page, pages);
    widget.onPageChanged?.call(page);
  }

  MushafPageSpec _specFor(int page, Size size, double devicePixelRatio) {
    return MushafPageSpec(
      page: page,
      size: size,
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
            final viewport = constraints.biggest;
            final layout = MushafLayout.of(viewport);
            final pageSize = layout.pageSize(viewport);
            final pageController = _controllerFor(layout);

            Widget pageAt(int page) => _MushafPage(
              key: ValueKey('mushaf_page_$page'),
              cache: _cache,
              controller: pageController,
              spec: _specFor(page, pageSize, devicePixelRatio),
              scrolls: layout == MushafLayout.scrolling,
              onLongPress: widget.onLongPress,
            );

            return PageView.builder(
              // A new layout counts its screens differently.
              key: ValueKey(layout),
              controller: pageController,
              // Builds, hence renders, the previous and next screens ahead.
              allowImplicitScrolling: true,
              itemCount: (totalPagesCount / layout.pagesPerView).ceil(),
              onPageChanged: _onIndexChanged,
              itemBuilder: (context, index) {
                final pages = layout.pagesAt(index);
                if (pages.length == 1) {
                  return Center(
                    child: SizedBox(
                      width: pageSize.width,
                      child: pageAt(pages.single),
                    ),
                  );
                }
                // Right to left, like the book: the first page of the
                // spread is on the right.
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: pageSize.width, child: pageAt(pages[0])),
                    _Spine(color: widget.verseColor),
                    if (pages[1] <= totalPagesCount)
                      SizedBox(width: pageSize.width, child: pageAt(pages[1]))
                    else
                      SizedBox(width: pageSize.width),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The fold between two facing pages.
class _Spine extends StatelessWidget {
  final Color color;

  const _Spine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MushafPageView.spineWidth,
      child: Center(
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: ColoredBox(
            color: color.withValues(alpha: 0.12),
            child: const SizedBox(width: 1),
          ),
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

  /// Whether the page is taller than the viewport and scrolls.
  final bool scrolls;
  final MushafVerseCallback? onLongPress;

  const _MushafPage({
    super.key,
    required this.cache,
    required this.controller,
    required this.spec,
    required this.scrolls,
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
    return widget.scrolls ? SingleChildScrollView(child: page) : page;
  }
}
