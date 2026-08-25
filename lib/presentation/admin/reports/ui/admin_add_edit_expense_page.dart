import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../domain/entities/expense.dart';
import '../cubit/admin_reports_cubit.dart';

class AdminAddEditExpensePage extends StatefulWidget {
  final Expense? expense;

  const AdminAddEditExpensePage({super.key, this.expense});

  @override
  State<AdminAddEditExpensePage> createState() => _AdminAddEditExpensePageState();
}

class _AdminAddEditExpensePageState extends State<AdminAddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  final List<String> _expenseCategories = [
    'Raw Materials',
    'Rent',
    'Salaries',
    'Salary',
    'Utilities',
    'Electricity',
    'Marketing',
    'Maintenance',
    'Internet',
    'Transportation',
    'Operations',
    'Others',
  ];

  late String _selectedCat;
  late DateTime _selectedDate;

  bool get _isEditMode => widget.expense != null;

  final List<Map<String, dynamic>> _itemFields = [];

  void _calculateAmountFromItems() {
    double total = 0;
    for (final field in _itemFields) {
      final priceText = (field['priceController'] as TextEditingController).text;
      final price = double.tryParse(priceText) ?? 0;
      total += price;
    }
    if (_itemFields.isNotEmpty) {
      _amountController.text = total.toInt().toString();
    }
  }

  void _addItemField([String name = '', String price = '']) {
    final nameCtrl = TextEditingController(text: name);
    final priceCtrl = TextEditingController(text: price);
    priceCtrl.addListener(_calculateAmountFromItems);
    setState(() {
      _itemFields.add({
        'nameController': nameCtrl,
        'priceController': priceCtrl,
      });
    });
  }

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;

    _descController = TextEditingController(text: expense?.description ?? '');
    _amountController = TextEditingController(
      text: expense != null ? '${expense.amount.toInt()}' : '',
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');

    _selectedCat = expense?.category ?? _expenseCategories[0];
    if (!_expenseCategories.contains(_selectedCat)) {
      _expenseCategories.add(_selectedCat);
    }
    _selectedDate = expense?.date ?? DateTime.now();

    if (expense?.items != null) {
      for (final item in expense!.items!) {
        _addItemField(item.name, item.price.toInt().toString());
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final field in _itemFields) {
      (field['nameController'] as TextEditingController).dispose();
      final pCtrl = field['priceController'] as TextEditingController;
      pCtrl.removeListener(_calculateAmountFromItems);
      pCtrl.dispose();
    }
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final amt = double.parse(_amountController.text);
      final desc = _descController.text.trim();
      final note = _notesController.text.trim();
      final cubit = context.read<AdminReportsCubit>();

      final List<ExpenseItem> items = _itemFields.map((field) {
        final name = (field['nameController'] as TextEditingController).text.trim();
        final price = double.parse((field['priceController'] as TextEditingController).text);
        return ExpenseItem(name: name, price: price);
      }).toList();

      if (_isEditMode) {
        final updated = widget.expense!.copyWith(
          date: _selectedDate,
          category: _selectedCat,
          description: desc,
          amount: amt,
          notes: note.isNotEmpty ? note : null,
          items: items.isNotEmpty ? items : null,
        );
        await cubit.updateExpense(updated);
      } else {
        final added = Expense(
          id: 'EXP_${DateTime.now().millisecondsSinceEpoch}',
          date: _selectedDate,
          category: _selectedCat,
          description: desc,
          amount: amt,
          notes: note.isNotEmpty ? note : null,
          createdBy: 'Super Admin',
          items: items.isNotEmpty ? items : null,
        );
        await cubit.addExpense(added);
      }
      if (mounted) {
        context.go('/admin/reports/expense');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row outside the white Card!
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                    onPressed: () => context.go('/admin/reports/expense'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'Edit Expense Record' : 'Record New Expense',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form Container (White Card)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Selector
                      const Text(
                        'Date *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('d MMM yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category Selector
                      const Text(
                        'Category *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCat,
                        items: _expenseCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCat = val;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description Input
                      const Text(
                        'Description *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'e.g. Rice supply stock purchase',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sub-Items list section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items Purchased (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _addItemField(),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_itemFields.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: const Center(
                            child: Text(
                              'No sub-items added',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _itemFields.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final item = _itemFields[idx];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: item['nameController'] as TextEditingController,
                                    decoration: InputDecoration(
                                      hintText: 'Item name',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: item['priceController'] as TextEditingController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Price',
                                      prefixText: 'Rp ',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Required';
                                      if (double.tryParse(val) == null) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    final priceCtrl = item['priceController'] as TextEditingController;
                                    priceCtrl.removeListener(_calculateAmountFromItems);
                                    priceCtrl.dispose();
                                    (item['nameController'] as TextEditingController).dispose();
                                    setState(() {
                                      _itemFields.removeAt(idx);
                                    });
                                    _calculateAmountFromItems();
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFEBEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 20),

                      // Amount Input
                      const Text(
                        'Amount (IDR) *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        readOnly: _itemFields.isNotEmpty,
                        decoration: InputDecoration(
                          hintText: 'e.g. 500000',
                          prefixText: 'Rp ',
                          filled: _itemFields.isNotEmpty,
                          fillColor: _itemFields.isNotEmpty ? Colors.grey[50] : null,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Notes Input
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Optional notes...',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit & Cancel Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => context.go('/admin/reports/expense'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GradientButton(
                              onPressed: _submitForm,
                              borderRadius: 12,
                              child: Text(
                                _isEditMode ? 'Save Changes' : 'Save Record',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
