import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

class GetMenuDetailUseCase {
  final MenuRepository repository;

  GetMenuDetailUseCase(this.repository);

  Future<MenuItem?> execute(String id) {
    return repository.getMenuItemDetail(id);
  }
}
