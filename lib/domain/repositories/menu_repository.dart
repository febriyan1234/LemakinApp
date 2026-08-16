import '../entities/menu_item.dart';
import '../entities/menu_category.dart';

abstract class MenuRepository {
  Future<List<MenuCategory>> getCategories();
  Future<List<MenuItem>> getMenuItems({String? categoryId, String? searchQuery});
  Future<MenuItem?> getMenuItemDetail(String id);
  Future<List<MenuItem>> getRecommendedItems();
}
