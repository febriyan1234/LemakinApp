import 'package:equatable/equatable.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/expense.dart';

abstract class AdminReportsState extends Equatable {
  const AdminReportsState();

  @override
  List<Object?> get props => [];
}

class AdminReportsInitial extends AdminReportsState {}

class AdminReportsLoading extends AdminReportsState {}

class AdminReportsLoaded extends AdminReportsState {
  final List<OrderEntity> incomeOrders;
  final List<Expense> expenses;
  
  // Filters for Income
  final String incomePaymentStatus;
  final DateTime? incomeStartDate;
  final DateTime? incomeEndDate;
  
  // Filters for Expense
  final String selectedExpenseCategory;
  final String expenseSearchQuery;
  final DateTime? expenseStartDate;
  final DateTime? expenseEndDate;
  
  // Computed values
  final double totalIncomeSum;
  final int totalIncomeTransactions;
  final double averageTransactionValue;
  final double totalExpenseSum;
  
  // Status feedback
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminReportsLoaded({
    required this.incomeOrders,
    required this.expenses,
    required this.incomePaymentStatus,
    this.incomeStartDate,
    this.incomeEndDate,
    required this.selectedExpenseCategory,
    required this.expenseSearchQuery,
    this.expenseStartDate,
    this.expenseEndDate,
    required this.totalIncomeSum,
    required this.totalIncomeTransactions,
    required this.averageTransactionValue,
    required this.totalExpenseSum,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  AdminReportsLoaded copyWith({
    List<OrderEntity>? incomeOrders,
    List<Expense>? expenses,
    String? incomePaymentStatus,
    DateTime? incomeStartDate,
    DateTime? incomeEndDate,
    String? selectedExpenseCategory,
    String? expenseSearchQuery,
    DateTime? expenseStartDate,
    DateTime? expenseEndDate,
    double? totalIncomeSum,
    int? totalIncomeTransactions,
    double? averageTransactionValue,
    double? totalExpenseSum,
    String? Function()? actionSuccessMessage,
    String? Function()? actionErrorMessage,
  }) {
    return AdminReportsLoaded(
      incomeOrders: incomeOrders ?? this.incomeOrders,
      expenses: expenses ?? this.expenses,
      incomePaymentStatus: incomePaymentStatus ?? this.incomePaymentStatus,
      incomeStartDate: incomeStartDate ?? this.incomeStartDate,
      incomeEndDate: incomeEndDate ?? this.incomeEndDate,
      selectedExpenseCategory: selectedExpenseCategory ?? this.selectedExpenseCategory,
      expenseSearchQuery: expenseSearchQuery ?? this.expenseSearchQuery,
      expenseStartDate: expenseStartDate ?? this.expenseStartDate,
      expenseEndDate: expenseEndDate ?? this.expenseEndDate,
      totalIncomeSum: totalIncomeSum ?? this.totalIncomeSum,
      totalIncomeTransactions: totalIncomeTransactions ?? this.totalIncomeTransactions,
      averageTransactionValue: averageTransactionValue ?? this.averageTransactionValue,
      totalExpenseSum: totalExpenseSum ?? this.totalExpenseSum,
      actionSuccessMessage: actionSuccessMessage != null ? actionSuccessMessage() : this.actionSuccessMessage,
      actionErrorMessage: actionErrorMessage != null ? actionErrorMessage() : this.actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        incomeOrders,
        expenses,
        incomePaymentStatus,
        incomeStartDate,
        incomeEndDate,
        selectedExpenseCategory,
        expenseSearchQuery,
        expenseStartDate,
        expenseEndDate,
        totalIncomeSum,
        totalIncomeTransactions,
        averageTransactionValue,
        totalExpenseSum,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

class AdminReportsError extends AdminReportsState {
  final String message;

  const AdminReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
