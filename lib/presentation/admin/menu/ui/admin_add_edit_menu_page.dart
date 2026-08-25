import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/entities/menu_category.dart';
import '../cubit/admin_menu_cubit.dart';
import '../cubit/admin_menu_state.dart';

class AdminAddEditMenuPage extends StatefulWidget {
  final MenuItem? menuItem;

  const AdminAddEditMenuPage({super.key, this.menuItem});

  @override
  State<AdminAddEditMenuPage> createState() => _AdminAddEditMenuPageState();
}

class _AdminAddEditMenuPageState extends State<AdminAddEditMenuPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isRecommended = false;
  String _pickedImageUrl = '';
  final List<MenuVariant> _selectedVariants = [];

  bool get _isEditMode => widget.menuItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;

    // Fetch menus/categories on entry to populate dropdown lists immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminMenuCubit>().fetchMenus();
      }
    });

    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final normalPrice = item != null ? (item.originalPrice ?? item.price) : 0.0;
    final discount = (item != null && item.originalPrice != null) ? (item.originalPrice! - item.price) : 0.0;

    _priceController = TextEditingController(
      text: item != null ? '${normalPrice.toInt()}' : '',
    );
    _discountController = TextEditingController(
      text: (item != null && item.originalPrice != null) ? '${discount.toInt()}' : '',
    );
    _stockController = TextEditingController(
      text: item != null ? '${item.stock}' : '50',
    );
    _imageUrlController = TextEditingController(
      text:
          item?.imageUrl ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600',
    );

    _selectedCategoryId = item?.categoryId;
    _isActive = item?.isActive ?? true;
    _isRecommended = item?.isRecommended ?? false;
    if (item?.variants != null) {
      _selectedVariants.addAll(item!.variants);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final desc = _descriptionController.text.trim();
      final normalPrice = double.parse(_priceController.text);
      final discountStr = _discountController.text.trim();
      final discount = discountStr.isNotEmpty ? (double.tryParse(discountStr) ?? 0.0) : 0.0;

      final finalPrice = normalPrice - discount;
      final double? originalPrice = discount > 0 ? normalPrice : null;
      final stock = int.parse(_stockController.text);
      final imageUrl = _pickedImageUrl.isNotEmpty
          ? _pickedImageUrl
          : _imageUrlController.text.trim();

      if (_isEditMode) {
        final updatedItem = widget.menuItem!.copyWith(
          name: name,
          description: desc,
          price: finalPrice,
          originalPrice: originalPrice,
          stock: stock,
          imageUrl: imageUrl,
          categoryId: _selectedCategoryId!,
          isActive: _isActive,
          isRecommended: _isRecommended,
          variants: _selectedVariants,
        );
        context.read<AdminMenuCubit>().updateMenu(updatedItem);
      } else {
        final newItem = MenuItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          description: desc,
          price: finalPrice,
          originalPrice: originalPrice,
          stock: stock,
          imageUrl: imageUrl,
          categoryId: _selectedCategoryId!,
          isActive: _isActive,
          isRecommended: _isRecommended,
          variants: _selectedVariants,
        );
        context.read<AdminMenuCubit>().addMenu(newItem);
      }

      context.go('/admin/menu');
    }
  }

  Widget _buildMinimalistSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: value ? AppColors.primary : Colors.grey[300],
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter category name...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          GradientButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<AdminMenuCubit>().addCategory(name).then((_) {
                  final menuState = context.read<AdminMenuCubit>().state;
                  if (menuState is AdminMenuLoaded) {
                    final newCat = menuState.categories.firstWhere(
                      (c) => c.name.toLowerCase() == name.toLowerCase(),
                      orElse: () => menuState.categories.last,
                    );
                    setState(() {
                      _selectedCategoryId = newCat.id;
                    });
                  }
                });
                Navigator.pop(dialogCtx);
              }
            },
            borderRadius: 8,
            height: 38,
            child: const Text(
              'Add Category',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Dish Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      setState(() {
                        _pickedImageUrl =
                            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=600';
                        _imageUrlController.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mock photo captured from Camera successfully!',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 32,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _showGalleryPhotosDialog(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 32,
                            color: Colors.grey[700],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGalleryPhotosDialog(BuildContext context) {
    final List<Map<String, String>> mockFoodGallery = [
      {
        'name': 'Fried Rice',
        'url':
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?q=80&w=600',
      },
      {
        'name': 'Noodle Soup',
        'url':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=600',
      },
      {
        'name': 'Burger & Fries',
        'url':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600',
      },
      {
        'name': 'Steak Salad',
        'url':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600',
      },
      {
        'name': 'Fruit Dessert',
        'url':
            'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=600',
      },
      {
        'name': 'Fruit Juice',
        'url':
            'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?q=80&w=600',
      },
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Food Picture'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: mockFoodGallery.length,
            itemBuilder: (context, index) {
              final photo = mockFoodGallery[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _pickedImageUrl = photo['url']!;
                    _imageUrlController.clear();
                  });
                  Navigator.pop(dialogCtx);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(photo['url']!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            photo['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminMenuCubit, AdminMenuState>(
      builder: (context, state) {
        if (state is AdminMenuLoading || state is AdminMenuInitial) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        List<MenuCategory> categoriesList = [];
        if (state is AdminMenuLoaded) {
          categoriesList = state.categories;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Back Button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textDark,
                          ),
                          onPressed: () => context.go('/admin/menu'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEditMode
                                ? 'Update Dish Details'
                                : 'Add New Menu Item',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Food Banner Image Preview Card
                    GestureDetector(
                      onTap: () => _showImagePickerDialog(context),
                      child: ListenableBuilder(
                        listenable: _imageUrlController,
                        builder: (context, _) {
                          final showPicked = _pickedImageUrl.isNotEmpty;
                          final showUrl = _imageUrlController.text.isNotEmpty;
                          final hasImage = showPicked || showUrl;
                          final displayUrl = showPicked ? _pickedImageUrl : _imageUrlController.text;

                          return Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                              image: hasImage
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        displayUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                if (hasImage)
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change Image',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 36,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Upload Menu Image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to select from Gallery or Camera',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image URL Input field (positioned directly below the image preview card)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Image URL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _imageUrlController,
                          onChanged: (val) {
                            if (val.isNotEmpty && _pickedImageUrl.isNotEmpty) {
                              setState(() {
                                _pickedImageUrl = '';
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Paste unsplash/web link...',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Menu Name
                    const Text(
                      'Menu Name *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Menu name is required';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'e.g. Special Fried Rice',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Describe ingredients, prep style, or sides...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Selector (Full Width)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                items: categoriesList.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategoryId = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                              onPressed: () =>
                                  _showAddCategoryDialog(context),
                              tooltip: 'Add Category',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price & Discount Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Price (IDR) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  final parsed = double.tryParse(val);
                                  if (parsed == null || parsed <= 0) {
                                    return 'Must be greater than 0';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 8000',
                                  prefixText: 'Rp ',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Discount Input (Optional)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discount Cut (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return null;
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed == null || parsed < 0) {
                                    return 'Cannot be negative';
                                  }
                                  final normalPriceStr = _priceController.text.trim();
                                  final normalPrice = double.tryParse(normalPriceStr);
                                  if (normalPrice != null && parsed >= normalPrice) {
                                    return 'Must be < Price';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 2000',
                                  prefixText: 'Rp ',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stock Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Initial Stock *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Required';
                            }
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed < 0) {
                              return 'Cannot be negative';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'e.g. 50',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Toggles Block (Minimalist Style)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          // Active Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Status',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Allow customer orders',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              _buildMinimalistSwitch(
                                value: _isActive,
                                onChanged: (val) {
                                  setState(() {
                                    _isActive = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Recommended Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recommend Item',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Feature on homepage carousel',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              _buildMinimalistSwitch(
                                value: _isRecommended,
                                onChanged: (val) {
                                  setState(() {
                                    _isRecommended = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dish Variants Section
                    const Text(
                      'Dish Variants',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select variants that apply to this dish. Manage variants globally in the Variant tab.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state is AdminMenuLoaded && state.variants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: const Center(
                          child: Text(
                            'No global variants created yet. Go to Variant tab to create one.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else if (state is AdminMenuLoaded)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.variants.length,
                        itemBuilder: (context, index) {
                          final variant = state.variants[index];
                          final isSelected = _selectedVariants.any((v) => v.id == variant.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF5E62).withValues(alpha: 0.02) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF5E62) : Colors.grey[200]!,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              activeColor: const Color(0xFFFF5E62),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(
                                variant.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                '${variant.isRequired ? "Required" : "Optional"} • Options: ${variant.options.map((o) => '${o.name} (+Rp ${o.additionalPrice.toInt()})').join(', ')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedVariants.add(variant);
                                  } else {
                                    _selectedVariants.removeWhere((v) => v.id == variant.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),

                    // Submit & Cancel Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => context.go('/admin/menu'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GradientButton(
                            onPressed: _submitForm,
                            borderRadius: 12,
                            child: Text(
                              _isEditMode
                                  ? 'Save'
                                  : 'Publish Menu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
