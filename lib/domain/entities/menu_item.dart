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
  final int minSelections;
  final int maxSelections;

  const MenuVariant({
    required this.id,
    required this.name,
    this.isRequired = false,
    required this.options,
    this.minSelections = 1,
    this.maxSelections = 1,
  });

  MenuVariant copyWith({
    String? id,
    String? name,
    bool? isRequired,
    List<VariantOption>? options,
    int? minSelections,
    int? maxSelections,
  }) {
    return MenuVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isRequired,
        options,
        minSelections,
        maxSelections,
      ];
}

class MenuItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final bool isRecommended;
  final String categoryId;
  final List<MenuVariant> variants;
  final int stock;
  final bool isActive;
  final int orderIndex;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.isRecommended = false,
    required this.categoryId,
    this.variants = const [],
    this.stock = 50,
    this.isActive = true,
    this.orderIndex = 0,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? imageUrl,
    bool? isRecommended,
    String? categoryId,
    List<MenuVariant>? variants,
    int? stock,
    bool? isActive,
    int? orderIndex,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isRecommended: isRecommended ?? this.isRecommended,
      categoryId: categoryId ?? this.categoryId,
      variants: variants ?? this.variants,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        originalPrice,
        imageUrl,
        isRecommended,
        categoryId,
        variants,
        stock,
        isActive,
        orderIndex,
      ];
}
