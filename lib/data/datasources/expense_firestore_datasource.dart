import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';
import 'expense_local_datasource.dart';

class ExpenseFirestoreDataSourceImpl implements ExpenseLocalDataSource {
  final FirebaseFirestore _firestore;

  ExpenseFirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Expense>> getExpenses({
    String? category,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore.collection('expenses');

    if (category != null && category != 'All' && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    List<Expense> expenses = snapshot.docs
        .map((doc) => _expenseFromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryStr = searchQuery.toLowerCase().trim();
      expenses = expenses
          .where((e) =>
              e.description.toLowerCase().contains(queryStr) ||
              e.category.toLowerCase().contains(queryStr))
          .toList();
    }

    if (startDate != null) {
      final normalizedStart =
          DateTime(startDate.year, startDate.month, startDate.day);
      expenses = expenses
          .where((e) =>
              e.date.isAfter(normalizedStart) ||
              e.date.isAtSameMomentAs(normalizedStart))
          .toList();
    }

    if (endDate != null) {
      final normalizedEnd =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      expenses = expenses
          .where((e) =>
              e.date.isBefore(normalizedEnd) ||
              e.date.isAtSameMomentAs(normalizedEnd))
          .toList();
    }

    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await _firestore
        .collection('expenses')
        .doc(expense.id)
        .set(_expenseToMap(expense));
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _firestore
        .collection('expenses')
        .doc(expense.id)
        .update(_expenseToMap(expense));
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'date': Timestamp.fromDate(expense.date),
      'category': expense.category,
      'description': expense.description,
      'amount': expense.amount,
      'notes': expense.notes,
      'createdBy': expense.createdBy,
    };
  }

  Expense _expenseFromMap(Map<String, dynamic> map) {
    final dateRaw = map['date'];
    DateTime date;
    if (dateRaw is Timestamp) {
      date = dateRaw.toDate();
    } else if (dateRaw is String) {
      date = DateTime.parse(dateRaw);
    } else {
      date = DateTime.now();
    }

    return Expense(
      id: map['id'] as String? ?? '',
      date: date,
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
    );
  }
}
