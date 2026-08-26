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
    final categories = snapshot.docs
        .map((doc) => _categoryFromMap(doc.data()))
        .toList();
    categories.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return categories;
  }

  @override
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) async {
    Query query = _firestore.collection('menu_items');

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.get();
    List<MenuItem> items = snapshot.docs
        .map((doc) => _menuItemFromMap(doc.data() as Map<String, dynamic>))
        .toList();

    try {
      final globalVariants = await getVariants();
      final gMap = <String, MenuVariant>{};
      for (final v in globalVariants) {
        gMap[v.id] = v;
        gMap[v.name] = v;
      }
      items = items.map((item) {
        if (item.variants.isEmpty) return item;
        final updatedVariants = item.variants.map((v) {
          return gMap[v.id] ?? gMap[v.name] ?? v;
        }).toList();
        return item.copyWith(variants: updatedVariants);
      }).toList();
    } catch (_) {}

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchLower = searchQuery.toLowerCase().trim();
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(searchLower) ||
                item.description.toLowerCase().contains(searchLower),
          )
          .toList();
    }

    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  @override
  Future<MenuItem?> getMenuItemDetail(String id) async {
    final doc = await _firestore.collection('menu_items').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final item = _menuItemFromMap(doc.data()!);
      if (item.variants.isNotEmpty) {
        try {
          final globalVariants = await getVariants();
          final gMap = <String, MenuVariant>{};
          for (final v in globalVariants) {
            gMap[v.id] = v;
            gMap[v.name] = v;
          }
          final updatedVariants = item.variants.map((v) {
            return gMap[v.id] ?? gMap[v.name] ?? v;
          }).toList();
          return item.copyWith(variants: updatedVariants);
        } catch (_) {}
      }
      return item;
    }
    return null;
  }

  @override
  Future<List<MenuItem>> getRecommendedItems({
    bool includeInactive = false,
  }) async {
    Query query = _firestore
        .collection('menu_items')
        .where('isRecommended', isEqualTo: true);
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    List<MenuItem> items = snapshot.docs
        .map((doc) => _menuItemFromMap(doc.data() as Map<String, dynamic>))
        .toList();

    try {
      final globalVariants = await getVariants();
      final gMap = <String, MenuVariant>{};
      for (final v in globalVariants) {
        gMap[v.id] = v;
        gMap[v.name] = v;
      }
      items = items.map((item) {
        if (item.variants.isEmpty) return item;
        final updatedVariants = item.variants.map((v) {
          return gMap[v.id] ?? gMap[v.name] ?? v;
        }).toList();
        return item.copyWith(variants: updatedVariants);
      }).toList();
    } catch (_) {}

    return items;
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
        .set(_menuItemToMap(item), SetOptions(merge: true));
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

  @override
  Future<void> updateCategory(MenuCategory category) async {
    await _firestore
        .collection('menu_categories')
        .doc(category.id)
        .update(_categoryToMap(category));
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('menu_categories').doc(id).delete();
  }

  @override
  Future<List<MenuVariant>> getVariants() async {
    final snapshot = await _firestore.collection('menu_variants').get();
    return snapshot.docs.map((doc) => _variantFromMap(doc.data())).toList();
  }

  @override
  Future<void> addVariant(MenuVariant variant) async {
    await _firestore
        .collection('menu_variants')
        .doc(variant.id)
        .set(_variantToMap(variant));
  }

  @override
  Future<void> updateVariant(MenuVariant variant) async {
    await _firestore
        .collection('menu_variants')
        .doc(variant.id)
        .set(_variantToMap(variant));

    try {
      final itemsSnapshot = await _firestore.collection('menu_items').get();
      for (final doc in itemsSnapshot.docs) {
        final data = doc.data();
        final variantsRaw = data['variants'] as List? ?? [];
        bool modified = false;

        final updatedVariantsRaw = variantsRaw.map((vRaw) {
          final vMap = Map<String, dynamic>.from(vRaw as Map);
          if (vMap['id'] == variant.id || vMap['name'] == variant.name) {
            modified = true;
            return _variantToMap(variant);
          }
          return vRaw;
        }).toList();

        if (modified) {
          await doc.reference.update({'variants': updatedVariantsRaw});
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteVariant(String id) async {
    await _firestore.collection('menu_variants').doc(id).delete();

    try {
      final itemsSnapshot = await _firestore.collection('menu_items').get();
      for (final doc in itemsSnapshot.docs) {
        final data = doc.data();
        final variantsRaw = data['variants'] as List? ?? [];
        final originalLen = variantsRaw.length;
        final updatedVariantsRaw = variantsRaw.where((vRaw) {
          final vMap = Map<String, dynamic>.from(vRaw as Map);
          return vMap['id'] != id;
        }).toList();

        if (updatedVariantsRaw.length != originalLen) {
          await doc.reference.update({'variants': updatedVariantsRaw});
        }
      }
    } catch (_) {}
  }

  Map<String, dynamic> _variantToMap(MenuVariant variant) {
    return {
      'id': variant.id,
      'name': variant.name,
      'isRequired': variant.isRequired,
      'minSelections': variant.minSelections,
      'maxSelections': variant.maxSelections,
      'options': variant.options
          .map(
            (o) => {
              'id': o.id,
              'name': o.name,
              'additionalPrice': o.additionalPrice,
            },
          )
          .toList(),
    };
  }

  MenuVariant _variantFromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'] as List? ?? [];
    final options = optionsRaw.map((oMapRaw) {
      final oMap = Map<String, dynamic>.from(oMapRaw as Map);
      return VariantOption(
        id: oMap['id'] as String? ?? '',
        name: oMap['name'] as String? ?? '',
        additionalPrice: (oMap['additionalPrice'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final isRequired = map['isRequired'] as bool? ?? false;
    return MenuVariant(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isRequired: isRequired,
      minSelections:
          (map['minSelections'] as num?)?.toInt() ?? (isRequired ? 1 : 0),
      maxSelections: (map['maxSelections'] as num?)?.toInt() ?? 1,
      options: options,
    );
  }

  Map<String, dynamic> _categoryToMap(MenuCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'orderIndex': category.orderIndex,
    };
  }

  MenuCategory _categoryFromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      orderIndex: map['orderIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _menuItemToMap(MenuItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'originalPrice': item.originalPrice,
      'imageUrl': item.imageUrl,
      'isRecommended': item.isRecommended,
      'categoryId': item.categoryId,
      'stock': item.stock,
      'isActive': item.isActive,
      'orderIndex': item.orderIndex,
      'variants': item.variants
          .map(
            (v) => {
              'id': v.id,
              'name': v.name,
              'isRequired': v.isRequired,
              'minSelections': v.minSelections,
              'maxSelections': v.maxSelections,
              'options': v.options
                  .map(
                    (o) => {
                      'id': o.id,
                      'name': o.name,
                      'additionalPrice': o.additionalPrice,
                    },
                  )
                  .toList(),
            },
          )
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

      final isRequired = vMap['isRequired'] as bool? ?? false;
      return MenuVariant(
        id: vMap['id'] as String? ?? '',
        name: vMap['name'] as String? ?? '',
        isRequired: isRequired,
        minSelections:
            (vMap['minSelections'] as num?)?.toInt() ?? (isRequired ? 1 : 0),
        maxSelections: (vMap['maxSelections'] as num?)?.toInt() ?? 1,
        options: options,
      );
    }).toList();

    return MenuItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String? ?? '',
      isRecommended: map['isRecommended'] as bool? ?? false,
      categoryId: map['categoryId'] as String? ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 50,
      isActive: map['isActive'] as bool? ?? true,
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      variants: variants,
    );
  }
}
