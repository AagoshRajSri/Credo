import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/app_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.existingTransaction});

  final Transaction? existingTransaction;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isCredit;
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _noteCtrl;
  late TransactionCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTransaction;
    _isCredit = t?.isCredit ?? false;
    _amountCtrl = TextEditingController(text: t?.amount.toString() ?? '');
    _merchantCtrl = TextEditingController(text: t?.merchant ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _category = t?.category ?? TransactionCategory.food;
    _date = t?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CredoColors.accentViolet,
              surface: CredoColors.surfaceHighlight,
              onSurface: CredoColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountCtrl.text.trim();
    final amount = double.tryParse(amountStr) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final t = widget.existingTransaction;
    final newTx = Transaction(
      id: t?.id ?? const Uuid().v4(),
      accountId: t?.accountId ?? 'acc_1', // Using default account for now
      merchant: _merchantCtrl.text.trim(),
      amount: amount,
      isCredit: _isCredit,
      category: _category,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (t != null) {
      ref.read(transactionsProvider.notifier).updateTx(newTx);
    } else {
      ref.read(transactionsProvider.notifier).add(newTx);
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTransaction != null;

    return Scaffold(
      backgroundColor: CredoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEditing ? 'Edit Transaction' : 'New Transaction',
            style: context.textTheme.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Toggle
                Row(
                  children: [
                    Expanded(
                      child: _TypeToggle(
                        label: 'Expense',
                        isSelected: !_isCredit,
                        color: CredoColors.error,
                        onTap: () => setState(() => _isCredit = false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TypeToggle(
                        label: 'Income',
                        isSelected: _isCredit,
                        color: CredoColors.success,
                        onTap: () => setState(() => _isCredit = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Amount
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: context.textTheme.displayMedium?.copyWith(
                    color: _isCredit ? CredoColors.success : CredoColors.error,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    labelStyle: const TextStyle(color: CredoColors.textSecondary),
                    filled: true,
                    fillColor: CredoColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Merchant
                TextFormField(
                  controller: _merchantCtrl,
                  style: const TextStyle(color: CredoColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Merchant / Title',
                    labelStyle: const TextStyle(color: CredoColors.textSecondary),
                    filled: true,
                    fillColor: CredoColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<TransactionCategory>(
                  value: _category,
                  dropdownColor: CredoColors.surfaceHighlight,
                  iconEnabledColor: CredoColors.accentViolet,
                  style: const TextStyle(color: CredoColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: CredoColors.textSecondary),
                    filled: true,
                    fillColor: CredoColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: TransactionCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text('${cat.emoji}  ${cat.displayName}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: CredoColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CredoFormatters.relativeDate(_date),
                          style:
                              const TextStyle(color: CredoColors.textPrimary),
                        ),
                        const Icon(Icons.calendar_today,
                            color: CredoColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteCtrl,
                  style: const TextStyle(color: CredoColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    labelStyle: const TextStyle(color: CredoColors.textSecondary),
                    filled: true,
                    fillColor: CredoColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Save Button
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CredoColors.accentViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Transaction',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : CredoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: context.textTheme.titleSmall?.copyWith(
              color: isSelected ? color : CredoColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
