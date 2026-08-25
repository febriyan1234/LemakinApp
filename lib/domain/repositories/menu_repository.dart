import '../entities/menu_item.dart';
import '../entities/menu_category.dart';

abstract class MenuRepository {
  Future<List<MenuCategory>> getCategories();
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  });
  Future<MenuItem?> getMenuItemDetail(String id);
  Future<List<MenuItem>> getRecommendedItems();

  // Admin CRUD methods
  Future<void> addMenuItem(MenuItem item);
  Future<void> updateMenuItem(MenuItem item);
  Future<void> deleteMenuItem(String id);
  Future<void> addCategory(MenuCategory category);
  Future<void> updateCategory(MenuCategory category);
  Future<void> deleteCategory(String id);
  Future<List<MenuVariant>> getVariants();
  Future<void> addVariant(MenuVariant variant);
  Future<void> updateVariant(MenuVariant variant);
  Future<void> deleteVariant(String id);
}
