import 'package:flutter/material.dart';

/// Tracks whether any modal route (dialogs, popovers, bottom sheets) is currently
/// active above the base application route.
///
/// Used especially on platforms like Linux desktop where native GTK WebKit overlays
/// must be temporarily hidden while modal Flutter widgets are displayed.
class ModalOverlayTracker extends NavigatorObserver {
  static final ModalOverlayTracker instance = ModalOverlayTracker._();

  ModalOverlayTracker._();

  factory ModalOverlayTracker() => instance;

  int _modalRouteCount = 0;
  final ValueNotifier<bool> hasModalRoute = ValueNotifier<bool>(false);

  bool _isPopup(Route<dynamic> route) => route is PopupRoute;

  /// Resets modal count (useful for testing and initial routing).
  void reset() {
    _modalRouteCount = 0;
    _update();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute == null) {
      _modalRouteCount = 0;
      _update();
      return;
    }
    if (_isPopup(route)) {
      _modalRouteCount++;
      _update();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_isPopup(route)) {
      _modalRouteCount = (_modalRouteCount - 1).clamp(0, 9999);
      _update();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (_isPopup(route)) {
      _modalRouteCount = (_modalRouteCount - 1).clamp(0, 9999);
      _update();
    }
  }

  void _update() {
    final hasModal = _modalRouteCount > 0;
    if (hasModalRoute.value != hasModal) {
      hasModalRoute.value = hasModal;
    }
  }
}
