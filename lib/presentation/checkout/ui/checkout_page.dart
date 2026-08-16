import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/order.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutCubit _cubit;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<CheckoutCubit>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartState = context.read<CartCubit>().state;
      if (cartState is CartLoaded && cartState.items.isEmpty) {
        context.go('/menu');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _redirectToWhatsApp(OrderEntity order) async {
    final buffer = StringBuffer();
    buffer.writeln('Halo, saya ingin pesan:');
    buffer.writeln('-----------------------------------------');
    buffer.writeln('Nama: ${order.customer.name}');
    buffer.writeln('Alamat/Meja: ${order.customer.address}');
    buffer.writeln();
    
    for (final item in order.items) {
      buffer.writeln('${item.quantity}x ${item.menuItem.name} (${item.menuItem.price.toInt()}/pcs)');
      final variantsText = item.selectedVariants.values.map((v) => v.name).join(' • ');
      if (variantsText.isNotEmpty) {
        buffer.writeln('\tPilihan: $variantsText');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('\tCatatan: "${item.notes}"');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Pembayaran Qris https://lemakin/pembayaran');
    buffer.writeln('Mohon konfirmasi pesanan saya. Terima kasih!');

    final String message = buffer.toString();
    final String phoneNumber = '6283819309651';
    final String encodedText = Uri.encodeComponent(message);
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=$encodedText');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka WhatsApp. Silakan hubungi admin.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          title: const Text('Checkout'),
        ),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) async {
            if (state is CheckoutSuccess) {
              await _redirectToWhatsApp(state.order);
              if (context.mounted) {
                context.read<CartCubit>().clearCart();
                context.go('/menu');
              }
            } else if (state is CheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            String? addressError;
            String? phoneError;

            if (state is CheckoutFormState) {
              addressError = state.addressError;
              phoneError = state.phoneError;
            }

            final isBtnLoading = state is CheckoutLoading;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Name (Optional)',
                                hintText: 'Enter your name',
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number (Optional)',
                                hintText: 'e.g. 08123456789',
                                errorText: phoneError,
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _addressController,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Address *',
                                hintText: 'Enter delivery address',
                                errorText: addressError,
                              ),
                            ),
                            const SizedBox(height: 24),

                            const Divider(color: AppColors.border),
                            const SizedBox(height: 16),

                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 const Text(
                                   'Order Confirmation',
                                   style: TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.bold,
                                     color: AppColors.textDark,
                                   ),
                                 ),
                                 TextButton.icon(
                                   onPressed: () {
                                     context.go('/menu');
                                   },
                                   icon: const Icon(Icons.add_shopping_cart, size: 14, color: AppColors.primary),
                                   label: const Text(
                                     'Tambah Pesanan',
                                     style: TextStyle(
                                       fontSize: 12,
                                       fontWeight: FontWeight.bold,
                                       color: AppColors.primary,
                                     ),
                                   ),
                                   style: TextButton.styleFrom(
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(20),
                                       side: const BorderSide(color: AppColors.primary, width: 1.2),
                                     ),
                                     backgroundColor: AppColors.primarySoft,
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 12),

                            BlocBuilder<CartCubit, CartState>(
                              builder: (context, cartState) {
                                if (cartState is CartLoaded) {
                                  if (cartState.items.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24.0),
                                      child: Center(
                                        child: Text(
                                          'No items in cart.',
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: cartState.items.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final item = cartState.items[index];
                                          final variantsText = item.selectedVariants.values
                                              .map((v) => v.name)
                                              .join(' • ');

                                          return GestureDetector(
                                            onTap: () async {
                                              await context.push('/menu/${item.menuItem.id}?editCartItemId=${item.id}');
                                            },
                                            child: Card(
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: const BorderSide(color: AppColors.border),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        item.menuItem.imageUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                            Container(
                                                              color: Colors.grey[200],
                                                              width: 50,
                                                              height: 50,
                                                              child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
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
                                                                  item.menuItem.name,
                                                                  style: const TextStyle(
                                                                    fontSize: 13,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: AppColors.textDark,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              const Icon(
                                                                Icons.edit_note,
                                                                size: 18,
                                                                color: AppColors.primary,
                                                              ),
                                                            ],
                                                          ),
                                                          if (variantsText.isNotEmpty) ...[
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              variantsText,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppColors.textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              'Notes: "${item.notes}"',
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                fontStyle: FontStyle.italic,
                                                                color: AppColors.primary,
                                                              ),
                                                            ),
                                                          ],
                                                          const SizedBox(height: 4),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors.textSecondary,
                                                                ),
                                                              ),
                                                              Text(
                                                                CurrencyFormatter.format(item.subtotal),
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: AppColors.textDark,
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
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(color: AppColors.border),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total Amount',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(cartState.totalPrice),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isBtnLoading
                                  ? null
                                  : () {
                                      _cubit.submitOrder(
                                        name: _nameController.text,
                                        phone: _phoneController.text,
                                        address: _addressController.text,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: isBtnLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Order Now',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
