import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/savings_goal.dart';
import '../../data/providers/app_providers.dart';
import '../../shared/widgets/gradient_background.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.existingGoal});
  final SavingsGoal? existingGoal;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _savedController;
  DateTime? _deadline;
  int _selectedColorValue = Colors.blue.toARGB32();
  int _selectedIconCode = Icons.savings.codePoint;

  final List<Color> _colorOptions = [
    Colors.blue,
    CredoColors.accentViolet,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    CredoColors.success,
  ];

  final List<IconData> _iconOptions = [
    Icons.savings,
    Icons.flight_takeoff,
    Icons.directions_car,
    Icons.home,
    Icons.school,
    Icons.laptop_mac,
    Icons.favorite,
    Icons.medical_services,
  ];

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _targetController = TextEditingController(
        text: goal?.targetAmount.toStringAsFixed(0) ?? '');
    _savedController = TextEditingController(
        text: goal?.savedAmount.toStringAsFixed(0) ?? '0');
    _deadline = goal?.deadline;
    _selectedColorValue = goal?.colorValue ?? Colors.blue.toARGB32();
    _selectedIconCode = goal?.iconCode ?? Icons.savings.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final target = double.tryParse(_targetController.text) ?? 0.0;
    final saved = double.tryParse(_savedController.text) ?? 0.0;

    final goal = SavingsGoal(
      id: widget.existingGoal?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      targetAmount: target,
      savedAmount: saved,
      deadline: _deadline,
      colorValue: _selectedColorValue,
      iconCode: _selectedIconCode,
      isCompleted: saved >= target,
    );

    if (widget.existingGoal == null) {
      ref.read(savingsGoalsProvider.notifier).add(goal);
    } else {
      ref.read(savingsGoalsProvider.notifier).updateGoal(goal);
    }
    context.pop();
  }

  void _deleteGoal() {
    if (widget.existingGoal != null) {
      ref.read(savingsGoalsProvider.notifier).remove(widget.existingGoal!.id);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'New Goal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: CredoColors.error),
              onPressed: _deleteGoal,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                children: [
                  _buildSectionLabel('GOAL NAME'),
                  TextFormField(
                    controller: _nameController,
                    style: context.textTheme.bodyLarge,
                    decoration: _inputDecoration('E.g. New Car, Vacation...'),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildSectionLabel('TARGET AMOUNT (₹)'),
                  TextFormField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    style: context.textTheme.bodyLarge,
                    decoration: _inputDecoration('0.00'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildSectionLabel('ALREADY SAVED (₹)'),
                  TextFormField(
                    controller: _savedController,
                    keyboardType: TextInputType.number,
                    style: context.textTheme.bodyLarge,
                    decoration: _inputDecoration('0.00'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildSectionLabel('DEADLINE (OPTIONAL)'),
                  GestureDetector(
                    onTap: _pickDeadline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: CredoColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _deadline != null
                                ? DateFormat.yMMMd().format(_deadline!)
                                : 'Select a date',
                            style: context.textTheme.bodyLarge,
                          ),
                          const Icon(Icons.calendar_today,
                              color: CredoColors.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildSectionLabel('ICON'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _iconOptions.map((icon) {
                      final isSelected = icon.codePoint == _selectedIconCode;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedIconCode = icon.codePoint),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CredoColors.accentViolet
                                : CredoColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : CredoColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildSectionLabel('COLOR'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colorOptions.map((color) {
                      final isSelected = color.toARGB32() == _selectedColorValue;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorValue = color.toARGB32()),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CredoColors.accentViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Goal',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(
          color: CredoColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: CredoColors.textSecondary),
      filled: true,
      fillColor: CredoColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        borderSide: const BorderSide(color: CredoColors.accentViolet),
      ),
    );
  }
}
