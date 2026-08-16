import 'package:equatable/equatable.dart';

class MenuCategory extends Equatable {
  final String id;
  final String name;

  const MenuCategory({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
