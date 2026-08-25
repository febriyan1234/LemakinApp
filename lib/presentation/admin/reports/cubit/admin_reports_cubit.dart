import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/expense.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../../domain/repositories/expense_repository.dart';
import 'admin_reports_state.dart';

class AdminReportsCubit extends Cubit<AdminReportsState> {
  final OrderRepository orderRepository;
  final ExpenseRepository expenseRepository;

  AdminReportsCubit({
    required this.orderRepository,
    required this.expenseRepository,
  }) : super(AdminReportsInitial());

  Future<void> fetchReports() async {
    emit(AdminReportsLoading());
    try {
      final orders = await orderRepository.getOrders();
      final expenses = await expenseRepository.getExpenses();

      // Sort orders descending
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final activeIncome = orders.where((o) => o.status.toLowerCase() == 'success').toList();
      final double totalIncome = activeIncome.fold(0.0, (sum, o) => sum + o.total);
      final double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final double avgTicket = activeIncome.isEmpty ? 0.0 : totalIncome / activeIncome.length;

      emit(AdminReportsLoaded(
        incomeOrders: orders,
        expenses: expenses,
        incomePaymentStatus: 'All',
        selectedExpenseCategory: 'All',
        expenseSearchQuery: '',
        totalIncomeSum: totalIncome,
        totalIncomeTransactions: activeIncome.length,
        averageTransactionValue: avgTicket,
        totalExpenseSum: totalExpenses,
      ));
    } catch (e) {
      emit(AdminReportsError(e.toString()));
    }
  }

  Future<void> refreshReports({String? successMsg, String? errorMsg}) async {
    final currentState = state;
    if (currentState is AdminReportsLoaded) {
      try {
        final orders = await orderRepository.getOrders();
        final expenses = await expenseRepository.getExpenses(
          category: currentState.selectedExpenseCategory,
          searchQuery: currentState.expenseSearchQuery,
          startDate: currentState.expenseStartDate,
          endDate: currentState.expenseEndDate,
        );

        // Sort descending
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Recompute sums with current filters
        _emitWithRecomputations(
          currentState: currentState,
          allOrders: orders,
          allExpenses: expenses,
          successMsg: successMsg,
          errorMsg: errorMsg,
        );
      } catch (e) {
        emit(AdminReportsError(e.toString()));
      }
    } else {
      await fetchReports();
    }
  }

  void updateIncomeFilters({
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final currentState = state;
    if (currentState is AdminReportsLoaded) {
      final orders = await orderRepository.getOrders();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final updatedState = currentState.copyWith(
        incomePaymentStatus: paymentStatus ?? currentState.incomePaymentStatus,
        incomeStartDate: startDate ?? currentState.incomeStartDate,
        incomeEndDate: endDate ?? currentState.incomeEndDate,
        actionSuccessMessage: () => null,
        actionErrorMessage: () => null,
      );

      _emitWithRecomputations(
        currentState: updatedState,
        allOrders: orders,
        allExpenses: currentState.expenses,
      );
    }
  }

  void updateExpenseFilters({
    String? category,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final currentState = state;
    if (currentState is AdminReportsLoaded) {
      final updatedState = currentState.copyWith(
        selectedExpenseCategory: category ?? currentState.selectedExpenseCategory,
        expenseSearchQuery: query ?? currentState.expenseSearchQuery,
        expenseStartDate: startDate ?? currentState.expenseStartDate,
        expenseEndDate: endDate ?? currentState.expenseEndDate,
        actionSuccessMessage: () => null,
        actionErrorMessage: () => null,
      );

      // Re-fetch with data source filters
      final filteredExpenses = await expenseRepository.getExpenses(
        category: updatedState.selectedExpenseCategory,
        searchQuery: updatedState.expenseSearchQuery,
        startDate: updatedState.expenseStartDate,
        endDate: updatedState.expenseEndDate,
      );

      _emitWithRecomputations(
        currentState: updatedState,
        allOrders: currentState.incomeOrders,
        allExpenses: filteredExpenses,
      );
    }
  }

  void _emitWithRecomputations({
    required AdminReportsLoaded currentState,
    required List<OrderEntity> allOrders,
    required List<Expense> allExpenses,
    String? successMsg,
    String? errorMsg,
  }) {
    // 1. Calculate filtered income metrics
    Iterable<OrderEntity> filteredOrders = allOrders;
    if (currentState.incomePaymentStatus != 'All') {
      filteredOrders = filteredOrders.where((o) =>
          o.status.toLowerCase() == currentState.incomePaymentStatus.toLowerCase());
    }
    if (currentState.incomeStartDate != null) {
      final start = DateTime(
        currentState.incomeStartDate!.year,
        currentState.incomeStartDate!.month,
        currentState.incomeStartDate!.day,
      );
      filteredOrders = filteredOrders.where((o) => o.createdAt.isAfter(start) || o.createdAt.isAtSameMomentAs(start));
    }
    if (currentState.incomeEndDate != null) {
      final end = DateTime(
        currentState.incomeEndDate!.year,
        currentState.incomeEndDate!.month,
        currentState.incomeEndDate!.day,
        23,
        59,
        59,
      );
      filteredOrders = filteredOrders.where((o) => o.createdAt.isBefore(end) || o.createdAt.isAtSameMomentAs(end));
    }

    final activeIncome = filteredOrders.where((o) => o.status.toLowerCase() == 'success').toList();
    final double totalIncome = activeIncome.fold(0.0, (sum, o) => sum + o.total);
    final double avgTicket = activeIncome.isEmpty ? 0.0 : totalIncome / activeIncome.length;

    // 2. Calculate filtered expense metrics
    final double totalExpenses = allExpenses.fold(0.0, (sum, e) => sum + e.amount);

    emit(currentState.copyWith(
      incomeOrders: allOrders,
      expenses: allExpenses,
      totalIncomeSum: totalIncome,
      totalIncomeTransactions: activeIncome.length,
      averageTransactionValue: avgTicket,
      totalExpenseSum: totalExpenses,
      actionSuccessMessage: () => successMsg,
      actionErrorMessage: () => errorMsg,
    ));
  }

  // Expense CRUD
  Future<void> addExpense(Expense expense) async {
    try {
      await expenseRepository.addExpense(expense);
      refreshReports(successMsg: 'Expense of ${expense.amount} added successfully');
    } catch (e) {
      refreshReports(errorMsg: 'Failed to add expense: ${e.toString()}');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await expenseRepository.updateExpense(expense);
      refreshReports(successMsg: 'Expense updated successfully');
    } catch (e) {
      refreshReports(errorMsg: 'Failed to update expense: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await expenseRepository.deleteExpense(id);
      refreshReports(successMsg: 'Expense deleted successfully');
    } catch (e) {
      refreshReports(errorMsg: 'Failed to delete expense: ${e.toString()}');
    }
  }

  Future<void> updateOrder(OrderEntity order) async {
    try {
      await orderRepository.updateOrder(order);
      await refreshReports(successMsg: 'Order ${order.id} updated successfully');
    } catch (e) {
      await refreshReports(errorMsg: 'Failed to update order: ${e.toString()}');
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await orderRepository.deleteOrder(id);
      await refreshReports(successMsg: 'Order $id deleted successfully');
    } catch (e) {
      await refreshReports(errorMsg: 'Failed to delete order: ${e.toString()}');
    }
  }

  void clearMessages() {
    final currentState = state;
    if (currentState is AdminReportsLoaded) {
      emit(currentState.copyWith(
        actionSuccessMessage: () => null,
        actionErrorMessage: () => null,
      ));
    }
  }
}
