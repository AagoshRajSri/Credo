import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';

/// Phase 7 — Custom morphing pill bottom nav bar.
///
/// Features:
/// - Gradient pill (violet → cyan) that spring-slides between tabs
/// - Glass-morphic surface (BackdropFilter blur + border)
/// - Icon-only unselected, icon + label selected (AnimatedCrossFade)
/// - Tap: lightImpact haptic + scale press feedback
/// - Spring curve: easeOutBack — single controlled overshoot
/// - Floating layout via bottomNavigationBar padding
class CredoNavBar extends StatefulWidget {
  const CredoNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  // DECISION: tabs defined here, not in _AppShell, so the bar is self-contained.
  static const List<NavTabData> tabs = [
    NavTabData(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    NavTabData(
      label: 'Accounts',
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card_rounded,
    ),
    NavTabData(
      label: 'Analytics',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    NavTabData(
      label: 'Activity',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
  ];

  @override
  State<CredoNavBar> createState() => _CredoNavBarState();
}

class _CredoNavBarState extends State<CredoNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _pillAnim;

  static const double _barH = 62.0;
  static const double _pillH = 44.0;
  static const double _pillHPad = 5.0; // inset from cell edge

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _pillAnim = AlwaysStoppedAnimation(widget.selectedIndex.toDouble());
  }

  @override
  void didUpdateWidget(CredoNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      final from = _pillAnim.value;
      _pillAnim = Tween<double>(
        begin: from,
        end: widget.selectedIndex.toDouble(),
      ).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = CredoNavBar.tabs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final tabW = totalW / tabs.length;

        return SizedBox(
          height: _barH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Glass background ────────────────────────────────
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CredoColors.surface.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusFull,
                        ),
                        border: Border.all(
                          color: CredoColors.glassBorderStart,
                          width: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Animated gradient pill ──────────────────────────
              AnimatedBuilder(
                animation: _pillAnim,
                builder: (_, __) {
                  final left = _pillAnim.value * tabW + _pillHPad;
                  return Positioned(
                    left: left,
                    top: (_barH - _pillH) / 2,
                    width: tabW - _pillHPad * 2,
                    height: _pillH,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: CredoColors.accentGradient,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: CredoColors.accentViolet
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Tab items ───────────────────────────────────────
              Row(
                children: tabs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tab = entry.value;
                  final selected = i == widget.selectedIndex;

                  return Expanded(
                    child: _NavItem(
                      tab: tab,
                      selected: selected,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTap(i);
                      },
                      height: _barH,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Individual tab item ───────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.height,
  });

  final NavTabData tab;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: SizedBox(
        height: widget.height,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              sizeCurve: Curves.easeInOut,
              crossFadeState: widget.selected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              // ── Selected: icon + label ───────────────────────────
              firstChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.tab.activeIcon,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.tab.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              // ── Unselected: icon only ────────────────────────────
              secondChild: Icon(
                widget.tab.icon,
                size: 22,
                color: CredoColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab data ──────────────────────────────────────────────────────────────

class NavTabData {
  const NavTabData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
