import 'package:flutter_bloc/flutter_bloc.dart';
import 'menu_state.dart';
import '../../../../domain/usecases/get_menu_usecase.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/repositories/order_repository.dart';

class MenuCubit extends Cubit<MenuState> {
  final GetMenuUseCase getMenuUseCase;
  final OrderRepository orderRepository;

  MenuCubit({required this.getMenuUseCase, required this.orderRepository})
    : super(MenuInitial());

  Future<List<MenuItem>> _getBestSellers(List<MenuItem> allItems) async {
    try {
      final orders = await orderRepository.getOrders();
      final Map<String, int> salesCountMap = {};
      for (final order in orders) {
        if (order.status.toLowerCase() == 'success') {
          for (final item in order.items) {
            final itemId = item.menuItem.id;
            salesCountMap[itemId] =
                (salesCountMap[itemId] ?? 0) + item.quantity;
          }
        }
      }

      final bestSellers = allItems
          .where((item) =>
              item.isActive &&
              item.stock != 0 &&
              (salesCountMap[item.id] ?? 0) > 0)
          .toList();
      bestSellers.sort((a, b) {
        final countA = salesCountMap[a.id] ?? 0;
        final countB = salesCountMap[b.id] ?? 0;
        return countB.compareTo(countA); // descending
      });
      return bestSellers;
    } catch (_) {
      return [];
    }
  }

  Future<void> fetchMenu() async {
    emit(MenuLoading());
    try {
      final categories = await getMenuUseCase.getCategories();
      final items = await getMenuUseCase.getMenuItems(
        categoryId: 'All',
        includeInactive: true,
      );
      final recommended = await getMenuUseCase.getRecommendedItems(
        includeInactive: true,
      );
      final bestSellers = await _getBestSellers(items);

      emit(
        MenuLoaded(
          categories: categories,
          menuItems: items,
          allMenuItems: items,
          recommendedItems: recommended,
          bestSellers: bestSellers,
          selectedCategoryId: 'All',
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  Future<void> refreshMenu() async {
    final currentState = state;
    if (currentState is MenuLoaded) {
      try {
        final categories = await getMenuUseCase.getCategories();
        final items = await getMenuUseCase.getMenuItems(
          categoryId: currentState.selectedCategoryId,
          searchQuery: currentState.searchQuery,
          includeInactive: true,
        );
        final allItems = await getMenuUseCase.getMenuItems(
          categoryId: 'All',
          includeInactive: true,
        );
        final recommended = await getMenuUseCase.getRecommendedItems(
          includeInactive: true,
        );
        final bestSellers = await _getBestSellers(allItems);

        emit(
          currentState.copyWith(
            categories: categories,
            menuItems: items,
            allMenuItems: allItems,
            recommendedItems: recommended,
            bestSellers: bestSellers,
          ),
        );
      } catch (e) {
        emit(MenuError(e.toString()));
      }
    } else {
      await fetchMenu();
    }
  }

  Future<void> selectCategory(String categoryId) async {
    final currentState = state;
    if (currentState is MenuLoaded) {
      emit(
        currentState.copyWith(isLoading: true, selectedCategoryId: categoryId),
      );
      try {
        final items = await getMenuUseCase.getMenuItems(
          categoryId: categoryId,
          searchQuery: currentState.searchQuery,
          includeInactive: true,
        );
        emit(
          currentState.copyWith(
            menuItems: items,
            selectedCategoryId: categoryId,
            isLoading: false,
          ),
        );
      } catch (e) {
        emit(MenuError(e.toString()));
      }
    }
  }

  Future<void> searchMenu(String query) async {
    final currentState = state;
    if (currentState is MenuLoaded) {
      emit(currentState.copyWith(isLoading: true, searchQuery: query));
      try {
        final items = await getMenuUseCase.getMenuItems(
          categoryId: query.trim().isNotEmpty
              ? 'All'
              : currentState.selectedCategoryId,
          searchQuery: query,
          includeInactive: true,
        );
        emit(
          currentState.copyWith(
            menuItems: items,
            selectedCategoryId: query.trim().isNotEmpty
                ? 'All'
                : currentState.selectedCategoryId,
            searchQuery: query,
            isLoading: false,
          ),
        );
      } catch (e) {
        emit(MenuError(e.toString()));
      }
    }
  }
}
