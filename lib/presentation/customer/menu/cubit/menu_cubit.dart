import 'package:flutter_bloc/flutter_bloc.dart';
import 'menu_state.dart';
import '../../../../domain/usecases/get_menu_usecase.dart';

class MenuCubit extends Cubit<MenuState> {
  final GetMenuUseCase getMenuUseCase;

  MenuCubit({required this.getMenuUseCase}) : super(MenuInitial());

  Future<void> fetchMenu() async {
    emit(MenuLoading());
    try {
      final categories = await getMenuUseCase.getCategories();
      final items = await getMenuUseCase.getMenuItems(categoryId: 'All');
      final recommended = await getMenuUseCase.getRecommendedItems();

      emit(
        MenuLoaded(
          categories: categories,
          menuItems: items,
          recommendedItems: recommended,
          selectedCategoryId: 'All',
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(MenuError(e.toString()));
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
