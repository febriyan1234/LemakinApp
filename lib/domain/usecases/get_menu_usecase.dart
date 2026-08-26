import '../entities/menu_item.dart';
import '../entities/menu_category.dart';
import '../repositories/menu_repository.dart';

class GetMenuUseCase {
  final MenuRepository repository;

  GetMenuUseCase(this.repository);

  Future<List<MenuCategory>> getCategories() {
    return repository.getCategories();
  }

  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) {
    return repository.getMenuItems(
      categoryId: categoryId,
      searchQuery: searchQuery,
      includeInactive: includeInactive,
    );
  }

  Future<List<MenuItem>> getRecommendedItems({bool includeInactive = false}) {
    return repository.getRecommendedItems(includeInactive: includeInactive);
  }
}
