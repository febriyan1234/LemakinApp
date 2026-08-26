import 'package:equatable/equatable.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/entities/menu_category.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuCategory> categories;
  final List<MenuItem> menuItems;
  final List<MenuItem> allMenuItems;
  final List<MenuItem> recommendedItems;
  final List<MenuItem> bestSellers;
  final String selectedCategoryId; // 'All' or specific id
  final String searchQuery;
  final bool isLoading;

  const MenuLoaded({
    required this.categories,
    required this.menuItems,
    required this.allMenuItems,
    required this.recommendedItems,
    required this.bestSellers,
    this.selectedCategoryId = 'All',
    this.searchQuery = '',
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
    categories,
    menuItems,
    allMenuItems,
    recommendedItems,
    bestSellers,
    selectedCategoryId,
    searchQuery,
    isLoading,
  ];

  MenuLoaded copyWith({
    List<MenuCategory>? categories,
    List<MenuItem>? menuItems,
    List<MenuItem>? allMenuItems,
    List<MenuItem>? recommendedItems,
    List<MenuItem>? bestSellers,
    String? selectedCategoryId,
    String? searchQuery,
    bool? isLoading,
  }) {
    return MenuLoaded(
      categories: categories ?? this.categories,
      menuItems: menuItems ?? this.menuItems,
      allMenuItems: allMenuItems ?? this.allMenuItems,
      recommendedItems: recommendedItems ?? this.recommendedItems,
      bestSellers: bestSellers ?? this.bestSellers,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MenuError extends MenuState {
  final String message;

  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}
