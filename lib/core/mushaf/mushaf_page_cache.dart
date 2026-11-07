import 'dart:async';

import 'mushaf_page_renderer.dart';

typedef MushafRenderFunction =
    Future<MushafPageRender> Function(MushafPageSpec spec);

/// Keeps the last rendered pages so a swipe back and forth never renders
/// twice, bounded because each image is a full-screen texture. Pages that
/// are on screen are retained and never evicted.
class MushafPageCache {
  MushafPageCache({this.capacity = 5, MushafRenderFunction? render})
    : _render = render ?? MushafPageRenderer.render;

  final int capacity;
  final MushafRenderFunction _render;
  final _renders = <MushafPageSpec, MushafPageRender>{};
  final _pending = <MushafPageSpec, Future<MushafPageRender>>{};
  final _retained = <MushafPageSpec, int>{};

  int get length => _renders.length;

  MushafPageRender? peek(MushafPageSpec spec) {
    final render = _renders.remove(spec);
    if (render != null) {
      _renders[spec] = render; // most recently used
    }
    return render;
  }

  Future<MushafPageRender> get(MushafPageSpec spec) {
    final cached = peek(spec);
    if (cached != null) {
      return Future.value(cached);
    }
    return _pending[spec] ??= _render(spec)
        .then((render) {
          _renders[spec] = render;
          _evict();
          return render;
        })
        .whenComplete(() {
          // A block body: returning the removed future would make the
          // chain wait for itself.
          _pending.remove(spec);
        });
  }

  /// Marks [spec] as displayed; a retained render survives eviction.
  void retain(MushafPageSpec spec) =>
      _retained[spec] = (_retained[spec] ?? 0) + 1;

  void release(MushafPageSpec spec) {
    final count = (_retained[spec] ?? 1) - 1;
    if (count <= 0) {
      _retained.remove(spec);
      _evict();
    } else {
      _retained[spec] = count;
    }
  }

  void _evict() {
    if (_renders.length <= capacity) {
      return;
    }
    for (final spec in _renders.keys.toList()) {
      if (_renders.length <= capacity) {
        break;
      }
      if (!_retained.containsKey(spec)) {
        _renders.remove(spec)?.dispose();
      }
    }
  }

  void clear() {
    for (final render in _renders.values) {
      render.dispose();
    }
    _renders.clear();
    _retained.clear();
  }
}
