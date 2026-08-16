import '../entities/menu_item.dart';
import '../entities/menu_category.dart';
import '../repositories/menu_repository.dart';

class GetMenuUseCase {
  final MenuRepository repository;

  GetMenuUseCase(this.repository);

  Future<List<MenuCategory>> getCategories() {
    return repository.getCategories();
  }

  Future<List<MenuItem>> getMenuItems({String? categoryId, String? searchQuery}) {
    return repository.getMenuItems(categoryId: categoryId, searchQuery: searchQuery);
  }

  Future<List<MenuItem>> getRecommendedItems() {
    return repository.getRecommendedItems();
  }
}
