import 'package:equatable/equatable.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/entities/menu_category.dart';

abstract class AdminMenuState extends Equatable {
  const AdminMenuState();

  @override
  List<Object?> get props => [];
}

class AdminMenuInitial extends AdminMenuState {}

class AdminMenuLoading extends AdminMenuState {}

class AdminMenuLoaded extends AdminMenuState {
  final List<MenuItem> menuItems;
  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final String selectedStatus;
  final String searchQuery;
  final String sortBy;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminMenuLoaded({
    required this.menuItems,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedStatus,
    required this.searchQuery,
    required this.sortBy,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  AdminMenuLoaded copyWith({
    List<MenuItem>? menuItems,
    List<MenuCategory>? categories,
    String? selectedCategoryId,
    String? selectedStatus,
    String? searchQuery,
    String? sortBy,
    String? Function()? actionSuccessMessage,
    String? Function()? actionErrorMessage,
  }) {
    return AdminMenuLoaded(
      menuItems: menuItems ?? this.menuItems,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      actionSuccessMessage: actionSuccessMessage != null ? actionSuccessMessage() : this.actionSuccessMessage,
      actionErrorMessage: actionErrorMessage != null ? actionErrorMessage() : this.actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        menuItems,
        categories,
        selectedCategoryId,
        selectedStatus,
        searchQuery,
        sortBy,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

class AdminMenuError extends AdminMenuState {
  final String message;

  const AdminMenuError(this.message);

  @override
  List<Object?> get props => [message];
}
