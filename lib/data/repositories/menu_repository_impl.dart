import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_local_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuLocalDataSource localDataSource;

  MenuRepositoryImpl({required this.localDataSource});

  @override
  Future<List<MenuCategory>> getCategories() {
    return localDataSource.getCategories();
  }

  @override
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) {
    return localDataSource.getMenuItems(
      categoryId: categoryId,
      searchQuery: searchQuery,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<MenuItem?> getMenuItemDetail(String id) {
    return localDataSource.getMenuItemDetail(id);
  }

  @override
  Future<List<MenuItem>> getRecommendedItems() {
    return localDataSource.getRecommendedItems();
  }

  @override
  Future<void> addMenuItem(MenuItem item) {
    return localDataSource.addMenuItem(item);
  }

  @override
  Future<void> updateMenuItem(MenuItem item) {
    return localDataSource.updateMenuItem(item);
  }

  @override
  Future<void> deleteMenuItem(String id) {
    return localDataSource.deleteMenuItem(id);
  }

  @override
  Future<void> addCategory(MenuCategory category) {
    return localDataSource.addCategory(category);
  }
}
