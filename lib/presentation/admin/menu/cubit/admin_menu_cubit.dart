import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/entities/menu_category.dart';
import '../../../../domain/repositories/menu_repository.dart';
import '../../../../domain/usecases/admin_menu_usecase.dart';
import 'admin_menu_state.dart';

class AdminMenuCubit extends Cubit<AdminMenuState> {
  final MenuRepository menuRepository;
  final AdminMenuUseCase adminMenuUseCase;

  AdminMenuCubit({required this.menuRepository, required this.adminMenuUseCase})
    : super(AdminMenuInitial());

  Future<void> fetchMenus() async {
    emit(AdminMenuLoading());
    try {
      final categories = await menuRepository.getCategories();
      final items = await menuRepository.getMenuItems(includeInactive: true);
      final variants = await adminMenuUseCase.getVariants();

      emit(
        AdminMenuLoaded(
          menuItems: items,
          categories: categories,
          variants: variants,
          selectedCategoryId: 'All',
          selectedStatus: 'All',
          searchQuery: '',
          sortBy: 'Custom',
        ),
      );
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> refreshMenus({String? successMsg, String? errorMsg}) async {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      try {
        final items = await menuRepository.getMenuItems(includeInactive: true);
        final categories = await menuRepository.getCategories();
        final variants = await adminMenuUseCase.getVariants();
        emit(
          currentState.copyWith(
            menuItems: items,
            categories: categories,
            variants: variants,
            actionSuccessMessage: () => successMsg,
            actionErrorMessage: () => errorMsg,
          ),
        );
      } catch (e) {
        emit(AdminMenuError(e.toString()));
      }
    } else {
      fetchMenus();
    }
  }

  void updateFilters({
    String? categoryId,
    String? status,
    String? searchQuery,
    String? sortBy,
  }) {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      emit(
        currentState.copyWith(
          selectedCategoryId: categoryId ?? currentState.selectedCategoryId,
          selectedStatus: status ?? currentState.selectedStatus,
          searchQuery: searchQuery ?? currentState.searchQuery,
          sortBy: sortBy ?? currentState.sortBy,
          actionSuccessMessage: () => null,
          actionErrorMessage: () => null,
        ),
      );
    }
  }

  List<MenuItem> getFilteredItems(AdminMenuLoaded loadedState) {
    Iterable<MenuItem> items = loadedState.menuItems;

    // Category filter
    if (loadedState.selectedCategoryId != 'All' &&
        loadedState.selectedCategoryId.isNotEmpty) {
      items = items.where(
        (item) => item.categoryId == loadedState.selectedCategoryId,
      );
    }

    // Status filter
    if (loadedState.selectedStatus == 'Active') {
      items = items.where((item) => item.isActive);
    } else if (loadedState.selectedStatus == 'Inactive') {
      items = items.where((item) => !item.isActive);
    }

    // Search query
    if (loadedState.searchQuery.trim().isNotEmpty) {
      final query = loadedState.searchQuery.toLowerCase().trim();
      items = items.where((item) => item.name.toLowerCase().contains(query));
    }

    // Sorting (Always custom/orderIndex)
    final list = items.toList();
    list.sort((a, b) => (a.orderIndex).compareTo(b.orderIndex));

    return list;
  }

  Future<void> addMenu(MenuItem item) async {
    try {
      await adminMenuUseCase.addMenuItem(item);
      refreshMenus(successMsg: 'Menu "${item.name}" added successfully');
    } catch (e) {
      refreshMenus(errorMsg: 'Failed to add menu: ${e.toString()}');
    }
  }

  Future<void> updateMenu(MenuItem item) async {
    try {
      await adminMenuUseCase.updateMenuItem(item);
      refreshMenus(successMsg: 'Menu "${item.name}" updated successfully');
    } catch (e) {
      refreshMenus(errorMsg: 'Failed to update menu: ${e.toString()}');
    }
  }

  Future<void> deleteMenu(String id, String name) async {
    try {
      await adminMenuUseCase.deleteMenuItem(id);
      refreshMenus(successMsg: 'Menu "$name" deleted successfully');
    } catch (e) {
      refreshMenus(errorMsg: 'Failed to delete menu: ${e.toString()}');
    }
  }

  Future<void> toggleMenuStatus(String id) async {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      try {
        final item = currentState.menuItems.firstWhere(
          (element) => element.id == id,
        );
        final updatedItem = item.copyWith(isActive: !item.isActive);
        await adminMenuUseCase.updateMenuItem(updatedItem);

        final newStatusStr = updatedItem.isActive ? 'Active' : 'Inactive';
        refreshMenus(successMsg: 'Menu "${item.name}" is now $newStatusStr');
      } catch (e) {
        refreshMenus(errorMsg: 'Failed to update menu status');
      }
    }
  }

  Future<void> adjustStock(String id, int newStock) async {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      try {
        final item = currentState.menuItems.firstWhere(
          (element) => element.id == id,
        );

        // Auto-disable if stock reaches 0 and admin chooses
        bool shouldDisable = newStock == 0;
        final updatedItem = item.copyWith(
          stock: newStock,
          isActive: shouldDisable ? false : item.isActive,
        );
        await adminMenuUseCase.updateMenuItem(updatedItem);

        String msg = 'Stock for "${item.name}" updated to $newStock';
        if (shouldDisable) {
          msg += ' and marked Inactive (Out of Stock)';
        }
        refreshMenus(successMsg: msg);
      } catch (e) {
        refreshMenus(errorMsg: 'Failed to update menu stock');
      }
    }
  }

  void clearMessages() {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      emit(
        currentState.copyWith(
          actionSuccessMessage: () => null,
          actionErrorMessage: () => null,
        ),
      );
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final currentState = state;
      int orderIndex = 0;
      if (currentState is AdminMenuLoaded) {
        orderIndex = currentState.categories.length;
      }
      final category = MenuCategory(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        orderIndex: orderIndex,
      );
      await adminMenuUseCase.addCategory(category);
      fetchMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> editCategory(String id, String newName) async {
    try {
      final currentState = state;
      int existingOrderIndex = 0;
      if (currentState is AdminMenuLoaded) {
        try {
          final existingCat = currentState.categories.firstWhere((cat) => cat.id == id);
          existingOrderIndex = existingCat.orderIndex;
        } catch (_) {}
      }
      final category = MenuCategory(id: id, name: newName, orderIndex: existingOrderIndex);
      await adminMenuUseCase.updateCategory(category);
      fetchMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await adminMenuUseCase.deleteCategory(id);
      fetchMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> addVariant(MenuVariant variant) async {
    try {
      await adminMenuUseCase.addVariant(variant);
      fetchMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> editVariant(MenuVariant variant) async {
    try {
      await adminMenuUseCase.updateVariant(variant);
      fetchMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> deleteVariant(String id) async {
    try {
      await adminMenuUseCase.deleteVariant(id);
      fetchMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
    }
  }

  Future<void> reorderCategories(List<MenuCategory> reorderedCategories) async {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      emit(currentState.copyWith(categories: reorderedCategories));
    }
    try {
      for (int i = 0; i < reorderedCategories.length; i++) {
        final updatedCat = reorderedCategories[i].copyWith(orderIndex: i);
        await adminMenuUseCase.updateCategory(updatedCat);
      }
      refreshMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
      fetchMenus();
    }
  }

  Future<void> reorderMenuItems(List<MenuItem> reorderedItems) async {
    final currentState = state;
    if (currentState is AdminMenuLoaded) {
      emit(currentState.copyWith(menuItems: reorderedItems));
    }
    try {
      for (int i = 0; i < reorderedItems.length; i++) {
        final updatedItem = reorderedItems[i].copyWith(orderIndex: i);
        await adminMenuUseCase.updateMenuItem(updatedItem);
      }
      refreshMenus();
    } catch (e) {
      emit(AdminMenuError(e.toString()));
      fetchMenus();
    }
  }
}
