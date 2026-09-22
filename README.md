# Credo 💳

> A CRED-level personal finance & credit health dashboard — built with Flutter.

An exercise in fintech UI design, fluid animations, and robust data architecture. The goal of this project is to build an app that doesn't just work, but feels incredibly premium to use—leveraging custom animations, haptic feedback, and performant state management.

---

## 🛠 Tech Stack & Architecture

This project was built to satisfy modern production Flutter requirements:

| Requirement | Implementation |
|---|---|
| **State Management** | **Riverpod** — Heavily uses `FutureProvider`, `StateProvider`, and `ConsumerWidget` for reactive data flow and caching. |
| **REST APIs & Network** | **Dio** — Configured with base options, interceptors, and a real endpoint (`open.er-api.com` for FX) alongside graceful mock fallbacks. |
| **Local Storage** | **Hive** — Fast, offline-first NoSQL database. Repositories implement a "network-first, cache-fallback" pattern for resilience. |
| **Threading & Performance** | **Isolates (`compute()`)** — Heavy payload parsing and spending analytics generation are offloaded to background threads. |
| **Fluid UI & Graphics** | **CustomPainter** & **Hero** — Used for the radial credit score gauge, morphing bottom navigation pill, and shared-axis transaction transitions. |
| **Performance Pass** | Heavy use of `const`, `RepaintBoundary` around animations (gauge, ambient blobs), and optimized `AnimatedBuilder` setups. |
| **Accessibility & Edge Cases** | Deep `Semantics` coverage on custom widgets, comprehensive `EmptyState`/`ErrorState` handling, and full `reduceMotion` (disableAnimations) support. |

---

## 🏗 Project Structure

```
lib/
  core/          → theme (tokens, dark mode), constants, utils, haptics, API client
  data/          → models, enums, providers, repositories (Hive + Dio), services (Isolates)
  features/      → UI modules (auth, dashboard, accounts, transactions, analytics)
  shared/        → cross-feature widgets (GlassCard, GradientBackground, shimmers)
  app.dart       → GoRouter config & ShellRoute (Bottom Navigation)
  main.dart      → ProviderScope, Hive init, App entry
```

---

## 🚀 Hero Moments

The UI focuses on restraint + delight in specific moments, rather than motion everywhere.

1. **The Radial Score Gauge:** A custom `CustomPainter` arc that spring-animates from 0 to the user's score with a `Cubic` overshoot, ending with a haptic bump.
2. **The PIN Unlock:** A staggered entrance with gradient-filled dots, a decaying sinusoidal math shake on error, and a scale/fade exit transition.
3. **Transaction Details:** Shared-axis Hero transitions where the transaction emoji scales seamlessly to an 88px circle on the detail screen while the rest of the page slides in horizontally.
4. **Ambient Background:** A `RepaintBoundary`-isolated background featuring 3 slow-drifting, semi-transparent colour blobs to give the app a living, breathing feel.

---

## 🏃 Running Locally

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

*Requires Flutter 3.32.4+ and Dart 3.8.1+. Tested on Android, iOS, and Web.*

---

## 📊 Data Sources

- **Exchange Rates:** Real live REST call to `exchangerate.host`.
- **Account / Transaction Data:** Seeded from local JSON assets (mock) to simulate network delay before caching to Hive.
- **Analytics:** Computed from raw transaction data using a dedicated background isolate.

---

## 🔮 What I'd Do With More Time

- Real live Plaid/Setu bank account linkage.
- Biometric authentication (fingerprint/Face ID) integration.
- Spend categorization driven by local ML models.
- Interactive home screen widgets showing today's spend.
- Push notifications for large transaction alerts.

---

*Built phase-by-phase following a structured 10-phase execution plan. See `CHANGELOG.md` for the complete development history.*
