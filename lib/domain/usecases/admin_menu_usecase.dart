import '../entities/menu_item.dart';
import '../entities/menu_category.dart';
import '../repositories/menu_repository.dart';

class AdminMenuUseCase {
  final MenuRepository repository;

  AdminMenuUseCase(this.repository);

  Future<void> addMenuItem(MenuItem item) {
    return repository.addMenuItem(item);
  }

  Future<void> updateMenuItem(MenuItem item) {
    return repository.updateMenuItem(item);
  }

  Future<void> deleteMenuItem(String id) {
    return repository.deleteMenuItem(id);
  }

  Future<void> addCategory(MenuCategory category) {
    return repository.addCategory(category);
  }

  Future<void> updateCategory(MenuCategory category) {
    return repository.updateCategory(category);
  }

  Future<void> deleteCategory(String id) {
    return repository.deleteCategory(id);
  }

  Future<List<MenuVariant>> getVariants() {
    return repository.getVariants();
  }

  Future<void> addVariant(MenuVariant variant) {
    return repository.addVariant(variant);
  }

  Future<void> updateVariant(MenuVariant variant) {
    return repository.updateVariant(variant);
  }

  Future<void> deleteVariant(String id) {
    return repository.deleteVariant(id);
  }
}
