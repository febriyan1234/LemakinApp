import '../../domain/entities/expense.dart';

abstract class ExpenseLocalDataSource {
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

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final List<Expense> _expenses = [];

  ExpenseLocalDataSourceImpl() {
    // Populate mock expenses over the last 30 days
    final now = DateTime.now();
    _expenses.addAll([
      Expense(
        id: 'EXP_001',
        date: now.subtract(const Duration(days: 28)),
        category: 'Internet',
        description: 'Monthly Fiber Internet Bill',
        amount: 350000,
        notes: 'Paid via auto-debit',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_002',
        date: now.subtract(const Duration(days: 25)),
        category: 'Raw Materials',
        description: 'Purchase meat & chicken stock',
        amount: 1500000,
        notes: 'Supplier: Jaya Meat',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_003',
        date: now.subtract(const Duration(days: 20)),
        category: 'Electricity',
        description: 'Electricity Bill token',
        amount: 500000,
        notes: 'Token ID: 1234567890',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_004',
        date: now.subtract(const Duration(days: 15)),
        category: 'Salary',
        description: 'Kitchen Helper monthly salary',
        amount: 3000000,
        notes: 'Employee: Andi',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_005',
        date: now.subtract(const Duration(days: 10)),
        category: 'Transportation',
        description: 'Gasoline for delivery motor',
        amount: 120000,
        notes: 'Pertamax fuel',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_006',
        date: now.subtract(const Duration(days: 5)),
        category: 'Raw Materials',
        description: 'Vegetables and spices restocking',
        amount: 800000,
        notes: 'Local market purchase',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_007',
        date: now.subtract(const Duration(days: 2)),
        category: 'Operations',
        description: 'New dishwashing sponges & soap',
        amount: 150000,
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_008',
        date: now,
        category: 'Others',
        description: 'Replacing broken drinking glasses',
        amount: 95000,
        notes: 'Purchased 6 pcs glass cups',
        createdBy: 'Super Admin',
      ),
    ]);
  }

  @override
  Future<List<Expense>> getExpenses({
    String? category,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    Iterable<Expense> filtered = _expenses;

    if (category != null && category != 'All' && category.isNotEmpty) {
      filtered = filtered.where((e) => e.category.toLowerCase() == category.toLowerCase());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((e) =>
          e.description.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query));
    }

    if (startDate != null) {
      // Normalize start date to beginning of day
      final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
      filtered = filtered.where((e) => e.date.isAfter(normalizedStart) || e.date.isAtSameMomentAs(normalizedStart));
    }

    if (endDate != null) {
      // Normalize end date to end of day
      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((e) => e.date.isBefore(normalizedEnd) || e.date.isAtSameMomentAs(normalizedEnd));
    }

    // Sort by date descending
    final list = filtered.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses.add(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
    } else {
      throw Exception('Expense not found');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _expenses.removeWhere((e) => e.id == id);
  }
}
