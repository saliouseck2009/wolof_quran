import 'package:flutter/widgets.dart';

/// Notifies [RouteAware] subscribers when any modal route (page or sheet)
/// is pushed above or popped from theirs. Registered in `MaterialApp`.
final RouteObserver<ModalRoute<dynamic>> modalRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();
