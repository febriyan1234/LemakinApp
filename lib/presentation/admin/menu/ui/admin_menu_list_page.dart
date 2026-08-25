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
  bool _isReordering = false;
  int _selectedTabIndex = 0;

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
      body: Stack(
        children: [
          BlocConsumer<AdminMenuCubit, AdminMenuState>(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedTabIndex == 0
                                  ? 'Manage your menu, pricing, availability and stock.'
                                  : _selectedTabIndex == 1
                                      ? 'Manage categories for sorting and grouping dishes.'
                                      : 'Define variants and options (e.g. Size, Toppings) that apply to dishes.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              if (_selectedTabIndex == 0) {
                                context.go('/admin/menu/add');
                              } else if (_selectedTabIndex == 1) {
                                _showAddCategoryDialog(context);
                              } else {
                                _showVariantFormDialog(context);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedTabIndex == 0
                                        ? 'Add Menu'
                                        : _selectedTabIndex == 1
                                            ? 'Add Category'
                                            : 'Add Variant',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          _buildTabButton('Items', 0),
                          const SizedBox(width: 12),
                          _buildTabButton('Categories', 1),
                          const SizedBox(width: 12),
                          _buildTabButton('Variants', 2),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_selectedTabIndex == 0) ...[
                        _buildActionBar(context, state, isMobile),
                        const SizedBox(height: 16),

                        filteredItems.isEmpty
                            ? _buildEmptyState()
                            : _buildListView(filteredItems, state),
                      ] else if (_selectedTabIndex == 1) ...[
                        _buildCategoryTab(state, isMobile),
                      ] else if (_selectedTabIndex == 2) ...[
                        _buildVariantTab(state, isMobile),
                      ],
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      if (_isReordering)
        Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
    ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
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

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchBar,
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

  Future<void> _onReorder(int oldIndex, int newIndex, List<MenuItem> filteredItems, AdminMenuLoaded state) async {
    final List<MenuItem> reorderedFiltered = List.from(filteredItems);
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final MenuItem movedItem = reorderedFiltered.removeAt(oldIndex);
    reorderedFiltered.insert(newIndex, movedItem);

    final List<MenuItem> allItems = List.from(state.menuItems);
    final Set<String> filteredIds = filteredItems.map((item) => item.id).toSet();

    int filteredPointer = 0;
    for (int i = 0; i < allItems.length; i++) {
      if (filteredIds.contains(allItems[i].id)) {
        allItems[i] = reorderedFiltered[filteredPointer];
        filteredPointer++;
      }
    }

    setState(() {
      _isReordering = true;
    });

    try {
      await _cubit.reorderMenuItems(allItems);
    } finally {
      if (mounted) {
        setState(() {
          _isReordering = false;
        });
      }
    }
  }

  Widget _buildListView(List<MenuItem> items, AdminMenuLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final bool canDrag = state.sortBy == 'Custom';

        return ReorderableListView(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIdx, newIdx) => _onReorder(oldIdx, newIdx, items, state),
          children: items.map((item) {
            final categoryName = _getCategoryName(
              item.categoryId,
              state.categories,
            );

            final int itemIndex = items.indexOf(item);

            if (isMobile) {
              return Container(
                key: ValueKey(item.id),
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
                        if (canDrag) ...[
                          ReorderableDragStartListener(
                            index: itemIndex,
                            child: const Icon(
                              Icons.drag_indicator,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
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
              key: ValueKey(item.id),
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
                  if (canDrag) ...[
                    ReorderableDragStartListener(
                      index: itemIndex,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Icon(
                          Icons.drag_indicator,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? null : Colors.grey[100],
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(AdminMenuLoaded state, bool isMobile) {
    final categories = state.categories;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ReorderableListView(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorder: (oldIdx, newIdx) => _onCategoryReorder(oldIdx, newIdx, categories),
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;

          return Container(
            key: ValueKey(category.id),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: index == categories.length - 1
                      ? Colors.transparent
                      : Colors.grey[100]!,
                ),
              ),
            ),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.drag_indicator,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              title: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
                      size: 18,
                    ),
                    onPressed: () => _showEditCategoryDialog(context, category),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    onPressed: () => _showDeleteCategoryConfirmDialog(context, category),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVariantTab(AdminMenuLoaded state, bool isMobile) {
    final variants = state.variants;
    if (variants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text(
            'No global variants created yet.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        final optionsString = variant.options
            .map((o) => '${o.name} (+Rp ${o.additionalPrice.toInt()})')
            .join(', ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  variant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: variant.isRequired ? Colors.red[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    variant.isRequired ? 'Required' : 'Optional',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: variant.isRequired ? Colors.red[700] : Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Options: $optionsString',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                    size: 18,
                  ),
                  onPressed: () => _showVariantFormDialog(context, existingVariant: variant),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  onPressed: () => _showDeleteVariantConfirmDialog(context, variant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onCategoryReorder(int oldIndex, int newIndex, List<MenuCategory> categories) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final List<MenuCategory> allCategories = List.from(categories);
    final moved = allCategories.removeAt(oldIndex);
    allCategories.insert(newIndex, moved);

    setState(() {
      _isReordering = true;
    });

    try {
      await _cubit.reorderCategories(allCategories);
    } finally {
      if (mounted) {
        setState(() {
          _isReordering = false;
        });
      }
    }
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
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, MenuCategory category) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Category'),
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
                _cubit.editCategory(category.id, name);
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryConfirmDialog(BuildContext context, MenuCategory category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _cubit.deleteCategory(category.id);
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVariantFormDialog(BuildContext context, {MenuVariant? existingVariant}) {
    final isEdit = existingVariant != null;
    final nameController = TextEditingController(text: existingVariant?.name ?? '');
    bool isRequired = existingVariant?.isRequired ?? false;

    int minSelections = existingVariant?.minSelections ?? (isRequired ? 1 : 0);
    int maxSelections = existingVariant?.maxSelections ?? 0;

    final List<Map<String, dynamic>> optionsData = [];
    if (isEdit) {
      for (final option in existingVariant.options) {
        optionsData.add({
          'id': option.id,
          'name': TextEditingController(text: option.name),
          'price': TextEditingController(text: option.additionalPrice.toInt().toString()),
        });
      }
    } else {
      optionsData.add({
        'id': 'opt_${DateTime.now().millisecondsSinceEpoch}_0',
        'name': TextEditingController(),
        'price': TextEditingController(text: '0'),
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final int optionsCount = optionsData.length;
            if (maxSelections > optionsCount) {
              maxSelections = optionsCount;
            }
            if (minSelections > optionsCount) {
              minSelections = optionsCount;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? 'Edit Global Variant' : 'Add New Global Variant'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Variant Name *',
                          hintText: 'e.g. Size, Spicy Level, Milk Option',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Is Required selection?'),
                        subtitle: const Text('Customers must pick an option to order'),
                        value: isRequired,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              isRequired = val;
                              minSelections = val ? 1 : 0;
                            });
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const Divider(color: AppColors.border, height: 24),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Options & Extra Price',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                optionsData.add({
                                  'id': 'opt_${DateTime.now().millisecondsSinceEpoch}_${optionsData.length}',
                                  'name': TextEditingController(),
                                  'price': TextEditingController(text: '0'),
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Option'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...optionsData.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final data = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: data['name'] as TextEditingController,
                                  decoration: const InputDecoration(
                                    hintText: 'Option (e.g. Medium)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: data['price'] as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '+ Price',
                                    prefixText: 'Rp ',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              if (optionsData.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () {
                                    setDialogState(() {
                                      optionsData.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                      const Divider(color: AppColors.border, height: 24),
                      const SizedBox(height: 8),

                      const Text(
                        'Selection Rules',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: minSelections,
                              decoration: const InputDecoration(
                                labelText: 'Min Selections',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: List.generate(optionsCount + 1, (i) => i)
                                  .map((val) => DropdownMenuItem<int>(
                                        value: val,
                                        child: Text(val.toString()),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    minSelections = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: maxSelections,
                              decoration: const InputDecoration(
                                labelText: 'Max Selections',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: List.generate(optionsCount + 1, (i) => i)
                                  .map((val) => DropdownMenuItem<int>(
                                        value: val,
                                        child: Text(val.toString()),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    maxSelections = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final variantName = nameController.text.trim();
                    if (variantName.isEmpty) return;

                    final List<VariantOption> finalOptions = [];
                    for (final optData in optionsData) {
                      final optName = (optData['name'] as TextEditingController).text.trim();
                      final optPriceStr = (optData['price'] as TextEditingController).text.trim();
                      final optPrice = double.tryParse(optPriceStr) ?? 0.0;

                      if (optName.isNotEmpty) {
                        finalOptions.add(VariantOption(
                          id: optData['id'] as String,
                          name: optName,
                          additionalPrice: optPrice,
                        ));
                      }
                    }

                    if (finalOptions.isEmpty) return;

                    final MenuVariant newVariant = MenuVariant(
                      id: existingVariant?.id ?? 'var_${DateTime.now().millisecondsSinceEpoch}',
                      name: variantName,
                      isRequired: isRequired,
                      options: finalOptions,
                      minSelections: minSelections,
                      maxSelections: maxSelections,
                    );

                    if (isEdit) {
                      _cubit.editVariant(newVariant);
                    } else {
                      _cubit.addVariant(newVariant);
                    }
                    Navigator.pop(dialogCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create Variant', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteVariantConfirmDialog(BuildContext context, MenuVariant variant) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Global Variant'),
        content: Text('Are you sure you want to delete "${variant.name}"? Dishes referencing this variant will no longer display it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _cubit.deleteVariant(variant.id);
              Navigator.pop(dialogCtx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
