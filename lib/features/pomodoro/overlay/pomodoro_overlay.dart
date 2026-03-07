import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — MUST be a top-level function with @pragma annotation.
// Flutter compiles this as a secondary entry point for the overlay isolate.
// Import this file in main.dart so the tree-shaker keeps it alive.
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _OverlayApp());
}

class _OverlayApp extends StatelessWidget {
  const _OverlayApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // No theme engine here — we use hard-coded AppTheme constants
      // (the overlay isolate has no access to ThemeNotifier / Riverpod)
      home: const PomodoroOverlayWidget(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message protocol (JSON strings over FlutterOverlayWindow.shareData)
//
//  App → Overlay:
//    { "type": "state", "secondsLeft": 1234, "phase": "work",
//      "isRunning": true, "taskName": "Math exam" }
//
//  Overlay → App:
//    { "type": "action", "action": "play_pause" }
//    { "type": "action", "action": "open_app"   }
// ─────────────────────────────────────────────────────────────────────────────

// ── Hard-coded theme colours (mirrors AppTheme static constants) ──────────────
const _bg        = Color(0xFF1C1C1A);
const _surface   = Color(0xFF242422);
const _border    = Color(0xFF30302E);
const _primary   = Color(0xFF4A7C59);
const _breakClr  = Color(0xFF5A7A9E);
const _txtPrim   = Color(0xFFF0EBE1);
const _txtSec    = Color(0xFFA89F94);

// ─────────────────────────────────────────────────────────────────────────────
// Overlay Widget
// ─────────────────────────────────────────────────────────────────────────────

class PomodoroOverlayWidget extends StatefulWidget {
  const PomodoroOverlayWidget({super.key});

  @override
  State<PomodoroOverlayWidget> createState() => _PomodoroOverlayWidgetState();
}

class _PomodoroOverlayWidgetState extends State<PomodoroOverlayWidget>
    with SingleTickerProviderStateMixin {

  // ── Timer state (populated from incoming messages) ─────────────────────────
  int     _secondsLeft = 25 * 60;
  String  _phase       = 'work';
  bool    _isRunning   = false;
  String? _taskName;

  // ── Subtle pulse animation while running ───────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Listen for state pushes from the main app
    _sub = FlutterOverlayWindow.overlayListener.listen(_onData);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _onData(dynamic raw) {
    if (raw == null) return;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      if (map['type'] == 'state') {
        setState(() {
          _secondsLeft = (map['secondsLeft'] as int?) ?? _secondsLeft;
          _phase       = (map['phase']       as String?) ?? _phase;
          _isRunning   = (map['isRunning']   as bool?)   ?? _isRunning;
          _taskName    = map['taskName'] as String?;
        });
        // Drive pulse based on running state
        if (_isRunning && !_pulseCtrl.isAnimating) {
          _pulseCtrl.repeat(reverse: true);
        } else if (!_isRunning) {
          _pulseCtrl.stop();
        }
      }
    } catch (_) {
      // Malformed message — ignore
    }
  }

  void _sendAction(String action) {
    HapticFeedback.lightImpact();
    FlutterOverlayWindow.shareData(jsonEncode({
      'type'  : 'action',
      'action': action,
    }));
  }

  // ── Derived helpers ────────────────────────────────────────────────────────

  String get _fmt {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _phaseColor => _phase == 'work' ? _primary : _breakClr;

  String get _phaseLabel => switch (_phase) {
    'work'       => 'Focus',
    'shortBreak' => 'Short Break',
    'longBreak'  => 'Long Break',
    _            => 'Focus',
  };

  // NOTE: The overlay doesn't know the configured durations (it has no
  // access to PomodoroSettings). We use the standard defaults for the
  // ring progress calculation — accurate enough for a visual indicator.
  double get _progress {
    final total = switch (_phase) {
      'shortBreak' => 5  * 60,
      'longBreak'  => 15 * 60,
      _            => 25 * 60,
    };
    return (_secondsLeft / total).clamp(0.0, 1.0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: _isRunning ? _pulse.value : 1.0,
          child: GestureDetector(
            // Tapping the widget body → bring app to foreground
            onTap: () => _sendAction('open_app'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(110),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Ring + time ──────────────────────────────
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(52, 52),
                          painter: _MiniRingPainter(
                            progress : _progress,
                            ringColor: _phaseColor,
                            bgColor  : _surface,
                          ),
                        ),
                        Text(
                          _fmt,
                          style: GoogleFonts.poppins(
                            fontSize      : 10.5,
                            fontWeight    : FontWeight.w700,
                            color         : _txtPrim,
                            letterSpacing : -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Phase + task name ────────────────────────
                  Column(
                    mainAxisSize       : MainAxisSize.min,
                    crossAxisAlignment : CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phaseLabel,
                        style: GoogleFonts.poppins(
                          fontSize  : 12,
                          fontWeight: FontWeight.w600,
                          color     : _phaseColor,
                        ),
                      ),
                      SizedBox(
                        width: 108,
                        child: Text(
                          _taskName ?? 'Free session',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color   : _txtSec,
                          ),
                          maxLines : 1,
                          overflow : TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  // ── Play / Pause button ──────────────────────
                  GestureDetector(
                    onTap: () => _sendAction('play_pause'),
                    child: Container(
                      width : 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color : _phaseColor.withAlpha(45),
                        shape : BoxShape.circle,
                        border: Border.all(
                          color: _phaseColor.withAlpha(90),
                        ),
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _phaseColor,
                        size : 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Ring Painter
// ─────────────────────────────────────────────────────────────────────────────

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color  ringColor;
  final Color  bgColor;

  const _MiniRingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  static const _stroke = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = _stroke / 2;
    final rect  = Rect.fromLTWH(inset, inset, size.width - _stroke, size.height - _stroke);

    // Background track
    canvas.drawArc(
      rect, -1.5708, 6.2832, false,
      Paint()
        ..color      = bgColor
        ..strokeWidth = _stroke
        ..style      = PaintingStyle.stroke
        ..strokeCap  = StrokeCap.round,
    );

    // Progress arc (drawn clockwise from top)
    if (progress > 0) {
      canvas.drawArc(
        rect, -1.5708, 6.2832 * progress, false,
        Paint()
          ..color      = ringColor
          ..strokeWidth = _stroke
          ..style      = PaintingStyle.stroke
          ..strokeCap  = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}