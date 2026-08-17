import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Expense>> getExpenses({
    String? category,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return localDataSource.getExpenses(
      category: category,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> addExpense(Expense expense) {
    return localDataSource.addExpense(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) {
    return localDataSource.updateExpense(expense);
  }

  @override
  Future<void> deleteExpense(String id) {
    return localDataSource.deleteExpense(id);
  }
}
