# Changelog

All notable changes to Credo are recorded here.
Format: `[Phase N] Brief description — date`

---

## [Phase 1] Project skeleton & architecture — 2026-09-22

- Initialised Flutter project with Riverpod, GoRouter, Dio, Hive, fl_chart, shimmer, flutter_animate, google_fonts.
- Established `lib/` folder structure: core / data / features / shared.
- Configured full dark `ThemeData` with Space Grotesk (display) + Inter (body) via google_fonts.
- Color token system: deep charcoal base, violet→cyan accent gradient.
- GoRouter shell with 4 tabs: Home, Accounts, Analytics, Activity.
- PIN screen stub (static dot layout + keypad).
- Static `GlassCard` (BackdropFilter blur + gradient border) and `GradientBackground` (3 blobs) shared widgets.
- Shimmer placeholder widgets for account cards, transaction rows, charts, and gauge.
- `HapticService` wrapper, `ApiClient` Dio stub, `AppConstants`, `BuildContextX` extensions.
- App boots, tab switching works, dark theme applied — ✅ Phase 1 exit criteria met.

## [Phase 2] Data layer — models, Hive, repositories, Riverpod, isolate — 2026-09-22

- Defined models: `Account`, `Transaction`, `CreditScoreSnapshot` with `fromJson`/`toJson` and `copyWith`.
- Seed JSON assets: 3 accounts, 15 transactions, 6-month credit score history.
- Hand-written Hive TypeAdapters (typeIds 2/3/4) — no build_runner step needed.
- Hive boxes (`accounts_box`, `transactions_box`, `score_history_box`, `app_settings_box`) opened at startup.
- `LocalDataService` — loads and parses all 3 JSON assets.
- `TransactionsRepository` / `AccountsRepository` / `CreditScoreRepository` — asset-first, Hive-cache-write-through; `simulateOffline` flag proves cache path.
- `AnalyticsIsolate` — `compute()` off-thread: category breakdown + monthly spend totals.
- `ExchangeRateService` — real REST call to open.er-api.com (free, no key) for live USD→INR rate.
- Riverpod providers: `FutureProvider` for all data + `simulateOfflineProvider` debug toggle.
- `flutter analyze` → No issues found ✅

## [Phase 3] Core screens with real data — 2026-09-22

- `lib/core/utils/formatters.dart` — Indian rupee (en_IN), relative dates, greeting string.
- `lib/shared/widgets/account_card.dart` — premium glass card with account colour tint, masked number, balance, bank initial badge.
- `lib/shared/widgets/transaction_row.dart` — category emoji badge, merchant/category/date, signed amount; Hero tag slots for Phase 6.
- `lib/shared/widgets/empty_state.dart` + `ErrorState` — designed non-placeholder states across all screens.
- `DashboardScreen` — live rate badge (open.er-api.com), score card with 6-month mini trend bars, horizontal account card scroll, recent 5 transactions.
- `AccountsScreen` — full account list + net worth summary card (savings vs credit breakdown).
- `TransactionsScreen` — category filter chips (animated), full transaction list, shimmer/empty/error.
- `TransactionDetailScreen` — large signed amount, merchant emoji, metadata card, note card (full-screen, no bottom nav).
- `AnalyticsScreen` — fl_chart PieChart donut (category breakdown + legend) + BarChart (monthly spend, gradient bars, touch tooltips); data computed off-thread via `AnalyticsIsolate.run()`.
- Router updated: `/transaction/:id` outside shell; `Transaction` object passed via GoRouter `extra`.
- `flutter analyze` → No issues found ✅

## [Phase 4] Radial credit score gauge — 2026-09-22

- `score_gauge.dart` (NEW): ScoreGauge — 270° arc SweepGradient, spring Cubic(0.34,1.4,0.64,1.0) with 8% overshoot, RepaintBoundary, reduce-motion fallback.
- _GaugePainter — tick marks at 300/600/900, glowing tip dot with MaskFilter.blur.
- ScoreSparkline — fl_chart LineChart, gradient fill, enlarged last dot, month labels.
- Haptic at 85% via HapticFeedback.mediumImpact(). Sparkline AnimatedOpacity + AnimatedSlide after settle.
- Dead code removed: _ScoreCard, _ScoreChip, _ScoreTrendDots, _ScoreRange, _RangeBarPainter.
- flutter analyze → No issues found ✅

## [Phase 5] PIN unlock hero moment — 2026-09-22

- Staggered entrance: brand/dots/keypad rows fade+slide in with _FadeSlideIn (delay intervals).
- PIN dots: spring scale fill per tap via Cubic(0.34,1.56,0.64,1.0), gradient interior, violet glow shadow.
- Wrong PIN: decaying sine shake (3 oscillations), error haptic, dots turn red, auto-clear.
- Correct PIN: heavyImpact haptic, screen scales to 1.06 + fades out, navigates to /home.
- Backspace: removes last digit with lightImpact.
- Biometric placeholder: fingerprint icon, shows SnackBar (functional hook ready).
- Reduce-motion: entrance controller jumps to value=1.0.
- Demo PIN: 1234 (// DECISION comment in source).
- flutter analyze → No issues found ✅

## [Phase 6] Hero transitions — 2026-09-22

- TransactionRow: CategoryBadge wrapped in Hero(tag: 'txn-icon-{id}').
- TransactionDetailScreen: icon container wrapped in matching Hero with flightShuttleBuilder (fades to destination widget during flight for clean scale). Amount Hero skipped — titleSmall->displayMedium delta too large.
- app.dart: transaction detail route uses CustomTransitionPage with horizontal shared-axis (fade + 6% slide in, fade out on pop). 380ms enter / 300ms reverse.
- flutter analyze → No issues found ✅

## [Phase 7] Custom morphing pill nav bar — 2026-09-22

- `credo_nav_bar.dart` (NEW): Floating pill layout (extendBody: true in scaffold).
- Glass-morphic surface via BackdropFilter + border.
- Gradient pill spring-slides (Curves.easeOutBack) between tabs via Stack Positioned animation.
- NavTabData definition decoupled from shell for component purity.
- Icon-only unselected → icon + label selected using AnimatedCrossFade.
- Scale press feedback on tabs with HapticFeedback.lightImpact().
- flutter analyze → No issues found ✅

## [Phase 8] Performance Pass — 2026-09-22

- Added Stopwatch timing logs to AnalyticsIsolate.run() to measure payload serialization and compute overhead.
- Verified RepaintBoundary placements (ScoreGauge arc, GradientBackground, Analytics charts).
- Verified image caching surface area is minimal (pure canvas/emoji).
- flutter analyze (const audit) → No issues found ✅

## [Phase 9] States, Accessibility & Edge Cases — 2026-09-22

- Added full support for disableAnimations (reduceMotion): ambient background blobs pause smoothly, PIN shake disables gracefully.
- Added deep Semantics integration to custom components: ScoreGauge arc now reads out full score status, PIN input reads character count, and Bar/Pie charts describe total spend/trends.
- Implemented responsive Offline banner in AppShell leveraging the simulateOfflineProvider.
- Verified all Empty states and error fallback flows.
- flutter analyze → No issues found ✅

## [Phase 10] Final Polish & Wrap-up — 2026-09-22

- Complete rewrite of README.md mapping tech stack, architecture, and Hero Moments to the project vision.
- App build plan fully executed (Phases 1 through 10).
- Ready for submission/demo.

## [Phase 11-14] Advanced Features & Polish — 2026-09-22

- **Manual Transactions**: Built `TransactionFormScreen` with custom type toggle, emoji category picker, and amount input.
- **Swipe Actions & Re-categorization**: Added swipe-to-delete on `TransactionsScreen` and a live tap-to-re-categorize bottom sheet on `TransactionDetailScreen`.
- **Monthly Category Budgeting**: Created `BudgetRepository` and providers. Added visual budget tracking section on the Analytics screen to track spending limits per category.
- **Search & Filters**: Added robust search by merchant, note, and amount. Added horizontal filter chips for Categories and Favorites on `TransactionsScreen`.
- **Savings Goals**: Created `SavingsGoal` model (typeId 5) and `GoalCard` with animated progress bars. Integrated into `DashboardScreen` and built a dedicated `SavingsGoalsScreen`.
- **Settings Screen**: Added biometric toggle stub, PIN changer, offline simulation toggle, and data reset tools.
- Fixed multiple UI layout issues, including FAB overlapping with custom navigation bar and trailing widgets in `ListTile`.

## [Phase 16] The Real Data Layer (Firebase) — 2026-09-23

- **Authentication**: Integrated `firebase_auth` with Riverpod. Built a dynamic `LoginScreen` and updated `GoRouter` to force unauthenticated users to log in.
- **Cloud Firestore**: Completely refactored `TransactionsRepository` and `SavingsGoalRepository` to read/write directly to Cloud Firestore instead of local Hive storage.
- **Data Privacy**: Scoped all database reads and writes to the authenticated user's `uid` (e.g., `users/{uid}/transactions/...`) to ensure complete multi-tenant SaaS architecture.
- **Offline Resilience**: Maintained offline capability through Firestore's built-in offline caching logic.
