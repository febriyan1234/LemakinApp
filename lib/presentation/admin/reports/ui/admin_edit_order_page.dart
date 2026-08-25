import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/cart_item.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/repositories/menu_repository.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/gradient_button.dart';
import '../cubit/admin_reports_cubit.dart';

class AdminEditOrderPage extends StatefulWidget {
  final OrderEntity order;

  const AdminEditOrderPage({
    key,
    required this.order,
  }) : super(key: key);

  @override
  State<AdminEditOrderPage> createState() => _AdminEditOrderPageState();
}

class _AdminEditOrderPageState extends State<AdminEditOrderPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  late String _status;
  late String _paymentMethod;
  late List<CartItem> _items;

  List<MenuItem> _allAvailableMenuItems = [];
  bool _isLoadingMenu = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.order.customer.name);
    _phoneController = TextEditingController(text: widget.order.customer.phone);
    _addressController = TextEditingController(text: widget.order.customer.address);

    _status = widget.order.status;
    _paymentMethod = widget.order.paymentMethod;
    _items = List.from(widget.order.items);

    _loadAvailableMenuItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Set<String> _globalVariantNames = {};

  Future<void> _loadAvailableMenuItems() async {
    try {
      final items = await di.sl<MenuRepository>().getMenuItems();
      final variants = await di.sl<MenuRepository>().getVariants();
      
      setState(() {
        _globalVariantNames = variants.map((v) => v.name.trim().toLowerCase()).toSet();
        _allAvailableMenuItems = items.map((menuItem) {
          final activeVariants = menuItem.variants.where((v) => 
            _globalVariantNames.contains(v.name.trim().toLowerCase())
          ).toList();
          return menuItem.copyWith(variants: activeVariants);
        }).toList();

        for (int i = 0; i < _items.length; i++) {
          final item = _items[i];
          try {
            final masterItem = items.firstWhere((mi) => mi.id == item.menuItem.id);
            final activeVariants = masterItem.variants.where((v) => 
              _globalVariantNames.contains(v.name.trim().toLowerCase())
            ).toList();
            
            _items[i] = CartItem(
              id: item.id,
              menuItem: masterItem.copyWith(variants: activeVariants),
              quantity: item.quantity,
              selectedVariants: item.selectedVariants,
              notes: item.notes,
            );
          } catch (_) {}
        }
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMenu = false;
      });
    }
  }

  double get _computedTotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _incrementQty(int idx) {
    setState(() {
      final item = _items[idx];
      _items[idx] = item.copyWith(quantity: item.quantity + 1);
    });
  }

  void _decrementQty(int idx) {
    setState(() {
      final item = _items[idx];
      if (item.quantity > 1) {
        _items[idx] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.removeAt(idx);
      }
    });
  }

  void _removeItem(int idx) {
    setState(() {
      _items.removeAt(idx);
    });
  }

  void _showAddItemPicker() {
    if (_allAvailableMenuItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No menu items available to add')),
      );
      return;
    }

    String searchQuery = '';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredItems = _allAvailableMenuItems.where((item) =>
              item.name.toLowerCase().contains(searchQuery.toLowerCase().trim())
            ).toList();

            return AlertDialog(
              title: const Text('Add Menu Item'),
              content: SizedBox(
                width: 400,
                height: 450,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Search menu item...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                'No menu items found',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                              itemBuilder: (context, index) {
                                final menuItem = filteredItems[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      menuItem.imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    menuItem.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(CurrencyFormatter.format(menuItem.price)),
                                  trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    _showItemCustomizerBottomSheet(
                                      context,
                                      newMenuItem: menuItem,
                                      onAdded: (newItem) {
                                        setState(() {
                                          _items.add(newItem);
                                        });
                                      },
                                    );
                                  },
                                );
                              },
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

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the order')),
      );
      return;
    }

    final updatedCustomer = CustomerInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    final updatedOrder = widget.order.copyWith(
      customer: updatedCustomer,
      items: _items,
      total: _computedTotal,
      status: _status,
      paymentMethod: _paymentMethod,
    );

    await context.read<AdminReportsCubit>().updateOrder(updatedOrder);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Order (${widget.order.id})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: _isLoadingMenu
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer Card
                    _buildSectionCard(
                      title: 'Customer Details',
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.person, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address / Table',
                              labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Address/Table is required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Options Card
                    _buildSectionCard(
                      title: 'Transaction Details',
                      icon: Icons.info_outline,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment Method',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'Card', child: Text('Card')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paymentMethod = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Success', child: Text('Success')),
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _status = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ordered Items Card
                    _buildSectionCard(
                      title: 'Ordered Menu Items',
                      icon: Icons.restaurant_menu,
                      actions: [
                        TextButton.icon(
                          onPressed: _showAddItemPicker,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Item'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                      child: Column(
                        children: [
                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Text(
                                'No items in this order',
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.border,),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                final hasVariants = item.menuItem.variants.isNotEmpty;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.menuItem.imageUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 64,
                                            height: 64,
                                            color: Colors.grey[100],
                                            child: const Icon(Icons.fastfood,
                                                size: 24, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: hasVariants 
                                              ? () => _showItemCustomizerBottomSheet(context, index: index)
                                              : null,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.menuItem.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (item.selectedVariants.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Builder(
                                                  builder: (context) {
                                                    final Map<String, List<String>> grouped = {};
                                                    item.selectedVariants.forEach((key, opt) {
                                                      final name = key.contains(':') ? key.split(':').first : key;
                                                      grouped.putIfAbsent(name, () => []).add(opt.name);
                                                    });
                                                    final text = grouped.entries
                                                        .map((e) => '${e.key}: ${e.value.join(", ")}')
                                                        .join(' | ');
                                                    return Text(
                                                      text,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 11,
                                                      ),
                                                    );
                                                  }
                                                ),
                                              ],
                                              if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Note: "${item.notes}"',
                                                  style: TextStyle(
                                                    color: Colors.amber[800],
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Text(
                                                CurrencyFormatter.format(item.unitPrice),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => _decrementQty(index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[100],
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.remove, size: 14, color: Colors.grey),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  GestureDetector(
                                                    onTap: () => _incrementQty(index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[100],
                                                        shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.add, size: 14, color: AppColors.primary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (hasVariants) ...[
                                            GestureDetector(
                                              onTap: () => _showItemCustomizerBottomSheet(context, index: index),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFE8F5E9),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: Color(0xFF4CAF50),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          GestureDetector(
                                            onTap: () => _removeItem(index),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFFEBEE),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Color(0xFFE53935),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const Divider(height: 32, color: AppColors.border,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_computedTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GradientButton(
                            onPressed: _saveOrder,
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    List<Widget>? actions,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                if (actions != null) ...actions,
              ],
            ),
            SizedBox(height: 24,),
            child,
          ],
        ),
      ),
    );
  }

  void _showItemCustomizerBottomSheet(
    BuildContext context, {
    int? index,
    MenuItem? newMenuItem,
    Function(CartItem)? onAdded,
  }) {
    final isEditing = index != null;
    final menuItem = isEditing ? _items[index].menuItem : newMenuItem!;
    final existingItem = isEditing ? _items[index] : null;

    int tempQty = existingItem?.quantity ?? 1;
    final notesController = TextEditingController(text: existingItem?.notes);
    Map<String, VariantOption> tempSelected = existingItem != null
        ? Map.from(existingItem.selectedVariants)
        : {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double addPrice = tempSelected.values.fold(0.0, (sum, opt) => sum + opt.additionalPrice);
            double itemSubtotal = (menuItem.price + addPrice) * tempQty;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            menuItem.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey[100],
                              child: const Icon(Icons.fastfood, size: 28, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                menuItem.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (menuItem.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  menuItem.description,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(menuItem.price),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    if (menuItem.variants.isNotEmpty) ...[
                      ...menuItem.variants.map((variant) {
                        final variantKeys = tempSelected.keys.where((k) => k == variant.name || k.startsWith('${variant.name}:')).toList();
                        final selectedOptions = variantKeys.map((k) => tempSelected[k]!).toList();
                        final selectedCount = selectedOptions.length;
                        final isMulti = variant.maxSelections > 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    variant.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (variant.isRequired) ...[
                                    const SizedBox(width: 4),
                                    const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text('(Required)', style: TextStyle(color: Colors.red, fontSize: 11)),
                                  ] else ...[
                                    const SizedBox(width: 4),
                                    const Text('(Optional)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                  if (isMulti) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Max: ${variant.maxSelections}',
                                        style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!, width: 1),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: variant.options.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                                  itemBuilder: (context, optIdx) {
                                    final option = variant.options[optIdx];
                                    final isSelected = selectedOptions.any((opt) => opt.id == option.id);

                                    if (isMulti) {
                                      return CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setDialogState(() {
                                            if (isSelected) {
                                              tempSelected.removeWhere((k, v) => k.startsWith('${variant.name}:') && v.id == option.id);
                                            } else {
                                              if (selectedCount < variant.maxSelections) {
                                                tempSelected['${variant.name}:${option.id}'] = option;
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Maximum ${variant.maxSelections} options allowed for ${variant.name}'),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            }
                                          });
                                        },
                                        title: Text(option.name, style: const TextStyle(fontSize: 12)),
                                        secondary: option.additionalPrice > 0
                                            ? Text('+ ${CurrencyFormatter.format(option.additionalPrice)}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold))
                                            : null,
                                        activeColor: AppColors.primary,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        dense: true,
                                      );
                                    } else {
                                      return RadioListTile<String>(
                                        value: option.id,
                                        groupValue: isSelected ? option.id : null,
                                        onChanged: (val) {
                                          setDialogState(() {
                                            for (final key in variantKeys) {
                                              tempSelected.remove(key);
                                            }
                                            tempSelected['${variant.name}:${option.id}'] = option;
                                          });
                                        },
                                        title: Text(option.name, style: const TextStyle(fontSize: 12)),
                                        secondary: option.additionalPrice > 0
                                            ? Text('+ ${CurrencyFormatter.format(option.additionalPrice)}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold))
                                            : null,
                                        activeColor: AppColors.primary,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        dense: true,
                                        toggleable: !variant.isRequired,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                              onPressed: () {
                                if (tempQty > 1) {
                                  setDialogState(() => tempQty--);
                                }
                              },
                            ),
                            Text(
                              '$tempQty',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              onPressed: () {
                                setDialogState(() => tempQty++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Optional notes...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(itemSubtotal),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: GradientButton(
                            onPressed: () {
                              for (final variant in menuItem.variants) {
                                if (variant.isRequired && tempSelected[variant.name] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please select an option for ${variant.name}')),
                                  );
                                  return;
                                }
                              }

                              final resultItem = CartItem(
                                id: existingItem?.id ?? '${menuItem.id}_${DateTime.now().millisecondsSinceEpoch}',
                                menuItem: menuItem,
                                quantity: tempQty,
                                selectedVariants: tempSelected,
                                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              );

                              if (isEditing) {
                                setState(() {
                                  _items[index] = resultItem;
                                });
                              } else {
                                if (onAdded != null) {
                                  onAdded(resultItem);
                                }
                              }
                              Navigator.pop(bottomSheetCtx);
                            },
                            child: Text(isEditing ? 'Apply Changes' : 'Add to Order'),
                          ),
                        ),
                      ],
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
