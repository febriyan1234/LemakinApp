import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/menu_item.dart';
import 'order_local_datasource.dart';

class OrderFirestoreDataSourceImpl implements OrderLocalDataSource {
  final FirebaseFirestore _firestore;

  OrderFirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createOrder(OrderEntity order) async {
    await _firestore
        .collection('orders')
        .doc(order.id)
        .set(_orderToMap(order));
  }

  @override
  Future<List<OrderEntity>> getOrders() async {
    final snapshot = await _firestore.collection('orders').get();
    final orders = snapshot.docs
        .map((doc) => _orderFromMap(doc.data()))
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Map<String, dynamic> _customerInfoToMap(CustomerInfo info) {
    return {
      'name': info.name,
      'phone': info.phone,
      'address': info.address,
    };
  }

  CustomerInfo _customerInfoFromMap(Map<String, dynamic> map) {
    return CustomerInfo(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> _cartItemToMap(CartItem item) {
    return {
      'id': item.id,
      'menuItemId': item.menuItem.id,
      'menuItemName': item.menuItem.name,
      'menuItemPrice': item.menuItem.price,
      'menuItemImageUrl': item.menuItem.imageUrl,
      'menuItemDescription': item.menuItem.description,
      'menuItemCategoryId': item.menuItem.categoryId,
      'quantity': item.quantity,
      'notes': item.notes,
      'selectedVariants': item.selectedVariants
          .map((key, val) => MapEntry(key, {
                'id': val.id,
                'name': val.name,
                'additionalPrice': val.additionalPrice,
              })),
    };
  }

  CartItem _cartItemFromMap(Map<String, dynamic> map) {
    final optionsMapRaw = map['selectedVariants'] as Map? ?? {};
    final selectedVariants = optionsMapRaw.map((key, valRaw) {
      final val = Map<String, dynamic>.from(valRaw as Map);
      return MapEntry(
        key as String,
        VariantOption(
          id: val['id'] as String? ?? '',
          name: val['name'] as String? ?? '',
          additionalPrice: (val['additionalPrice'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    });

    return CartItem(
      id: map['id'] as String? ?? '',
      menuItem: MenuItem(
        id: map['menuItemId'] as String? ?? '',
        name: map['menuItemName'] as String? ?? '',
        price: (map['menuItemPrice'] as num?)?.toDouble() ?? 0.0,
        imageUrl: map['menuItemImageUrl'] as String? ?? '',
        description: map['menuItemDescription'] as String? ?? '',
        categoryId: map['menuItemCategoryId'] as String? ?? '',
      ),
      quantity: map['quantity'] as int? ?? 1,
      selectedVariants: selectedVariants,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> _orderToMap(OrderEntity order) {
    return {
      'id': order.id,
      'customer': _customerInfoToMap(order.customer),
      'items': order.items.map((item) => _cartItemToMap(item)).toList(),
      'total': order.total,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'paymentMethod': order.paymentMethod,
      'status': order.status,
      'scheduledAt': order.scheduledAt != null ? Timestamp.fromDate(order.scheduledAt!) : null,
    };
  }

  OrderEntity _orderFromMap(Map<String, dynamic> map) {
    final itemsRaw = map['items'] as List? ?? [];
    final items = itemsRaw
        .map((i) => _cartItemFromMap(Map<String, dynamic>.from(i as Map)))
        .toList();

    final dateRaw = map['createdAt'];
    DateTime createdAt;
    if (dateRaw is Timestamp) {
      createdAt = dateRaw.toDate();
    } else if (dateRaw is String) {
      createdAt = DateTime.parse(dateRaw);
    } else {
      createdAt = DateTime.now();
    }

    final dateScheduledRaw = map['scheduledAt'];
    DateTime? scheduledAt;
    if (dateScheduledRaw is Timestamp) {
      scheduledAt = dateScheduledRaw.toDate();
    } else if (dateScheduledRaw is String) {
      scheduledAt = DateTime.parse(dateScheduledRaw);
    }

    return OrderEntity(
      id: map['id'] as String? ?? '',
      customer: _customerInfoFromMap(
          Map<String, dynamic>.from(map['customer'] as Map)),
      items: items,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdAt,
      paymentMethod: map['paymentMethod'] as String? ?? 'QRIS',
      status: map['status'] as String? ?? 'Success',
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<void> updateOrder(OrderEntity order) async {
    await _firestore
        .collection('orders')
        .doc(order.id)
        .update(_orderToMap(order));
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _firestore
        .collection('orders')
        .doc(id)
        .delete();
  }
}
