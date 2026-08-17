import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    String? category,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}
