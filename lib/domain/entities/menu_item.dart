import 'package:equatable/equatable.dart';

class VariantOption extends Equatable {
  final String id;
  final String name;
  final double additionalPrice;

  const VariantOption({
    required this.id,
    required this.name,
    this.additionalPrice = 0.0,
  });

  @override
  List<Object?> get props => [id, name, additionalPrice];
}

class MenuVariant extends Equatable {
  final String id;
  final String name; // e.g. "Flavor", "Size"
  final bool isRequired;
  final List<VariantOption> options;

  const MenuVariant({
    required this.id,
    required this.name,
    this.isRequired = false,
    required this.options,
  });

  @override
  List<Object?> get props => [id, name, isRequired, options];
}

class MenuItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isRecommended;
  final String categoryId;
  final List<MenuVariant> variants;
  final int stock;
  final bool isActive;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isRecommended = false,
    required this.categoryId,
    this.variants = const [],
    this.stock = 50,
    this.isActive = true,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isRecommended,
    String? categoryId,
    List<MenuVariant>? variants,
    int? stock,
    bool? isActive,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isRecommended: isRecommended ?? this.isRecommended,
      categoryId: categoryId ?? this.categoryId,
      variants: variants ?? this.variants,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        imageUrl,
        isRecommended,
        categoryId,
        variants,
        stock,
        isActive,
      ];
}
