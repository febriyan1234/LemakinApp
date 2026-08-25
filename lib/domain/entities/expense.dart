import 'package:equatable/equatable.dart';

class ExpenseItem extends Equatable {
  final String name;
  final double price;

  const ExpenseItem({required this.name, required this.price});

  @override
  List<Object?> get props => [name, price];
}

class Expense extends Equatable {
  final String id;
  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final String? notes;
  final String createdBy;
  final List<ExpenseItem>? items;

  const Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    this.notes,
    required this.createdBy,
    this.items,
  });

  Expense copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? description,
    double? amount,
    String? notes,
    String? createdBy,
    List<ExpenseItem>? items,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        category,
        description,
        amount,
        notes,
        createdBy,
        items,
      ];
}
