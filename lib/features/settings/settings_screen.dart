import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/app_providers.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/services/local_data_service.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Box<dynamic> _settingsBox;
  bool _useBiometrics = false;
  String _currentPin = '1234';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box<dynamic>(HiveBoxNames.appSettings);
    _useBiometrics =
        _settingsBox.get('use_biometrics', defaultValue: false) as bool;
    _currentPin =
        _settingsBox.get('app_pin', defaultValue: '1234') as String;
  }

  void _toggleBiometrics(bool val) {
    setState(() => _useBiometrics = val);
    _settingsBox.put('use_biometrics', val);
    HapticFeedback.lightImpact();
  }

  void _showChangePinDialog() {
    final pinCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: CredoColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            side: const BorderSide(color: CredoColors.glassBorderStart, width: 0.5),
          ),
          title: Text(
            'Change Security PIN',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: CredoColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a new 4-digit security code for unlocking Credo.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: CredoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(
                  color: CredoColors.textPrimary,
                  letterSpacing: 8,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: CredoColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '••••',
                  hintStyle: const TextStyle(
                    color: CredoColors.textSecondary,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: CredoColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CredoColors.accentViolet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final newPin = pinCtrl.text.trim();
                if (newPin.length == 4) {
                  _settingsBox.put('app_pin', newPin);
                  setState(() => _currentPin = newPin);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN successfully updated!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: CredoColors.surfaceVariant,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN must be exactly 4 digits'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: CredoColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save PIN', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetBudgets() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CredoColors.surface,
        title: const Text('Reset Budgets?'),
        content: const Text(
          'This will reset all monthly category budget limits back to original defaults.',
          style: TextStyle(color: CredoColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: CredoColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CredoColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(budgetsProvider.notifier).resetToDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budgets reset to defaults!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reseedSampleData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CredoColors.surface,
        title: const Text('Re-seed Transactions?'),
        content: const Text(
          'This will reload the initial demo transactions from JSON into your Hive database.',
          style: TextStyle(color: CredoColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: CredoColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CredoColors.accentViolet),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = Hive.box<Transaction>(HiveBoxNames.transactions);
      await box.clear();
      final sample = await LocalDataService.loadTransactions();
      for (final t in sample) {
        await box.put(t.id, t);
      }
      ref.invalidate(transactionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo transactions reloaded!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
    final isOffline = ref.watch(simulateOfflineProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: AppConstants.spacingM,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Profile Card ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: CredoColors.accentGradient,
                            ),
                            child: const Center(
                              child: Text(
                                'A',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aagosh',
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Credo Pro · Portfolio Edition',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: CredoColors.accentCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CredoColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: CredoColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Section: Security ────────────────────────────────
                const SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Security & Access'),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CredoColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.pin_rounded,
                              color: CredoColors.accentViolet,
                            ),
                            title: const Text('App Security PIN'),
                            subtitle: Text('Current PIN: •••• (ends in ${_currentPin.characters.last})'),
                            trailing: SizedBox(
                              width: 84,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CredoColors.surfaceHighlight,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                ),
                                onPressed: _showChangePinDialog,
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: CredoColors.accentCyan,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: CredoColors.textDisabled,
                          ),
                          SwitchListTile(
                            activeColor: CredoColors.accentViolet,
                            secondary: const Icon(
                              Icons.fingerprint_rounded,
                              color: CredoColors.accentCyan,
                            ),
                            title: const Text('Biometric Unlock'),
                            subtitle: const Text('Face ID or Fingerprint authentication'),
                            value: _useBiometrics,
                            onChanged: _toggleBiometrics,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Section: Preferences ─────────────────────────────
                const SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Preferences & Cache'),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CredoColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeColor: CredoColors.warning,
                            secondary: const Icon(
                              Icons.wifi_off_rounded,
                              color: CredoColors.warning,
                            ),
                            title: const Text('Simulate Offline Mode'),
                            subtitle: const Text('Bypass network to verify Hive cache'),
                            value: isOffline,
                            onChanged: (val) {
                              ref.read(simulateOfflineProvider.notifier).state = val;
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: CredoColors.textDisabled,
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.restart_alt_rounded,
                              color: CredoColors.accentCyan,
                            ),
                            title: const Text('Reset Category Budgets'),
                            subtitle: const Text('Restore original default spending limits'),
                            onTap: _resetBudgets,
                          ),
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: CredoColors.textDisabled,
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.restore_page_rounded,
                              color: CredoColors.accentViolet,
                            ),
                            title: const Text('Re-seed Demo Transactions'),
                            subtitle: Text('${txns.length} transactions currently stored in Hive'),
                            onTap: _reseedSampleData,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Section: About ───────────────────────────────────
                const SliverToBoxAdapter(
                  child: _SectionHeader(title: 'About'),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: CredoColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Credo',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'v2.0.0 (Build 2026)',
                                style: TextStyle(
                                  color: CredoColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'State-of-the-art Flutter financial engine featuring Riverpod 2.0 AsyncNotifiers, Hive offline write-through cache, and background compute isolates.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: CredoColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'GitHub: AagoshRajSri/Credo',
                            style: TextStyle(
                              color: CredoColors.accentCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        0,
        AppConstants.spacingM,
        AppConstants.spacingS,
      ),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: CredoColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
