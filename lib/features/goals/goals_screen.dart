import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/goal_card.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goal-form'),
        backgroundColor: CredoColors.accentViolet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (goals) {
                if (goals.isEmpty) {
                  return const EmptyState(
                    emoji: '🎯',
                    title: 'No Goals Yet',
                    subtitle: 'Set a savings goal to track your progress.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  itemCount: goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return SizedBox(
                      height: 120,
                      child: GoalCard(
                        goal: goal,
                        onTap: () => context.push('/goal-form', extra: goal),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
