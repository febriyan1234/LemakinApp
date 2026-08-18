import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_item.dart';
import 'menu_local_datasource.dart';

class MenuFirestoreDataSourceImpl implements MenuLocalDataSource {
  final FirebaseFirestore _firestore;

  MenuFirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<MenuCategory>> getCategories() async {
    final snapshot = await _firestore.collection('menu_categories').get();
    return snapshot.docs.map((doc) => _categoryFromMap(doc.data())).toList();
  }

  @override
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) async {
    Query query = _firestore.collection('menu_items');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.get();
    List<MenuItem> items = snapshot.docs
        .map((doc) => _menuItemFromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchLower = searchQuery.toLowerCase().trim();
      items = items
          .where((item) =>
              item.name.toLowerCase().contains(searchLower) ||
              item.description.toLowerCase().contains(searchLower))
          .toList();
    }

    return items;
  }

  @override
  Future<MenuItem?> getMenuItemDetail(String id) async {
    final doc = await _firestore.collection('menu_items').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return _menuItemFromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<List<MenuItem>> getRecommendedItems() async {
    final snapshot = await _firestore
        .collection('menu_items')
        .where('isRecommended', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => _menuItemFromMap(doc.data())).toList();
  }

  @override
  Future<void> addMenuItem(MenuItem item) async {
    await _firestore
        .collection('menu_items')
        .doc(item.id)
        .set(_menuItemToMap(item));
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    await _firestore
        .collection('menu_items')
        .doc(item.id)
        .update(_menuItemToMap(item));
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    await _firestore.collection('menu_items').doc(id).delete();
  }

  @override
  Future<void> addCategory(MenuCategory category) async {
    await _firestore
        .collection('menu_categories')
        .doc(category.id)
        .set(_categoryToMap(category));
  }

  Map<String, dynamic> _categoryToMap(MenuCategory category) {
    return {
      'id': category.id,
      'name': category.name,
    };
  }

  MenuCategory _categoryFromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> _menuItemToMap(MenuItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'imageUrl': item.imageUrl,
      'isRecommended': item.isRecommended,
      'categoryId': item.categoryId,
      'stock': item.stock,
      'isActive': item.isActive,
      'variants': item.variants
          .map((v) => {
                'id': v.id,
                'name': v.name,
                'isRequired': v.isRequired,
                'options': v.options
                    .map((o) => {
                          'id': o.id,
                          'name': o.name,
                          'additionalPrice': o.additionalPrice,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  MenuItem _menuItemFromMap(Map<String, dynamic> map) {
    final variantsRaw = map['variants'] as List? ?? [];
    final variants = variantsRaw.map((vMapRaw) {
      final vMap = Map<String, dynamic>.from(vMapRaw as Map);
      final optionsRaw = vMap['options'] as List? ?? [];
      final options = optionsRaw.map((oMapRaw) {
        final oMap = Map<String, dynamic>.from(oMapRaw as Map);
        return VariantOption(
          id: oMap['id'] as String? ?? '',
          name: oMap['name'] as String? ?? '',
          additionalPrice: (oMap['additionalPrice'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      return MenuVariant(
        id: vMap['id'] as String? ?? '',
        name: vMap['name'] as String? ?? '',
        isRequired: vMap['isRequired'] as bool? ?? false,
        options: options,
      );
    }).toList();

    return MenuItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      isRecommended: map['isRecommended'] as bool? ?? false,
      categoryId: map['categoryId'] as String? ?? '',
      stock: map['stock'] as int? ?? 50,
      isActive: map['isActive'] as bool? ?? true,
      variants: variants,
    );
  }

}
