import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OverlayService
//
// Singleton that owns all interaction with flutter_overlay_window.
// Called from:
//   - MainShell  (lifecycle: show/hide, action listener, state pushes)
//   - PomodoroNotifier (state pushes on each tick / pause / resume)
//
// Keep all FlutterOverlayWindow calls here so the rest of the codebase
// never touches the plugin directly.
// ─────────────────────────────────────────────────────────────────────────────

class OverlayService {
  OverlayService._();
  static final OverlayService instance = OverlayService._();

  // ── Internal state ─────────────────────────────────────────────────────────
  bool    _visible      = false;
  String? _cachedTask;             // task name set by MainShell when taskId changes

  // ── Permission ─────────────────────────────────────────────────────────────

  /// Requests "Draw over other apps" permission on Android.
  /// Safe to call multiple times — no-ops if already granted.
  Future<bool> requestPermission() async {
    try {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      if (granted) return true;
      await FlutterOverlayWindow.requestPermission();
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('[OverlayService] requestPermission error: $e');
      return false;
    }
  }

  Future<bool> get isPermissionGranted async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  // ── Show / Hide ────────────────────────────────────────────────────────────

  /// Shows the overlay if not already visible.
  /// Must be called after [requestPermission] returns true.
  Future<void> show() async {
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (active) { _visible = true; return; }

      await FlutterOverlayWindow.showOverlay(
        height           : 78,
        width            : 268,
        alignment        : OverlayAlignment.topCenter,
        positionGravity  : PositionGravity.auto,
        enableDrag       : true,        // user can drag it around
        flag             : OverlayFlag.defaultFlag,
        overlayTitle     : 'Pomodoro Timer',
        overlayContent   : 'Timer running in background',
        visibility       : NotificationVisibility.visibilityPublic,
      );
      _visible = true;
    } catch (e) {
      debugPrint('[OverlayService] show error: $e');
    }
  }

  /// Closes the overlay if currently visible.
  Future<void> hide() async {
    if (!_visible) return;
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (active) await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('[OverlayService] hide error: $e');
    } finally {
      _visible = false;
    }
  }

  // ── Task name cache ────────────────────────────────────────────────────────

  /// Call this whenever the attached task name changes so the overlay shows
  /// the correct task name without the overlay needing DB access.
  void setTaskName(String? name) => _cachedTask = name;

  // ── State push ─────────────────────────────────────────────────────────────

  /// Sends current timer state to the overlay widget.
  /// No-ops silently if the overlay is not active.
  Future<void> pushState({
    required int    secondsLeft,
    required String phase,
    required bool   isRunning,
    String?         taskName,     // optional override; falls back to cached name
  }) async {
    if (!_visible) return;
    try {
      final active = await FlutterOverlayWindow.isActive();
      if (!active) { _visible = false; return; }

      await FlutterOverlayWindow.shareData(jsonEncode({
        'type'       : 'state',
        'secondsLeft': secondsLeft,
        'phase'      : phase,
        'isRunning'  : isRunning,
        'taskName'   : taskName ?? _cachedTask,
      }));
    } catch (e) {
      debugPrint('[OverlayService] pushState error: $e');
    }
  }

  // ── Action stream ──────────────────────────────────────────────────────────

  /// Emits action maps sent FROM the overlay widget TO the main app.
  /// Listen in MainShell to handle 'play_pause' and 'open_app' actions.
  ///
  /// Emitted objects:  { 'type': 'action', 'action': 'play_pause' }
  ///                   { 'type': 'action', 'action': 'open_app'   }
  Stream<Map<String, dynamic>> get actionStream {
    return FlutterOverlayWindow.overlayListener
        .where((raw) => raw != null)
        .map<Map<String, dynamic>>((raw) {
      try {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        return map['type'] == 'action' ? map : {};
      } catch (_) {
        return {};
      }
    }).where((map) => map.isNotEmpty);
  }

  bool get isVisible => _visible;
}