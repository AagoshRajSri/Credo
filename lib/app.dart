import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'data/models/transaction.dart';
import 'features/auth/pin_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'shared/widgets/credo_nav_bar.dart';

// ── Route paths ──────────────────────────────────────────────────────────
abstract final class AppRoutes {
  static const String pin = '/pin';
  static const String home = '/home';
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transaction/:id';
  static const String analytics = '/analytics';
}

// ── Router definition ────────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.pin,
  routes: [
    // ── PIN screen (no bottom nav shell) ──────────────────────────────
    GoRoute(
      path: AppRoutes.pin,
      name: 'pin',
      builder: (_, __) => const PinScreen(),
    ),

    // ── Transaction detail (no bottom nav — full screen) ───────────────
    // DECISION: Detail screen is outside the shell so it's full-screen
    // without the bottom nav bar, giving the content more breathing room.
    GoRoute(
      path: AppRoutes.transactionDetail,
      name: 'transaction-detail',
      // Phase 6: custom page transition — horizontal shared-axis (fade + subtle
      // slide) that complements the Hero icon flight without fighting it.
      pageBuilder: (context, state) {
        final transaction = state.extra as Transaction;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: TransactionDetailScreen(transaction: transaction),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Enter: fade + slide in 6% from right
            final enterFade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final enterSlide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            // Exit (when popping): fade + slide 4% to right
            final exitFade = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeIn,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(enterFade),
              child: FadeTransition(
                opacity:
                    Tween<double>(begin: 1.0, end: 0.0).animate(exitFade),
                child: SlideTransition(
                  position: enterSlide,
                  child: child,
                ),
              ),
            );
          },
        );
      },
    ),

    // ── Main shell with bottom navigation ─────────────────────────────
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.accounts,
          name: 'accounts',
          builder: (_, __) => const AccountsScreen(),
        ),
        GoRoute(
          path: AppRoutes.transactions,
          name: 'transactions',
          builder: (_, __) => const TransactionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.analytics,
          name: 'analytics',
          builder: (_, __) => const AnalyticsScreen(),
        ),
      ],
    ),
  ],
);

// ── Shell scaffold with custom morphing pill nav ──────────────────────────

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.child});
  final Widget child;

  // Route order must match CredoNavBar.tabs order.
  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.accounts,
    AppRoutes.analytics,
    AppRoutes.transactions,
  ];

  static int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.accounts)) return 1;
    if (location.startsWith(AppRoutes.analytics)) return 2;
    if (location.startsWith(AppRoutes.transactions)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _locationToIndex(location);
    final isOffline = ref.watch(simulateOfflineProvider);

    return Scaffold(
      // Extend body behind the floating nav so gradient shows through.
      extendBody: true,
      body: Stack(
        children: [
          child,
          if (isOffline)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Semantics(
                label: 'Offline Mode Active',
                child: Container(
                  color: Colors.orange.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'Offline Mode (Cached Data)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: CredoNavBar(
          selectedIndex: selectedIndex,
          onTap: (i) => context.go(_routes[i]),
        ),
      ),
    );
  }
}

// ── Root app widget ───────────────────────────────────────────────────────
class CredoApp extends StatelessWidget {
  const CredoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Credo',
      debugShowCheckedModeBanner: false,
      theme: CredoTheme.dark,
      routerConfig: appRouter,
    );
  }
}
