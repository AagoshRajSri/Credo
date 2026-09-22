import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/credit_score_snapshot.dart';

/// Phase 4 — Hero Moment #1: animated radial gauge.
///
/// Features:
/// - 270° arc drawn with a SweepGradient (violet → cyan)
/// - Spring animation: count-up from 300 → score with overshoot
/// - Glowing tip dot tracks the arc edge
/// - Haptic feedback fires at 85% of animation duration
/// - 6-month sparkline cross-fades in after animation settles
/// - RepaintBoundary isolates arc repaints from the widget tree
/// - Reduce-motion fallback: skips immediately to final state
class ScoreGauge extends StatefulWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.history,
  });

  final int score;
  final List<CreditScoreSnapshot> history;

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _gaugeAnim;
  late final Animation<double> _countAnim;

  bool _sparklineVisible = false;
  bool _hapticFired = false;

  static const double _minScore = 300.0;
  static const double _maxScore = 900.0;

  // DECISION: Cubic(0.34, 1.4, 0.64, 1.0) — a "tight spring" cubic.
  // Overshoots the target fraction by ~8%, then settles cleanly.
  // Feels intentionally designed without being distracting.
  static const Curve _springCurve = Cubic(0.34, 1.4, 0.64, 1.0);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _gaugeAnim = CurvedAnimation(
      parent: _controller,
      curve: _springCurve,
    );

    _countAnim = Tween<double>(
      begin: _minScore,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _controller.value = 1.0;
        setState(() => _sparklineVisible = true);
      } else {
        _controller.forward();
      }
    });
  }

  void _onTick() {
    if (!_hapticFired && _controller.value >= 0.85) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _sparklineVisible = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final label = creditScoreLabel(score);
    final color = creditScoreColor(score);
    final history = widget.history;

    int? delta;
    if (history.length >= 2) {
      delta = history.last.score - history[history.length - 2].score;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
        AppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CredoColors.surfaceVariant, CredoColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Score',
                style: context.textTheme.labelMedium
                    ?.copyWith(color: CredoColors.textSecondary),
              ),
              _ScoreChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),

          // ── Gauge arc (isolated paint boundary) ────────────────────
          Semantics(
            label: 'Credit Score',
            value: '${widget.score} out of 850. Status: $label.',
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final targetFraction =
                      (widget.score - _minScore) / (_maxScore - _minScore);
                  return _GaugeArc(
                    fraction: (_gaugeAnim.value * targetFraction),
                    displayScore: _countAnim.value.round(),
                    scoreColor: color,
                    label: label,
                  );
                },
              ),
            ),
          ),

          // ── Delta ──────────────────────────────────────────────────
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    delta >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 13,
                    color: delta >= 0 ? CredoColors.success : CredoColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${delta >= 0 ? '+' : ''}$delta from last month',
                    style: context.textTheme.bodySmall?.copyWith(
                      color:
                          delta >= 0 ? CredoColors.success : CredoColors.error,
                    ),
                  ),
                ],
              ),
            ),

          // ── Sparkline — cross-fades in after animation settles ─────
          if (history.length >= 2)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              opacity: _sparklineVisible ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                offset: _sparklineVisible ? Offset.zero : const Offset(0, 0.1),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingM),
                  child: ScoreSparkline(history: history, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Gauge arc widget ──────────────────────────────────────────────────────

class _GaugeArc extends StatelessWidget {
  const _GaugeArc({
    required this.fraction,
    required this.displayScore,
    required this.scoreColor,
    required this.label,
  });

  final double fraction;
  final int displayScore;
  final Color scoreColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: CustomPaint(
        painter: _GaugePainter(fraction: fraction, scoreColor: scoreColor),
        child: Align(
          alignment: const Alignment(0, 0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$displayScore',
                style: context.textTheme.displaySmall?.copyWith(
                  color: scoreColor,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: CredoColors.textSecondary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.fraction, required this.scoreColor});

  final double fraction;
  final Color scoreColor;

  // Gauge geometry constants
  static const double _strokeWidth = 13.0;
  // Start: 135° from right (lower-left, 7:30 o'clock)
  // Sweep: 270° clockwise → ends at lower-right (4:30 o'clock)
  // Gap at the bottom — classic speedometer look.
  static const double _startAngle = 135.0 * math.pi / 180.0;
  static const double _totalSweep = 270.0 * math.pi / 180.0;
  // Range labels: 300 – 900, ticks drawn at 0%, 50%, 100%

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final radius = math.min(size.width, size.height) / 2 -
        _strokeWidth / 2 -
        10;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // ── Track (background arc) ────────────────────────────────────
    final trackPaint = Paint()
      ..color = CredoColors.surfaceHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, _startAngle, _totalSweep, false, trackPaint);

    // ── Tick marks at 300 / 600 / 900 ────────────────────────────
    _drawTicks(canvas, center, radius);

    // ── Fill arc ──────────────────────────────────────────────────
    final clamped = fraction.clamp(0.0, 1.08); // allow slight overshoot
    if (clamped <= 0) return;

    final sweepAngle = _totalSweep * clamped;

    final fillPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _totalSweep,
        colors: [CredoColors.accentViolet, CredoColors.accentCyan],
        tileMode: TileMode.clamp,
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, _startAngle, sweepAngle, false, fillPaint);

    // ── Glowing tip dot ───────────────────────────────────────────
    final tipAngle = _startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    final tip = Offset(tipX, tipY);

    // Glow halo
    canvas.drawCircle(
      tip,
      _strokeWidth / 2 + 4,
      Paint()
        ..color = CredoColors.accentCyan.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Inner dot
    canvas.drawCircle(
      tip,
      _strokeWidth / 2 - 1,
      Paint()..color = Colors.white,
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    const tickFractions = [0.0, 0.5, 1.0]; // 300, 600, 900
    final tickPaint = Paint()
      ..color = CredoColors.textDisabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final f in tickFractions) {
      final angle = _startAngle + _totalSweep * f;
      final inner = radius - _strokeWidth;
      final outer = radius + _strokeWidth * 0.5;
      canvas.drawLine(
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Offset(
          center.dx + outer * math.cos(angle),
          center.dy + outer * math.sin(angle),
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.scoreColor != scoreColor;
}

// ── Score chip ─────────────────────────────────────────────────────────────

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Score sparkline ────────────────────────────────────────────────────────

/// 6-month credit score sparkline using fl_chart LineChart.
/// Shown only after the gauge animation completes.
class ScoreSparkline extends StatelessWidget {
  const ScoreSparkline({
    super.key,
    required this.history,
    required this.color,
  });

  final List<CreditScoreSnapshot> history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
        .toList();

    final yValues = spots.map((s) => s.y).toList();
    final minY = yValues.reduce(math.min) - 20;
    final maxY = yValues.reduce(math.max) + 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '6-month trend',
              style: context.textTheme.labelSmall
                  ?.copyWith(color: CredoColors.textTertiary),
            ),
            Row(
              children: [
                Icon(
                  history.last.score >= history.first.score
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 3),
                Text(
                  '${history.first.score} → ${history.last.score}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Line chart ────────────────────────────────────────────
        SizedBox(
          height: 60,
          child: RepaintBoundary(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (history.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: LinearGradient(
                      colors: [CredoColors.accentViolet, color],
                    ),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final isLast = index == history.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 4.5 : 2.0,
                          color: isLast ? color : CredoColors.textSecondary,
                          strokeWidth: isLast ? 2.0 : 0,
                          strokeColor: CredoColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.18),
                          color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // ── Month labels ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: history.map((s) {
            final isLast = s == history.last;
            return Text(
              DateFormat('MMM').format(s.date),
              style: context.textTheme.labelSmall?.copyWith(
                color: isLast ? color : CredoColors.textTertiary,
                fontSize: 9,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
