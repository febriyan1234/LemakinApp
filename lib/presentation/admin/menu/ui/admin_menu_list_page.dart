import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletal_loader.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/entities/menu_category.dart';
import '../cubit/admin_menu_cubit.dart';
import '../cubit/admin_menu_state.dart';

class AdminMenuListPage extends StatefulWidget {
  const AdminMenuListPage({super.key});

  @override
  State<AdminMenuListPage> createState() => _AdminMenuListPageState();
}

class _AdminMenuListPageState extends State<AdminMenuListPage> {
  late final AdminMenuCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AdminMenuCubit>();
    _cubit.fetchMenus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryName(String id, List<MenuCategory> categories) {
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/menu/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Menu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<AdminMenuCubit, AdminMenuState>(
        listener: (context, state) {
          if (state is AdminMenuLoaded) {
            if (state.actionSuccessMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccessMessage!),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _cubit.clearMessages();
            }
            if (state.actionErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionErrorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _cubit.clearMessages();
            }
          }
        },
        builder: (context, state) {
          if (state is AdminMenuLoading) {
            return _buildSkeletonLoader(context);
          } else if (state is AdminMenuError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.fetchMenus(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is AdminMenuLoaded) {
            final filteredItems = _cubit.getFilteredItems(state);

            return LayoutBuilder(
              builder: (context, mainConstraints) {
                final isMobile = mainConstraints.maxWidth < 650;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle Header Row
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Manage your menu, pricing, availability and stock.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Bar (Search & Add Menu Button)
                      _buildActionBar(context, state, isMobile),
                      const SizedBox(height: 16),

                      // Smart Filters
                      _buildFilterRow(state, isMobile),
                      const SizedBox(height: 24),

                      // Grid vs List view toggle content
                      filteredItems.isEmpty
                          ? _buildEmptyState()
                          : (_isGridView
                                ? _buildGridView(filteredItems, state)
                                : _buildListView(filteredItems, state)),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        SkeletalLoader(
                          width: double.infinity,
                          height: 38,
                          borderRadius: 10,
                        ),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SkeletalLoader(
                            width: 160,
                            height: 38,
                            borderRadius: 10,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        SkeletalLoader(
                          width: 300,
                          height: 40,
                          borderRadius: 10,
                        ),
                        SkeletalLoader(
                          width: 200,
                          height: 40,
                          borderRadius: 10,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, gridConstraints) {
                  final cols = gridConstraints.maxWidth < 650 ? 1 : 3;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: cols == 1 ? 1.6 : 1.1,
                    children: List.generate(
                      6,
                      (_) => SkeletalLoader.card(height: 200),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _cubit.addCategory(name);
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(AdminMenuLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip(
            label: 'All Categories',
            isSelected: state.selectedCategoryId == 'All',
            onTap: () => _cubit.updateFilters(categoryId: 'All'),
          ),
          ...state.categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildChoiceChip(
                label: cat.name,
                isSelected: state.selectedCategoryId == cat.id,
                onTap: () => _cubit.updateFilters(categoryId: cat.id),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 14, color: AppColors.primary),
              label: const Text(
                'Add Category',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              onPressed: () => _showAddCategoryDialog(context),
              backgroundColor: AppColors.primarySoft,
              side: const BorderSide(color: AppColors.primary, width: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(AdminMenuLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip(
            label: 'All Status',
            isSelected: state.selectedStatus == 'All',
            onTap: () => _cubit.updateFilters(status: 'All'),
          ),
          const SizedBox(width: 8),
          _buildChoiceChip(
            label: 'Active',
            isSelected: state.selectedStatus == 'Active',
            onTap: () => _cubit.updateFilters(status: 'Active'),
          ),
          const SizedBox(width: 8),
          _buildChoiceChip(
            label: 'Inactive',
            isSelected: state.selectedStatus == 'Inactive',
            onTap: () => _cubit.updateFilters(status: 'Inactive'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(AdminMenuLoaded state) {
    String label = 'Sort: Name';
    if (state.sortBy == 'Price Asc') label = 'Price: Low to High';
    if (state.sortBy == 'Price Desc') label = 'Price: High to Low';
    if (state.sortBy == 'Stock Asc') label = 'Stock: Low to High';
    if (state.sortBy == 'Stock Desc') label = 'Stock: High to Low';

    return PopupMenuButton<String>(
      onSelected: (val) => _cubit.updateFilters(sortBy: val),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Name', child: Text('Name')),
        PopupMenuItem(value: 'Price Asc', child: Text('Price: Low to High')),
        PopupMenuItem(value: 'Price Desc', child: Text('Price: High to Low')),
        PopupMenuItem(value: 'Stock Asc', child: Text('Stock: Low to High')),
        PopupMenuItem(value: 'Stock Desc', child: Text('Stock: High to Low')),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    AdminMenuLoaded state,
    bool isMobile,
  ) {
    final searchBar = Container(
      width: isMobile ? double.infinity : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _cubit.updateFilters(searchQuery: val),
              decoration: InputDecoration(
                hintText: 'Search menus...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          _cubit.updateFilters(searchQuery: '');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );

    final viewToggle = Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleButton(
            icon: Icons.grid_view,
            isSelected: _isGridView,
            onTap: () => setState(() => _isGridView = true),
          ),
          _buildViewToggleButton(
            icon: Icons.list,
            isSelected: !_isGridView,
            onTap: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: searchBar),
              const SizedBox(width: 8),
              viewToggle,
            ],
          ),
          const SizedBox(height: 12),
          _buildCategoryChips(state),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatusChips(state)),
              const SizedBox(width: 12),
              _buildSortChip(state),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            searchBar,
            const SizedBox(width: 12),
            viewToggle,
            const SizedBox(width: 16),
            Container(width: 1, height: 24, color: AppColors.border),
            const SizedBox(width: 16),
            Expanded(child: _buildCategoryChips(state)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Status: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChips(state),
            const SizedBox(width: 24),
            const Text(
              'Sort: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            _buildSortChip(state),
          ],
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppColors.textDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilterRow(AdminMenuLoaded state, bool isMobile) {
    // This helper is kept empty since filters are now inline inside _buildActionBar
    return const SizedBox.shrink();
  }

  Widget _buildGridView(List<MenuItem> items, AdminMenuLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = 3;
        if (constraints.maxWidth < 650) {
          cols = 1;
        } else if (constraints.maxWidth < 950) {
          cols = 2;
        }

        final double spacing = 16.0;
        final double totalSpacing = spacing * (cols - 1);
        final double cardWidth = (constraints.maxWidth - totalSpacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: _buildMenuGridCard(item, state),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMenuGridCard(MenuItem item, AdminMenuLoaded state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Food Image with Category badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  item.imageUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    width: double.infinity,
                    color: AppColors.primarySoft,
                    child: const Icon(
                      Icons.restaurant,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getCategoryName(item.categoryId, state.categories),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Footer actions (Switches & Edit/Delete Buttons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Visibility Switch
                    Row(
                      children: [
                        Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMinimalistSwitch(
                          value: item.isActive,
                          onChanged: (_) => _cubit.toggleMenuStatus(item.id),
                        ),
                      ],
                    ),
                    // Action buttons: Edit & Delete
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 16,
                          ),
                          onPressed: () => context.go(
                            '/admin/menu/edit/${item.id}',
                            extra: item,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.05),
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 16,
                          ),
                          onPressed: () =>
                              _showDeleteConfirmDialog(context, item),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withOpacity(0.05),
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<MenuItem> items, AdminMenuLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return Column(
          children: items.map((item) {
            final categoryName = _getCategoryName(
              item.categoryId,
              state.categories,
            );

            if (isMobile) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primarySoft,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.restaurant,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item.isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildMinimalistSwitch(
                              value: item.isActive,
                              onChanged: (_) =>
                                  _cubit.toggleMenuStatus(item.id),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 16,
                              ),
                              onPressed: () => context.go(
                                '/admin/menu/edit/${item.id}',
                                extra: item,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.05),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                                size: 16,
                              ),
                              onPressed: () =>
                                  _showDeleteConfirmDialog(context, item),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.error.withOpacity(
                                  0.05,
                                ),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            // Desktop layout (Horizontal Row)
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primarySoft,
                        width: 54,
                        height: 54,
                        child: const Icon(
                          Icons.restaurant,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildMinimalistSwitch(
                        value: item.isActive,
                        onChanged: (_) => _cubit.toggleMenuStatus(item.id),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 18,
                        ),
                        onPressed: () => context.go(
                          '/admin/menu/edit/${item.id}',
                          extra: item,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        onPressed: () =>
                            _showDeleteConfirmDialog(context, item),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No menu items match your search filters',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _cubit.updateFilters(
                  categoryId: 'All',
                  status: 'All',
                  searchQuery: '',
                  sortBy: 'Name',
                );
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete the menu "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _cubit.deleteMenu(item.id, item.name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
