import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/gradient_background.dart';

/// Phase 5 — Hero Moment #2: PIN unlock screen.
///
/// Features:
/// - 4 PIN dots: gradient-filled with spring scale on each tap
/// - Staggered entrance animation for dots + keypad rows
/// - Shake animation on wrong PIN + error haptic
/// - Correct PIN → dots glow, screen scales + fades out into dashboard
/// - Biometric button placeholder (icon only, non-functional)
/// - Reduce-motion fallback
///
/// DECISION: demo PIN is "1234". In production this would be a hashed
/// value stored in Hive (SecureStorage or flutter_secure_storage).
const String _kDemoPin = '1234';

class PinScreen extends StatelessWidget {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          GradientBackground(),
          SafeArea(child: _PinBody()),
        ],
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────

class _PinBody extends StatefulWidget {
  const _PinBody();

  @override
  State<_PinBody> createState() => _PinBodyState();
}

class _PinBodyState extends State<_PinBody> with TickerProviderStateMixin {
  final List<String> _entered = [];
  bool _isError = false;

  // Entrance stagger
  late final AnimationController _entranceController;
  // Shake on wrong PIN
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;
  // Exit (correct PIN)
  late final AnimationController _exitController;
  late final Animation<double> _exitScaleAnim;
  late final Animation<double> _exitOpacityAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Shake: translate left-right, decaying amplitude
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitScaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _entranceController.value = 1.0;
      } else {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shakeController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_exitController.isAnimating || _exitController.isCompleted) return;

    if (key == '⌫') {
      if (_entered.isNotEmpty) {
        HapticFeedback.lightImpact();
        setState(() {
          _entered.removeLast();
          _isError = false;
        });
      }
      return;
    }

    if (_entered.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _entered.add(key);
      _isError = false;
    });

    if (_entered.length == 4) {
      _evaluatePin();
    }
  }

  Future<void> _evaluatePin() async {
    final pin = _entered.join();
    await Future<void>.delayed(const Duration(milliseconds: 80)); // let last dot fill

    if (pin == _kDemoPin) {
      await _onCorrectPin();
    } else {
      await _onWrongPin();
    }
  }

  Future<void> _onCorrectPin() async {
    HapticFeedback.heavyImpact();
    // Exit animation — scale up + fade out
    await _exitController.forward();
    if (mounted) context.go('/home');
  }

  Future<void> _onWrongPin() async {
    HapticFeedback.vibrate();
    setState(() => _isError = true);
    await _shakeController.forward();
    _shakeController.reset();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      setState(() {
        _entered.clear();
        _isError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Transform.scale(
          scale: _exitScaleAnim.value,
          child: Opacity(
            opacity: _exitOpacityAnim.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          const Spacer(flex: 2),

          // ── Brand mark ─────────────────────────────────────────────
          _FadeSlideIn(
            controller: _entranceController,
            delay: 0.0,
            child: Column(
              children: [
                // Gradient logo text
                ShaderMask(
                  shaderCallback: (bounds) =>
                      CredoColors.accentGradient.createShader(bounds),
                  child: Text(
                    'credo',
                    style: context.textTheme.displaySmall?.copyWith(
                      color: Colors.white, // masked by shader
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your PIN',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: CredoColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ── PIN dots ────────────────────────────────────────────────
          _FadeSlideIn(
            controller: _entranceController,
            delay: 0.15,
            child: Semantics(
              label: 'PIN input: ${_entered.length} out of 4 digits entered.',
              value: _isError ? 'Incorrect PIN, try again.' : null,
              child: AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    context.reduceMotion ? 0.0 : _shakeOffset(_shakeAnim.value),
                    0,
                  ),
                  child: child,
                ),
                child: _PinDots(
                  filledCount: _entered.length,
                  isError: _isError,
                ),
              ),
            ),
          ),

          const Spacer(flex: 2),

          // ── Numeric keypad ──────────────────────────────────────────
          _NumericKeypad(
            entranceController: _entranceController,
            onKeyTap: _onKeyTap,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Decaying sinusoidal shake offset — 3 full oscillations, shrinking.
  double _shakeOffset(double t) {
    const amplitude = 18.0;
    const frequency = 3.0;
    return amplitude * (1 - t) * math.sin(frequency * t * math.pi * 2);
  }
}

// ── PIN dots row ──────────────────────────────────────────────────────────

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filledCount, required this.isError});

  final int filledCount;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final filled = i < filledCount;
        final isJustFilled = i == filledCount - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _PinDot(
            filled: filled,
            isError: isError,
            springIn: isJustFilled,
          ),
        );
      }),
    );
  }
}

class _PinDot extends StatefulWidget {
  const _PinDot({
    required this.filled,
    required this.isError,
    required this.springIn,
  });

  final bool filled;
  final bool isError;
  final bool springIn;

  @override
  State<_PinDot> createState() => _PinDotState();
}

class _PinDotState extends State<_PinDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Cubic(0.34, 1.56, 0.64, 1.0)),
    );
  }

  @override
  void didUpdateWidget(_PinDot old) {
    super.didUpdateWidget(old);
    if (widget.filled && !old.filled) {
      _ctrl.forward(from: 0);
    } else if (!widget.filled && old.filled) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const errorColor = CredoColors.error;
    final Color borderColor = widget.isError
        ? errorColor
        : widget.filled
            ? CredoColors.accentViolet
            : CredoColors.textSecondary;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            // Error: solid red. Filled: nothing (we draw gradient inside).
            color: widget.isError && widget.filled
                ? errorColor.withValues(alpha: 0.3)
                : Colors.transparent,
            boxShadow: widget.filled && !widget.isError
                ? [
                    BoxShadow(
                      color: CredoColors.accentViolet.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: widget.filled && !widget.isError
              ? Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: CredoColors.accentGradient,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ── Numeric keypad ────────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.entranceController,
    required this.onKeyTap,
  });

  final AnimationController entranceController;
  final ValueChanged<String> onKeyTap;

  static const List<String> _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '🔒', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: List.generate(4, (row) {
          final rowDelay = 0.25 + row * 0.1;
          return _FadeSlideIn(
            controller: entranceController,
            delay: rowDelay,
            slideFrom: const Offset(0, 0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (col) {
                  final index = row * 3 + col;
                  final key = _keys[index];
                  return _KeyButton(
                    label: key,
                    onTap: () => onKeyTap(key),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    if (label == '🔒') {
      // Biometric placeholder — non-functional in Phase 5
      return Semantics(
        label: 'Biometric Login',
        button: true,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Biometric auth coming soon'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Icon(
                Icons.fingerprint_rounded,
                color: CredoColors.textSecondary,
                size: 30,
              ),
            ),
          ),
        ),
      );
    }

    if (label == '⌫') {
      return Semantics(
        label: 'Delete',
        button: true,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const Icon(
                Icons.backspace_outlined,
                color: CredoColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: CredoColors.surfaceVariant,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: CredoColors.accentViolet.withValues(alpha: 0.15),
          highlightColor: CredoColors.accentViolet.withValues(alpha: 0.08),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: CredoColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Entrance animation helper ─────────────────────────────────────────────

/// Fades and slides a child in using a [delay] fraction within [controller].
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.controller,
    required this.delay,
    required this.child,
    this.slideFrom = const Offset(0, 0.5),
  });

  final AnimationController controller;
  final double delay;
  final Widget child;
  final Offset slideFrom;

  @override
  Widget build(BuildContext context) {
    final interval = Interval(
      delay.clamp(0.0, 0.9),
      (delay + 0.35).clamp(0.1, 1.0),
      curve: Curves.easeOut,
    );
    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: interval),
    );
    final slide = Tween<Offset>(begin: slideFrom, end: Offset.zero).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.clamp(0.0, 0.9),
          (delay + 0.35).clamp(0.1, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => FadeTransition(
        opacity: opacity,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      ),
      child: child,
    );
  }
}
