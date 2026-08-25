import 'package:equatable/equatable.dart';

class MenuCategory extends Equatable {
  final String id;
  final String name;
  final int orderIndex;

  const MenuCategory({
    required this.id,
    required this.name,
    this.orderIndex = 0,
  });

  MenuCategory copyWith({
    String? id,
    String? name,
    int? orderIndex,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  List<Object?> get props => [id, name, orderIndex];
}
