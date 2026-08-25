import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/store_status_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../../../domain/entities/cart_item.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../cubit/menu_cubit.dart';
import '../cubit/menu_state.dart';
import '../widget/banner_carousel.dart';
import '../widget/category_chips.dart';
import '../widget/menu_card.dart';
import '../widget/floating_cart_widget.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    context.read<MenuCubit>().fetchMenu();
    context.read<CartCubit>().loadCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isGridView
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return ShimmerWidget.rounded(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 12.0,
                );
              },
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ShimmerWidget.rounded(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 12.0,
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Stack(
                children: [
                  BlocBuilder<MenuCubit, MenuState>(
                    builder: (context, menuState) {
                      if (menuState is MenuLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      } else if (menuState is MenuError) {
                        return Center(
                          child: Text(
                            'Error: ${menuState.message}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      } else if (menuState is MenuLoaded) {
                        return CustomScrollView(
                          slivers: [
                            // 1. Banner Carousel with overlapping logo & status (scrolls away)
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Banner Carousel with overlapping logo
                                  Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      BannerCarousel(
                                        items: (() {
                                          final promoItems = menuState.menuItems
                                              .where((item) =>
                                                  item.originalPrice != null &&
                                                  item.originalPrice! > item.price)
                                              .toList();
                                          if (promoItems.length <= 1) {
                                            final recommended = menuState.menuItems
                                                .where((item) => item.isRecommended)
                                                .toList();
                                            for (final item in recommended) {
                                              if (!promoItems.any((promo) => promo.id == item.id)) {
                                                promoItems.add(item);
                                              }
                                            }
                                          }
                                          if (promoItems.isEmpty) {
                                            return menuState.menuItems.take(3).toList();
                                          }
                                          return promoItems;
                                        })(),
                                        onTap: (item) => _handleItemTap(context, item),
                                      ),
                                      Positioned(
                                        bottom: -32,
                                        child: Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: ClipOval(
                                              child: Container(
                                                color: Colors.white,
                                                padding: const EdgeInsets.all(4.0),
                                                child: Image.asset(
                                                  'assets/images/logo.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 44),
                                  
                                  // Store Name
                                  const Text(
                                    'Jajanan by Lemakin',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Outlet Operational Status
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: StoreStatusHelper.stream,
                                    builder: (context, storeSnapshot) {
                                      bool isShopOpen = true;
                                      bool isClosedTemporarily = false;
                                      DateTime? closedUntil;

                                      if (storeSnapshot.hasData && storeSnapshot.data!.exists) {
                                        final sData = storeSnapshot.data!.data() as Map<String, dynamic>?;
                                        if (sData != null) {
                                          isShopOpen = sData['isShopOpen'] as bool? ?? true;
                                          isClosedTemporarily = sData['isClosedTemporarily'] as bool? ?? false;
                                          if (sData['closedUntil'] != null) {
                                            closedUntil = DateTime.tryParse(sData['closedUntil'] as String);
                                          }
                                        }
                                      }

                                      // Check if temp closed has expired
                                      if (isClosedTemporarily &&
                                          closedUntil != null &&
                                          closedUntil.isBefore(DateTime.now())) {
                                        isClosedTemporarily = false;
                                        closedUntil = null;
                                      }

                                      final isCurrentlyClosed = !isShopOpen ||
                                          (isClosedTemporarily &&
                                              closedUntil != null &&
                                              closedUntil.isAfter(DateTime.now()));

                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isCurrentlyClosed
                                              ? AppColors.error.withValues(alpha: 0.1)
                                              : AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isCurrentlyClosed
                                                ? AppColors.error.withValues(alpha: 0.2)
                                                : AppColors.success.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isCurrentlyClosed ? Icons.cancel : Icons.check_circle,
                                              color: isCurrentlyClosed ? AppColors.error : AppColors.success,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isCurrentlyClosed
                                                  ? (isClosedTemporarily && closedUntil != null
                                                      ? 'Tutup Sementara s.d ${closedUntil.hour.toString().padLeft(2, '0')}:${closedUntil.minute.toString().padLeft(2, '0')}'
                                                      : 'Outlet Sedang Tutup')
                                                  : 'Outlet Buka - Menerima Pesanan',
                                              style: TextStyle(
                                                color: isCurrentlyClosed ? AppColors.error : AppColors.success,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),

                            // 2. Sticky Header: Search Bar + Chips & Toggle (pinned)
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyHeaderDelegate(
                                height: 135.0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (val) {
                                          context.read<MenuCubit>().searchMenu(
                                            val,
                                          );
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Search menus...',
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: AppColors.grey500,
                                          ),
                                          suffixIcon:
                                              _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    context
                                                        .read<MenuCubit>()
                                                        .searchMenu('');
                                                  },
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(28),
                                            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(28),
                                            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(28),
                                            borderSide: const BorderSide(color: AppColors.primary, width: 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CategoryChips(
                                            categories: menuState.categories,
                                            selectedCategoryId:
                                                menuState.selectedCategoryId,
                                            onCategorySelected: (catId) {
                                              context
                                                  .read<MenuCubit>()
                                                  .selectCategory(catId);
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 12.0,
                                          ),
                                          child: CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                AppColors.primarySoft,
                                            child: IconButton(
                                              icon: Icon(
                                                _isGridView
                                                    ? Icons.view_list
                                                    : Icons.grid_view,
                                                color: AppColors.primary,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isGridView = !_isGridView;
                                                });
                                              },
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 3. Recommended Section (only when All category selected)
                            if (menuState.selectedCategoryId == 'All' &&
                                menuState.searchQuery.isEmpty &&
                                menuState.recommendedItems.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(
                                        'Recommended Menu',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 235,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        itemCount:
                                            menuState.recommendedItems.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                              menuState.recommendedItems[index];
                                          return SizedBox(
                                            width: 175,
                                            child:
                                                BlocBuilder<
                                                  CartCubit,
                                                  CartState
                                                >(
                                                  builder: (context, cartState) {
                                                    final qty = context
                                                        .read<CartCubit>()
                                                        .getItemQuantityInCart(
                                                          item.id,
                                                        );
                                                    return GestureDetector(
                                                      onTap: () =>
                                                          _handleItemTap(
                                                            context,
                                                            item,
                                                          ),
                                                      child: MenuCard(
                                                        item: item,
                                                        quantity: qty,
                                                        onIncrement: () {
                                                          context.read<CartCubit>().incrementCartItemQuantity(item.id);
                                                        },
                                                        onDecrement: () {
                                                          context.read<CartCubit>().decrementCartItemQuantity(item.id);
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // 4. Menu Items Section (shows shimmers only here if loading)
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (menuState.isLoading)
                                    _buildLoadingShimmer()
                                  else if (menuState.selectedCategoryId ==
                                      'All') ...[
                                    ...menuState.categories.map((category) {
                                      final categoryItems = menuState.menuItems
                                          .where(
                                            (item) =>
                                                item.categoryId == category.id,
                                          )
                                          .toList();
                                      if (categoryItems.isEmpty)
                                        return const SizedBox.shrink();
                                      return _buildCategorySection(
                                        context,
                                        category.name,
                                        categoryItems,
                                      );
                                    }),
                                  ] else ...[
                                    if (menuState.menuItems.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(48.0),
                                          child: Text(
                                            'No items found.',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      _buildCategorySection(
                                        context,
                                        menuState.categories
                                            .firstWhere(
                                              (cat) =>
                                                  cat.id ==
                                                  menuState.selectedCategoryId,
                                            )
                                            .name,
                                        menuState.menuItems,
                                      ),
                                  ],
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        if (cartState is CartLoaded &&
                            cartState.items.isNotEmpty) {
                          return FloatingCartWidget(
                            totalItems: cartState.totalQuantity,
                            totalPrice: cartState.totalPrice,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<MenuItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _isGridView
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        final qty = context
                            .read<CartCubit>()
                            .getItemQuantityInCart(item.id);
                        return GestureDetector(
                          onTap: () => _handleItemTap(context, item),
                          child: MenuCard(
                            item: item,
                            quantity: qty,
                            onIncrement: () {
                              context.read<CartCubit>().incrementCartItemQuantity(item.id);
                            },
                            onDecrement: () {
                              context.read<CartCubit>().decrementCartItemQuantity(item.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        final qty = context
                            .read<CartCubit>()
                            .getItemQuantityInCart(item.id);
                        return GestureDetector(
                          onTap: () => _handleItemTap(context, item),
                          child: _buildMenuListItem(context, item, qty),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMenuListItem(BuildContext context, MenuItem item, int quantity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.broken_image,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            CurrencyFormatter.format(item.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (item.originalPrice != null && item.originalPrice! > item.price)
                            Text(
                              CurrencyFormatter.format(item.originalPrice!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      if (item.variants.isEmpty && quantity > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.read<CartCubit>().decrementCartItemQuantity(item.id);
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                context.read<CartCubit>().incrementCartItemQuantity(item.id);
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (quantity > 0)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleItemTap(BuildContext context, MenuItem item) async {
    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.state;

    List<CartItem> matchingItems = [];
    if (cartState is CartLoaded) {
      matchingItems = cartState.items
          .where((cartItem) => cartItem.menuItem.id == item.id)
          .toList();
    }

    if (item.variants.isNotEmpty) {
      if (matchingItems.isNotEmpty) {
        _showCartSummaryForItemBottomSheet(context, item, matchingItems);
      } else {
        await context.push('/menu/${item.id}');
      }
    } else {
      if (matchingItems.isEmpty) {
        await cartCubit.addToCart(
          CartItem(
            id: item.id,
            menuItem: item,
            quantity: 1,
            selectedVariants: const {},
          ),
        );
      } else {
        await context.push('/menu/${item.id}');
      }
    }
  }

  void _showCartSummaryForItemBottomSheet(
    BuildContext context,
    MenuItem item,
    List<CartItem> initialCartItems,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            if (cartState is! CartLoaded) return const SizedBox.shrink();

            final matchingItems = cartState.items
                .where((cartItem) => cartItem.menuItem.id == item.id)
                .toList();

            if (matchingItems.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
              return const SizedBox.shrink();
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rangkuman Pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 24, color: AppColors.border),

                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matchingItems.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 16, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final cartItem = matchingItems[index];
                          final variantsText = cartItem.selectedVariants.values
                              .map((v) => v.name)
                              .join(' • ');

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (variantsText.isNotEmpty)
                                      Text(
                                        variantsText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    if (cartItem.notes != null &&
                                        cartItem.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Catatan: "${cartItem.notes}"',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(
                                            cartItem.subtotal,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () async {
                                            Navigator.pop(context);
                                            await context.push(
                                              '/menu/${item.id}?editCartItemId=${cartItem.id}',
                                            );
                                          },
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 12,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      final qty = cartItem.quantity;
                                      if (qty <= 1) {
                                        context
                                            .read<CartCubit>()
                                            .removeFromCart(cartItem.id);
                                      } else {
                                        context
                                            .read<CartCubit>()
                                            .updateQuantity(
                                              cartItem.id,
                                              qty - 1,
                                            );
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      context
                                          .read<CartCubit>()
                                          .updateQuantity(
                                            cartItem.id,
                                            cartItem.quantity + 1,
                                          );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            matchingItems.fold<double>(
                              0,
                              (sum, cartItem) => sum + cartItem.subtotal,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await context.push('/menu/${item.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buat Pesanan Lain',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, this.height = 135.0});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(height: height, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
