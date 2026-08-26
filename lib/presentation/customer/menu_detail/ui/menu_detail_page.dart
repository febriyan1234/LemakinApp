import 'package:flutter/material.dart';
import 'package:lemakin_app/core/utils/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/store_status_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../domain/entities/cart_item.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../cubit/menu_detail_cubit.dart';
import '../cubit/menu_detail_state.dart';
import '../widget/variant_selector.dart';

class MenuDetailPage extends StatefulWidget {
  final String menuItemId;
  final String? editCartItemId;

  const MenuDetailPage({
    super.key,
    required this.menuItemId,
    this.editCartItemId,
  });

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  late final MenuDetailCubit _cubit;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<MenuDetailCubit>();
    _cubit.fetchItemDetails(
      widget.menuItemId,
      editCartItemId: widget.editCartItemId,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Menu Detail'),
        ),
        body: BlocConsumer<MenuDetailCubit, MenuDetailState>(
          listener: (context, state) {
            if (state is MenuDetailLoaded) {
              if (state.validationError != null) {
                showAppToast(context, state.validationError!, type: AppToastType.error);
              }
              if (state.editCartItemId != null &&
                  _notesController.text.isEmpty) {
                final cartState = context.read<CartCubit>().state;
                if (cartState is CartLoaded) {
                  try {
                    final existing = cartState.items.firstWhere(
                      (i) => i.id == state.editCartItemId,
                    );
                    if (existing.notes != null) {
                      _notesController.text = existing.notes!;
                    }
                  } catch (_) {}
                }
              }
            }
          },
          builder: (context, state) {
            if (state is MenuDetailLoading) {
              return const Center(
                child: AppLoadingIndicator(
                  width: 100,
                  height: 100,
                ),
              );
            } else if (state is MenuDetailError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error, fontSize: 16),
                ),
              );
            } else if (state is MenuDetailLoaded) {
              final item = state.menuItem;

              return StreamBuilder<DocumentSnapshot>(
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
                  if (isClosedTemporarily && closedUntil != null && closedUntil.isBefore(DateTime.now())) {
                    isClosedTemporarily = false;
                    closedUntil = null;
                  }

                  final isCurrentlyClosed = !isShopOpen ||
                      (isClosedTemporarily &&
                          closedUntil != null &&
                          closedUntil.isAfter(DateTime.now()));

                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Large Menu Image
                                  SizedBox(
                                    width: double.infinity,
                                    height: 280,
                                    child: Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: Colors.grey[100],
                                              child: const Center(
                                                child: AppLoadingIndicator(
                                                  width: 40,
                                                  height: 40,
                                                ),
                                              ),
                                            );
                                          },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Name & Price
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              CurrencyFormatter.format(item.price),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            if (item.originalPrice != null && item.originalPrice! > item.price)
                                              Text(
                                                CurrencyFormatter.format(item.originalPrice!),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textLight,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  const Divider(height: 1, color: AppColors.border),
                                  const SizedBox(height: 12),

                                  // Variants list
                                  if (item.variants.isNotEmpty) ...[
                                    ...item.variants.map((variant) {
                                      final selectedOpt =
                                          state.selectedVariants[variant.name];
                                      return VariantSelector(
                                        variant: variant,
                                        selectedOption: selectedOpt,
                                        onOptionSelected: (opt) {
                                          _cubit.selectVariantOption(
                                            variant.name,
                                            opt,
                                          );
                                        },
                                      );
                                    }),
                                  ],

                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'Add Special Notes (Optional)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 4.0,
                                    ),
                                    child: TextField(
                                      controller: _notesController,
                                      maxLines: 2,
                                      maxLength: 150,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'e.g. No onion, extra spicy, sauce on the side...',
                                        counterText: '',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Bar with quantity selector and Add to Cart button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: const Border(
                            top: BorderSide(color: AppColors.border, width: 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Row(
                              children: [
                                // Quantity selector
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: isCurrentlyClosed || item.stock == 0
                                          ? null
                                          : () {
                                              if (state.quantity > 1) {
                                                _cubit.updateQuantity(
                                                  state.quantity - 1,
                                                );
                                              }
                                            },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isCurrentlyClosed || item.stock == 0
                                                ? Colors.grey
                                                : AppColors.primary,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: isCurrentlyClosed || item.stock == 0
                                              ? Colors.grey
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(
                                        isCurrentlyClosed || item.stock == 0 ? '0' : '${state.quantity}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrentlyClosed || item.stock == 0
                                              ? Colors.grey
                                              : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: isCurrentlyClosed || item.stock == 0
                                          ? null
                                          : () {
                                              _cubit.updateQuantity(
                                                state.quantity + 1,
                                              );
                                            },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isCurrentlyClosed || item.stock == 0
                                              ? Colors.grey[300]
                                              : AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Order Now button
                                Expanded(
                                  child: GradientButton(
                                    onPressed: isCurrentlyClosed || item.stock == 0 || !item.isActive
                                        ? null
                                        : () {
                                            final success = _cubit.addToCart(
                                              notes: _notesController.text,
                                            );
                                            if (success) {
                                              final sortedOptionIds =
                                                  state.selectedVariants.values
                                                      .map((o) => o.id)
                                                      .toList()
                                                    ..sort();
                                              final notesKey =
                                                  _notesController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? 'notes_${_notesController.text.trim().hashCode}'
                                                  : '';
                                              final cartItemId = [
                                                item.id,
                                                ...sortedOptionIds,
                                                if (notesKey.isNotEmpty) notesKey,
                                              ].join('_');

                                              final addedItem = CartItem(
                                                id: cartItemId,
                                                menuItem: item,
                                                quantity: state.quantity,
                                                selectedVariants:
                                                    state.selectedVariants,
                                                notes:
                                                    _notesController.text
                                                        .trim()
                                                        .isNotEmpty
                                                    ? _notesController.text.trim()
                                                    : null,
                                              );

                                              context.pop(addedItem);
                                            }
                                          },
                                    borderRadius: 12,
                                    height: 48,
                                    child: Text(
                                      isCurrentlyClosed
                                          ? 'Outlet is Closed'
                                          : (!item.isActive
                                              ? 'Unavailable'
                                              : (item.stock == 0
                                                  ? 'Out of Stock'
                                                  : (state.editCartItemId != null
                                                        ? 'Update Order - ${CurrencyFormatter.format(state.totalPrice)}'
                                                        : 'Add to Cart - ${CurrencyFormatter.format(state.totalPrice)}'))),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
