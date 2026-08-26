import 'package:flutter/material.dart';
import 'package:lemakin_app/core/utils/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../domain/entities/order.dart';
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
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;

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
    buffer.writeln('Hello, I am ${order.customer.name} and I would like to order:');
    buffer.writeln();
    buffer.writeln('--------------------------------------');
    for (final item in order.items) {
      buffer.writeln(
        '${item.quantity}x ${item.menuItem.name} (${item.menuItem.price.toInt()}/pcs)',
      );
      final variantsText = item.selectedVariants.values
          .map((v) => v.name)
          .join(' • ');
      if (variantsText.isNotEmpty) {
        buffer.writeln('\tOptions: $variantsText');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('\tNotes: "${item.notes}"');
      }
    }
    buffer.writeln('--------------------------------------');
    buffer.writeln();
    buffer.writeln('Address: ${order.customer.address}');
    if (order.scheduledAt != null) {
      final dateStr = '${order.scheduledAt!.day.toString().padLeft(2, '0')}/${order.scheduledAt!.month.toString().padLeft(2, '0')}/${order.scheduledAt!.year}';
      final timeStr = '${order.scheduledAt!.hour.toString().padLeft(2, '0')}:${order.scheduledAt!.minute.toString().padLeft(2, '0')}';
      buffer.writeln('Delivery Schedule: $dateStr at $timeStr');
    } else {
      buffer.writeln('Delivery Schedule: Now (Order Now)');
    }
    buffer.writeln('Order ID: ${order.id}');
    buffer.writeln();

    buffer.writeln('QRIS Payment: https://lemakin/pembayaran');
    buffer.writeln('Please confirm my order. Thank you!');

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
        showAppToast(context, 'Failed to open WhatsApp. Please contact admin.', type: AppToastType.error);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime now = DateTime.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _scheduledDateTime != null
          ? TimeOfDay.fromDateTime(_scheduledDateTime!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            dialogTheme: const DialogThemeData(
              actionsPadding: EdgeInsets.only(left: 12, right: 12, bottom: 16),
            ),
            timePickerTheme: TimePickerThemeData(
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(50, 36),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(50, 36),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.transparent;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.textDark;
              }),
              dayPeriodBorderSide: const BorderSide(color: AppColors.border),
              dialHandColor: AppColors.primary,
              dialBackgroundColor: Colors.grey[50],
              entryModeIconColor: AppColors.primary,
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primarySoft;
                }
                return Colors.grey[100]!;
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textDark;
              }),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Checkout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          elevation: 0,
        ),
        body: BlocConsumer<CheckoutCubit, CheckoutState>(
          listener: (context, state) async {
            if (state is CheckoutSuccess) {
              await _redirectToWhatsApp(state.order);
              if (context.mounted) {
                await context.read<CartCubit>().clearCart();
                if (context.mounted) {
                  context.go('/menu');
                }
              }
            } else if (state is CheckoutError) {
              showAppToast(context, state.message, type: AppToastType.error);
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

                             const Text(
                               'Name',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.bold,
                                 color: AppColors.textSecondary,
                               ),
                             ),
                             const SizedBox(height: 6),
                             TextField(
                               controller: _nameController,
                               textCapitalization: TextCapitalization.words,
                               decoration: InputDecoration(
                                 hintText: 'Enter your name',
                                 hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                 filled: true,
                                 fillColor: Colors.grey[100],
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: BorderSide.none,
                                 ),
                                 enabledBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: BorderSide.none,
                                 ),
                                 focusedBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                 ),
                               ),
                               style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                             ),
                             const SizedBox(height: 16),

                             const Text(
                               'Phone Number',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.bold,
                                 color: AppColors.textSecondary,
                               ),
                             ),
                             const SizedBox(height: 6),
                             TextField(
                               controller: _phoneController,
                               keyboardType: TextInputType.phone,
                               decoration: InputDecoration(
                                 hintText: 'e.g. 08123456789',
                                 hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                 filled: true,
                                 fillColor: Colors.grey[100],
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: BorderSide.none,
                                 ),
                                 enabledBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: BorderSide.none,
                                 ),
                                 focusedBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                 ),
                                 errorBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: const BorderSide(color: AppColors.error, width: 1),
                                 ),
                                 errorText: phoneError,
                               ),
                               style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                             ),
                             const SizedBox(height: 16),

                             Row(
                               children: [
                                 const Text(
                                   'Address',
                                   style: TextStyle(
                                     fontSize: 13,
                                     fontWeight: FontWeight.bold,
                                     color: AppColors.textSecondary,
                                   ),
                                 ),
                                 const SizedBox(width: 4),
                                 const Text(
                                   '*',
                                   style: TextStyle(
                                     color: Colors.red,
                                     fontSize: 13,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 6),
                             TextField(
                               controller: _addressController,
                               maxLines: 2,
                               textCapitalization: TextCapitalization.sentences,
                               decoration: InputDecoration(
                                 hintText: 'Enter delivery address',
                                 hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                 filled: true,
                                 fillColor: Colors.grey[100],
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: BorderSide.none,
                                 ),
                                 enabledBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: BorderSide.none,
                                 ),
                                 focusedBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                 ),
                                 errorBorder: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(12),
                                   borderSide: const BorderSide(color: AppColors.error, width: 1),
                                 ),
                                 errorText: addressError,
                               ),
                               style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                             ),
                            const SizedBox(height: 24),

                            const Text(
                              'Delivery Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isScheduled = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !_isScheduled ? AppColors.primary : AppColors.border,
                                        width: !_isScheduled ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.flash_on,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Order Now',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          !_isScheduled ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: !_isScheduled ? AppColors.primary : Colors.grey,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isScheduled = true;
                                    });
                                    _selectDateTime();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isScheduled ? AppColors.primary : AppColors.border,
                                        width: _isScheduled ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _scheduledDateTime == null
                                                ? 'Select Delivery Time'
                                                : 'At ${_scheduledDateTime!.hour.toString().padLeft(2, '0')}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  label: const Text(
                                    'Add Item',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.2,
                                      ),
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
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24.0,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No items in cart.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: cartState.items.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final item = cartState.items[index];
                                          final variantsText = item
                                              .selectedVariants
                                              .values
                                              .map((v) => v.name)
                                              .join(' • ');

                                          return GestureDetector(
                                            onTap: () async {
                                              await context.push(
                                                '/menu/${item.menuItem.id}?editCartItemId=${item.id}',
                                              );
                                            },
                                            child: Card(
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: const BorderSide(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10.0,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        item.menuItem.imageUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              color: Colors
                                                                  .grey[200],
                                                              width: 50,
                                                              height: 50,
                                                              child: const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 20,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  item
                                                                      .menuItem
                                                                      .name,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppColors
                                                                        .textDark,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              const Icon(
                                                                Icons.edit_note,
                                                                size: 18,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            ],
                                                          ),
                                                          if (variantsText
                                                              .isNotEmpty) ...[
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              variantsText,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                          if (item.notes !=
                                                                  null &&
                                                              item
                                                                  .notes!
                                                                  .isNotEmpty) ...[
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              'Notes: "${item.notes}"',
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            ),
                                                          ],
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                ),
                                                              ),
                                                              Text(
                                                                CurrencyFormatter.format(
                                                                  item.subtotal,
                                                                ),
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: AppColors
                                                                      .textDark,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                            CurrencyFormatter.format(
                                              cartState.totalPrice,
                                            ),
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
                          child: SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              onPressed: isBtnLoading
                                  ? null
                                  : () {
                                      if (_isScheduled && _scheduledDateTime == null) {
                                        showAppToast(context, 'Please select the delivery date and time.', type: AppToastType.error);
                                        return;
                                      }
                                      _cubit.submitOrder(
                                        name: _nameController.text,
                                        phone: _phoneController.text,
                                        address: _addressController.text,
                                        scheduledAt: _isScheduled ? _scheduledDateTime : null,
                                      );
                                    },
                              borderRadius: 12,
                              height: 48,
                              child: isBtnLoading
                                  ? const AppLoadingIndicator(
                                      width: 20,
                                      height: 20,
                                    )
                                  : Text(
                                      _isScheduled ? 'Schedule Order' : 'Order Now',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
