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
}
