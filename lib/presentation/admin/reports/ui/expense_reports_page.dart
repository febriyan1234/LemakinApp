import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/expense.dart';
import '../cubit/admin_reports_cubit.dart';
import '../cubit/admin_reports_state.dart';

class ExpenseReportsPage extends StatefulWidget {
  const ExpenseReportsPage({super.key});

  @override
  State<ExpenseReportsPage> createState() => _ExpenseReportsPageState();
}

class _ExpenseReportsPageState extends State<ExpenseReportsPage> {
  late final AdminReportsCubit _cubit;
  final TextEditingController _searchController = TextEditingController();

  // Pagination State
  int _currentPage = 1;
  final int _rowsPerPage = 8;

  final List<String> _expenseCategories = [
    'Raw Materials',
    'Operations',
    'Transportation',
    'Salary',
    'Electricity',
    'Internet',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AdminReportsCubit>();
    _cubit.fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectDateRange(BuildContext context, AdminReportsLoaded state) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange:
          state.expenseStartDate != null && state.expenseEndDate != null
          ? DateTimeRange(
              start: state.expenseStartDate!,
              end: state.expenseEndDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      _cubit.updateExpenseFilters(
        startDate: pickedRange.start,
        endDate: pickedRange.end,
      );
      setState(() {
        _currentPage = 1; // Reset pagination
      });
    }
  }

  void _clearDateFilters() {
    _cubit.updateExpenseFilters(startDate: null, endDate: null);
    setState(() {
      _currentPage = 1;
    });
  }

  String _formatIndoDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminReportsCubit, AdminReportsState>(
      listener: (context, state) {
        if (state is AdminReportsLoaded) {
          if (state.actionSuccessMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionSuccessMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _cubit.clearMessages();
          }
          if (state.actionErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionErrorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _cubit.clearMessages();
          }
        }
      },
      builder: (context, state) {
        if (state is AdminReportsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (state is AdminReportsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _cubit.fetchReports(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is AdminReportsLoaded) {
          final totalExpensesCount = state.expenses.length;
          final totalPages = (totalExpensesCount / _rowsPerPage).ceil();
          final startIndex = (_currentPage - 1) * _rowsPerPage;
          var endIndex = startIndex + _rowsPerPage;
          if (endIndex > totalExpensesCount) endIndex = totalExpensesCount;

          final paginatedExpenses = totalExpensesCount > 0
              ? state.expenses.sublist(startIndex, endIndex)
              : <Expense>[];

          return RefreshIndicator(
            onRefresh: () => _cubit.refreshReports(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Total Card & Add Expense Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Ledger Expenses',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(state.totalExpenseSum),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        GradientButton(
                          onPressed: () => context.go('/admin/reports/expense/add'),
                          borderRadius: 12,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Add Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Search and Filters Panel
                    _buildFilterPanel(context, state),
                    const SizedBox(height: 20),

                    // Expenses Table
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: totalExpensesCount == 0
                            ? _buildEmptyState()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return _buildExpenseList(
                                        paginatedExpenses,
                                        constraints.maxWidth < 650,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPaginationControls(totalPages),
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
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilterPanel(BuildContext context, AdminReportsLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        final searchField = SizedBox(
          width: isCompact ? double.infinity : 240,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _cubit.updateExpenseFilters(query: val),
            decoration: InputDecoration(
              hintText: 'Search title...',
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _cubit.updateExpenseFilters(query: '');
                      },
                    )
                  : null,
            ),
          ),
        );

        final dropdownFilters = Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: state.selectedExpenseCategory,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: 'All',
                  child: Text('All Categories'),
                ),
                ..._expenseCategories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  _cubit.updateExpenseFilters(category: val);
                  setState(() {
                    _currentPage = 1;
                  });
                }
              },
            ),
            TextButton.icon(
              onPressed: () => _selectDateRange(context, state),
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(
                state.expenseStartDate == null || state.expenseEndDate == null
                    ? 'Choose Date Range'
                    : '${DateFormat('d/M/yy').format(state.expenseStartDate!)} - ${DateFormat('d/M/yy').format(state.expenseEndDate!)}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (state.expenseStartDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                onPressed: _clearDateFilters,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              dropdownFilters,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [searchField, dropdownFilters],
        );
      },
    );
  }

  Widget _buildCategoryBadge(String cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        cat,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page $_currentPage of $totalPages',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Row(
          children: [
            GradientButton(
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
              borderRadius: 12,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                'Previous',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            GradientButton(
              onPressed: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
              borderRadius: 12,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'No expenses found matching the selected filters.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete this expense of ${CurrencyFormatter.format(expense.amount)} for "${expense.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _cubit.deleteExpense(expense.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Expense Details'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Expense ID:', expense.id),
                _buildDetailRow('Date:', _formatIndoDate(expense.date)),
                _buildDetailRow('Category:', expense.category),
                _buildDetailRow('Title:', expense.description),
                _buildDetailRow(
                  'Amount:',
                  CurrencyFormatter.format(expense.amount),
                  valColor: AppColors.error,
                  valBold: true,
                ),
                _buildDetailRow('Created By:', expense.createdBy),
                if (expense.notes != null && expense.notes!.isNotEmpty)
                  _buildDetailRow('Notes:', expense.notes!),
                if (expense.items != null && expense.items!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text(
                    'Items Purchased:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  ...expense.items!.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('- ${item.name}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(CurrencyFormatter.format(item.price),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valColor,
    bool valBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valColor ?? AppColors.textDark,
                fontWeight: valBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildExpenseList(List<Expense> expenses, bool isCompact) {
    if (isCompact) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    _buildCategoryBadge(expense.category),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  expense.id,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatIndoDate(expense.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        expense.createdBy,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 24,
                  thickness: 0.5,
                  color: AppColors.grey300,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(expense.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.error,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: Colors.blue,
                            size: 18,
                          ),
                          tooltip: 'Details',
                          onPressed: () => _showDetailsDialog(context, expense),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.05),
                            padding: const EdgeInsets.all(4),
                          ),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.green,
                            size: 18,
                          ),
                          onPressed: () => context.go(
                            '/admin/reports/expense/edit/${expense.id}',
                            extra: expense,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.05),
                            padding: const EdgeInsets.all(4),
                          ),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          tooltip: 'Delete',
                          onPressed: () =>
                              _showDeleteConfirmDialog(context, expense),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withOpacity(0.05),
                            padding: const EdgeInsets.all(4),
                          ),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: const [
          DataColumn(
            label: Text(
              'Expense ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Created By',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: expenses.map((expense) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  expense.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(_formatIndoDate(expense.date))),
              DataCell(_buildCategoryBadge(expense.category)),
              DataCell(Text(expense.description)),
              DataCell(
                Text(
                  CurrencyFormatter.format(expense.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
              DataCell(Text(expense.createdBy)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      tooltip: 'Details',
                      onPressed: () => _showDetailsDialog(context, expense),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.green,
                        size: 20,
                      ),
                      tooltip: 'Edit',
                      onPressed: () => context.go(
                        '/admin/reports/expense/edit/${expense.id}',
                        extra: expense,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      tooltip: 'Delete',
                      onPressed: () =>
                          _showDeleteConfirmDialog(context, expense),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
