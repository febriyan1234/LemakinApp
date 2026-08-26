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
    final pickedRange = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return _CustomDateRangePickerBottomSheet(
          initialStartDate: state.expenseStartDate,
          initialEndDate: state.expenseEndDate,
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

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, AdminReportsLoaded state) {
    final chipsList = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildFilterChip(
              label: 'All Categories',
              value: 'All',
              isSelected: state.selectedExpenseCategory == 'All',
              onTap: () {
                _cubit.updateExpenseFilters(category: 'All');
                setState(() {
                  _currentPage = 1;
                });
              },
            ),
          ),
          ..._expenseCategories.map((c) {
            final isSelected = state.selectedExpenseCategory == c;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildFilterChip(
                label: c,
                value: c,
                isSelected: isSelected,
                onTap: () {
                  _cubit.updateExpenseFilters(category: c);
                  setState(() {
                    _currentPage = 1;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );

    final dateRangeButton = OutlinedButton.icon(
      onPressed: () => _selectDateRange(context, state),
      icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
      label: Text(
        state.expenseStartDate == null || state.expenseEndDate == null
            ? 'Choose Date Range'
            : '${DateFormat('d/M/yy').format(state.expenseStartDate!)} - ${DateFormat('d/M/yy').format(state.expenseEndDate!)}',
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
      ),
    );

    final clearDateButton = state.expenseStartDate != null
        ? IconButton(
            icon: const Icon(Icons.cancel, size: 18, color: AppColors.error),
            tooltip: 'Clear Date Filter',
            onPressed: _clearDateFilters,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 6),
          )
        : const SizedBox.shrink();

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

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchField,
              const SizedBox(height: 12),
              chipsList,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: dateRangeButton),
                        clearDateButton,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                searchField,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    dateRangeButton,
                    clearDateButton,
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            chipsList,
          ],
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

class _CustomDateRangePickerBottomSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _CustomDateRangePickerBottomSheet({
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_CustomDateRangePickerBottomSheet> createState() =>
      __CustomDateRangePickerBottomSheetState();
}

class __CustomDateRangePickerBottomSheetState
    extends State<_CustomDateRangePickerBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _visibleMonth = widget.initialStartDate ?? DateTime.now();
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDayTapped(DateTime day) {
    if (_startDate == null) {
      setState(() {
        _startDate = day;
      });
    } else if (_endDate == null) {
      if (day.isBefore(_startDate!)) {
        setState(() {
          _startDate = day;
        });
      } else {
        setState(() {
          _endDate = day;
        });
      }
    } else {
      setState(() {
        _startDate = day;
        _endDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int year = _visibleMonth.year;
    final int month = _visibleMonth.month;
    
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final weekdayOfFirst = DateTime(year, month, 1).weekday;
    final emptySlots = weekdayOfFirst == 7 ? 0 : weekdayOfFirst;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DATE RANGE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_visibleMonth),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              final isWeekend = day == 'S';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWeekend ? AppColors.error.withOpacity(0.7) : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              crossAxisSpacing: 0,
              mainAxisSpacing: 4,
            ),
            itemCount: emptySlots + daysInMonth,
            itemBuilder: (context, index) {
              if (index < emptySlots) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - emptySlots + 1;
              final day = DateTime(year, month, dayNumber);
              
              final isTodayOrBefore = day.isBefore(DateTime.now()) || _isSameDay(day, DateTime.now());
              final isStart = _startDate != null && _isSameDay(day, _startDate!);
              final isEnd = _endDate != null && _isSameDay(day, _endDate!);
              final isRangeActive = _startDate != null && _endDate != null;
              final isInRange = isRangeActive && day.isAfter(_startDate!) && day.isBefore(_endDate!);

              return GestureDetector(
                onTap: isTodayOrBefore ? () => _onDayTapped(day) : null,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: (isInRange || (isEnd && isRangeActive))
                                ? AppColors.primarySoft
                                : Colors.transparent,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: (isInRange || (isStart && isRangeActive))
                                ? AppColors.primarySoft
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    if (isStart || isEnd)
                      Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (isStart || isEnd || isInRange) ? FontWeight.bold : FontWeight.normal,
                          color: !isTodayOrBefore
                              ? AppColors.textLight.withOpacity(0.5)
                              : ((isStart || isEnd)
                                  ? Colors.white
                                  : (isInRange ? AppColors.primary : AppColors.textDark)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Range',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _startDate == null
                        ? 'No dates selected'
                        : (_endDate == null
                            ? DateFormat('d MMM yyyy').format(_startDate!)
                            : '${DateFormat('d MMM yyyy').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (_startDate != null || _endDate != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  onPressed: (_startDate != null && _endDate != null)
                      ? () {
                          Navigator.pop(
                            context,
                            DateTimeRange(start: _startDate!, end: _endDate!),
                          );
                        }
                      : null,
                  borderRadius: 12,
                  height: 48,
                  child: const Text(
                    'Apply Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
