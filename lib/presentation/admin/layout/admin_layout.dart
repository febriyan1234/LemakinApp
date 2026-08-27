import 'package:flutter/material.dart';
import 'package:lemakin_app/core/utils/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../domain/entities/menu_category.dart';
import '../../../domain/entities/menu_item.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/repositories/menu_repository.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../auth/cubit/admin_auth_cubit.dart';
import '../auth/cubit/admin_auth_state.dart';
import '../auth/ui/admin_login_page.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_loading_indicator.dart';

class AdminLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String title;

  const AdminLayout({
    super.key,
    required this.navigationShell,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminAuthCubit, AdminAuthState>(
      listener: (context, state) {
        if (state is! AdminAuthAuthenticated) {
          context.go('/admin/login');
        }
      },
      child: BlocBuilder<AdminAuthCubit, AdminAuthState>(
        builder: (context, authState) {
          if (authState is! AdminAuthAuthenticated) {
            return const AdminLoginPage();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final bool isMobile = width <= 650;
              final bool isTablet = width > 650 && width <= 1000;

              final sidebarWidget = _SidebarContent(
                isCollapsed: isTablet,
                navigationShell: navigationShell,
                adminName: authState.adminName,
              );

              return Scaffold(
                backgroundColor: AppColors.scaffoldBackground,
                body: Row(
                  children: [
                    // Sidebar for Desktop & Tablet
                    if (!isMobile) sidebarWidget,

                    // Main Content Area
                    Expanded(
                      child: Column(
                        children: [
                          // Header
                          _AdminHeader(
                            title: title,
                            showMenu: false,
                            adminName: authState.adminName,
                          ),
                          // Content Body
                          Expanded(child: navigationShell),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isMobile
                    ? _AdminBottomNavBar(
                        navigationShell: navigationShell,
                        adminName: authState.adminName,
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final String title;
  final bool showMenu;
  final String adminName;

  const _AdminHeader({
    required this.title,
    required this.showMenu,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showMenu) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textDark),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // User profile / info dropdown
          PopupMenuButton<int>(
            offset: const Offset(0, 50),
            position: PopupMenuPosition.under,
            onSelected: (val) {
              if (val == 1) {
                _showProfileDialog(context, adminName);
              } else if (val == 2) {
                _showSettingsDialog(context);
              } else if (val == 3) {
                _showLogoutConfirmDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(color: AppColors.border),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 18,
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
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final bool isCollapsed;
  final StatefulNavigationShell navigationShell;
  final String adminName;

  const _SidebarContent({
    required this.isCollapsed,
    required this.navigationShell,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 80 : 250,
      height: double.infinity,
      color: AppColors.grey900,
      child: Column(
        children: [
          // Logo/Brand Section
          Container(
            height: 70,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.5),
              ),
            ),
            child: isCollapsed
                ? const Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.primary,
                    size: 28,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LEMAKIN ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          // Navigation items
          _buildSidebarItem(
            context,
            icon: Icons.dashboard,
            label: 'Dashboard',
            index: 0,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.restaurant_menu,
            label: 'Menu Management',
            index: 1,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Income Reports',
            index: 2,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.receipt_long,
            label: 'Expense Reports',
            index: 3,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.settings,
            label: 'Settings',
            index: -1,
            isSettings: true,
          ),
          const Spacer(),
          // Logout at bottom
          _buildSidebarItem(
            context,
            icon: Icons.power_settings_new,
            label: 'Logout',
            index: -1,
            isLogout: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    bool isLogout = false,
    bool isSettings = false,
  }) {
    // Determine active route
    final bool isActive =
        !isLogout && !isSettings && navigationShell.currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () {
          if (isLogout) {
            _showLogoutConfirmDialog(context);
          } else if (isSettings) {
            if (Scaffold.of(context).hasDrawer) {
              Navigator.pop(context);
            }
            _showSettingsDialog(context);
          } else {
            if (Scaffold.of(context).hasDrawer) {
              Navigator.pop(context);
            }
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border(left: BorderSide(color: activeColor, width: 4))
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 16,
            vertical: 14,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isLogout
                    ? AppColors.error
                    : (isActive ? activeColor : inactiveColor),
                size: 22,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isLogout
                        ? AppColors.error
                        : (isActive ? Colors.white : inactiveColor),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
Future<void> _seedFirestoreData(BuildContext context) async {
  try {
    final menuRepo = di.sl<MenuRepository>();
    final expenseRepo = di.sl<ExpenseRepository>();

    // 1. Seed Categories
    final categories = [
      const MenuCategory(id: 'cat_rice', name: 'Rice'),
      const MenuCategory(id: 'cat_noodles', name: 'Noodles'),
      const MenuCategory(id: 'cat_chicken', name: 'Chicken'),
      const MenuCategory(id: 'cat_snack', name: 'Snack'),
      const MenuCategory(id: 'cat_drink', name: 'Drink'),
      const MenuCategory(id: 'cat_dessert', name: 'Dessert'),
    ];
    for (final cat in categories) {
      await menuRepo.addCategory(cat);
    }

    // 2. Seed Menu Items
    final items = [
      const MenuItem(
        id: 'item_katsu',
        name: 'Chicken Katsu',
        description:
            'Crispy chicken breast with savory tonkatsu sauce, cabbage salad and warm rice.',
        price: 35000,
        imageUrl:
            'https://images.unsplash.com/photo-1598515214211-89d3e73ae83b?q=80&w=600',
        isRecommended: true,
        categoryId: 'cat_chicken',
        variants: [
          MenuVariant(
            id: 'v_katsu_flavor',
            name: 'Flavor',
            isRequired: true,
            options: [
              VariantOption(id: 'opt_katsu_orig', name: 'Original Sauce'),
              VariantOption(
                id: 'opt_katsu_spicy',
                name: 'Spicy Fire Sauce',
                additionalPrice: 3000,
              ),
              VariantOption(
                id: 'opt_katsu_cheese',
                name: 'Cheese Dip Sauce',
                additionalPrice: 5000,
              ),
            ],
          ),
        ],
      ),
      const MenuItem(
        id: 'item_teriyaki',
        name: 'Beef Teriyaki Rice Bowl',
        description:
            'Stir-fried sliced beef with sweet teriyaki sauce, onions, and sesame seeds over rice.',
        price: 42000,
        imageUrl:
            'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?q=80&w=600',
        isRecommended: true,
        categoryId: 'cat_rice',
        variants: [
          MenuVariant(
            id: 'v_teriyaki_size',
            name: 'Size',
            isRequired: true,
            options: [
              VariantOption(id: 'opt_teriyaki_reg', name: 'Regular'),
              VariantOption(
                id: 'opt_teriyaki_large',
                name: 'Jumbo Beef Portion',
                additionalPrice: 12000,
              ),
            ],
          ),
        ],
      ),
      const MenuItem(
        id: 'item_spicy_ramen',
        name: 'Spicy Miso Ramen',
        description:
            'Noodles in spicy rich miso broth topped with egg, chashu chicken, corn and green onions.',
        price: 38000,
        imageUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=600',
        isRecommended: true,
        categoryId: 'cat_noodles',
        variants: [
          MenuVariant(
            id: 'v_ramen_spicy',
            name: 'Spicy Level',
            isRequired: true,
            options: [
              VariantOption(id: 'opt_ramen_lvl1', name: 'Level 1 - Mild'),
              VariantOption(
                id: 'opt_ramen_lvl3',
                name: 'Level 3 - Medium Spicy',
                additionalPrice: 2000,
              ),
              VariantOption(
                id: 'opt_ramen_lvl5',
                name: 'Level 5 - Extreme Spicy',
                additionalPrice: 4000,
              ),
            ],
          ),
        ],
      ),
      const MenuItem(
        id: 'item_iced_tea',
        name: 'Iced Sweet Jasmine Tea',
        description:
            'Refreshing brewed jasmine green tea served chilled with pure sugar syrup.',
        price: 8000,
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=600',
        isRecommended: false,
        categoryId: 'cat_drink',
        variants: [
          MenuVariant(
            id: 'v_tea_size',
            name: 'Size',
            isRequired: false,
            options: [
              VariantOption(id: 'opt_tea_reg', name: 'Regular Size'),
              VariantOption(
                id: 'opt_tea_jumbo',
                name: 'Jumbo Size',
                additionalPrice: 3000,
              ),
            ],
          ),
        ],
      ),
    ];
    for (final item in items) {
      await menuRepo.addMenuItem(item);
    }

    // 3. Seed Expenses
    final now = DateTime.now();
    final expenses = [
      Expense(
        id: 'EXP_001',
        date: now.subtract(const Duration(days: 10)),
        category: 'Internet',
        description: 'Monthly Fiber Internet Bill',
        amount: 350000,
        notes: 'Paid via auto-debit',
        createdBy: 'Super Admin',
      ),
      Expense(
        id: 'EXP_002',
        date: now.subtract(const Duration(days: 5)),
        category: 'Raw Materials',
        description: 'Purchase meat & chicken stock',
        amount: 1500000,
        notes: 'Supplier: Jaya Meat',
        createdBy: 'Super Admin',
      ),
    ];
    for (final exp in expenses) {
      await expenseRepo.addExpense(exp);
    }

    if (context.mounted) {
      showAppToast(
        context,
        'Firestore Database seeded successfully! Please refresh pages.',
        type: AppToastType.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showAppToast(
        context,
        'Failed to seed database: $e',
        type: AppToastType.error,
      );
    }
  }
}

// ==========================================
// File-Level Common Admin Dialog Helpers
// ==========================================

void _showLogoutConfirmDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm Logout'),
      content: const Text(
        'Are you sure you want to log out of the Admin session?',
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
            context.read<AdminAuthCubit>().logout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

void _showProfileDialog(BuildContext context, String adminName) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final emailPrefix = adminName.toLowerCase().replaceAll(' ', '.');
      final dynamicEmail = emailPrefix.contains('@')
          ? emailPrefix
          : '$emailPrefix@lemakin.com';

      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bottom sheet drag handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              adminName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Super Admin Role',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            _buildProfileRow('Email', dynamicEmail),
            _buildProfileRow('Permissions', 'All Access'),
            _buildProfileRow('Joined', 'August 2026'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: () => Navigator.pop(sheetCtx),
                borderRadius: 12,
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showSettingsDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('settings')
            .doc('store')
            .get(),
        builder: (builderCtx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(
                child: AppLoadingIndicator(width: 100, height: 100),
              ),
            );
          }

          String restaurantName = 'Lemakin Restaurant';
          String logoUrl = '';
          bool isShopOpen = true;
          bool isClosedTemporarily = false;
          DateTime? closedUntil;

          String openingTime = '09:00';
          String closingTime = '22:00';

          if (snapshot.hasData && snapshot.data!.exists) {
            final sData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            restaurantName =
                sData['restaurantName'] as String? ?? 'Lemakin Restaurant';
            logoUrl = sData['logoUrl'] as String? ?? '';
            isShopOpen = sData['isShopOpen'] as bool? ?? true;
            isClosedTemporarily =
                sData['isClosedTemporarily'] as bool? ?? false;
            if (sData['closedUntil'] != null) {
              closedUntil = DateTime.tryParse(sData['closedUntil'] as String);
            }
            openingTime = sData['openingTime'] as String? ?? '09:00';
            closingTime = sData['closingTime'] as String? ?? '22:00';
          }

          // Check if temp closed has expired
          if (isClosedTemporarily &&
              closedUntil != null &&
              closedUntil.isBefore(DateTime.now())) {
            isClosedTemporarily = false;
            closedUntil = null;
          }

          return _SystemSettingsForm(
            initialRestaurantName: restaurantName,
            initialLogoUrl: logoUrl,
            initialShopOpen: isShopOpen,
            initialClosedTemporarily: isClosedTemporarily,
            initialClosedUntil: closedUntil,
            initialOpeningTime: openingTime,
            initialClosingTime: closingTime,
            sheetCtx: sheetCtx,
            parentCtx: context,
          );
        },
      );
    },
  );
}

class _SystemSettingsForm extends StatefulWidget {
  final String initialRestaurantName;
  final String initialLogoUrl;
  final bool initialShopOpen;
  final bool initialClosedTemporarily;
  final DateTime? initialClosedUntil;
  final String initialOpeningTime;
  final String initialClosingTime;
  final BuildContext sheetCtx;
  final BuildContext parentCtx;

  const _SystemSettingsForm({
    required this.initialRestaurantName,
    required this.initialLogoUrl,
    required this.initialShopOpen,
    required this.initialClosedTemporarily,
    required this.initialClosedUntil,
    required this.initialOpeningTime,
    required this.initialClosingTime,
    required this.sheetCtx,
    required this.parentCtx,
  });

  @override
  State<_SystemSettingsForm> createState() => _SystemSettingsFormState();
}

class _SystemSettingsFormState extends State<_SystemSettingsForm> {
  late TextEditingController nameController;
  late TextEditingController logoController;
  late TextEditingController openingTimeController;
  late TextEditingController closingTimeController;
  late bool isShopOpen;
  late bool isClosedTemporarily;
  DateTime? closedUntil;
  int? selectedMinutes;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialRestaurantName);
    logoController = TextEditingController(text: widget.initialLogoUrl);
    openingTimeController = TextEditingController(
      text: widget.initialOpeningTime,
    );
    closingTimeController = TextEditingController(
      text: widget.initialClosingTime,
    );
    isShopOpen = widget.initialShopOpen;
    isClosedTemporarily = widget.initialClosedTemporarily;
    closedUntil = widget.initialClosedUntil;
  }

  @override
  void dispose() {
    nameController.dispose();
    logoController.dispose();
    openingTimeController.dispose();
    closingTimeController.dispose();
    super.dispose();
  }

  Future<String?> _selectTime(
    BuildContext context,
    String initialTimeStr,
  ) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    try {
      final parts = initialTimeStr.split(':');
      if (parts.length == 2) {
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isTempClosedNow =
        isClosedTemporarily &&
        closedUntil != null &&
        closedUntil!.isAfter(DateTime.now());

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(widget.sheetCtx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bottom sheet drag handle indicator
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
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'System Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Restaurant Name',
                  labelStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const Center(
              child: Text(
                'Restaurant Logo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ListenableBuilder(
                listenable: logoController,
                builder: (context, _) {
                  final hasLogo = logoController.text.isNotEmpty;
                  return Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      image: hasLogo
                          ? DecorationImage(
                              image: NetworkImage(logoController.text.trim()),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child: !hasLogo
                        ? Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TextFormField(
                controller: logoController,
                decoration: InputDecoration(
                  labelText: 'Logo URL',
                  labelStyle: const TextStyle(fontSize: 12),
                  hintText: 'Paste logo image link...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Operational Status & Hours',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              title: const Text('Store Status', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                isShopOpen
                    ? (isTempClosedNow
                          ? 'Outlet Temporarily Closed until ${closedUntil!.hour.toString().padLeft(2, '0')}:${closedUntil?.minute.toString().padLeft(2, '0')}'
                          : 'Store is OPEN for orders')
                    : 'Store is CLOSED for orders',
                style: TextStyle(
                  fontSize: 11,
                  color: isTempClosedNow
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: isTempClosedNow
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              value: isShopOpen,
              onChanged: (val) {
                setState(() {
                  isShopOpen = val;
                  if (!val) {
                    isClosedTemporarily = false;
                    closedUntil = null;
                    selectedMinutes = null;
                  }
                });
              },
              activeColor: isTempClosedNow
                  ? AppColors.error
                  : AppColors.success,
              contentPadding: EdgeInsets.zero,
            ),

            if (isShopOpen) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Temporarily Closed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Close the outlet for a specified duration. The shop will automatically reopen after the time expires.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isTempClosedNow) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status: Temporarily Closed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  'Until ${closedUntil!.hour.toString().padLeft(2, '0')}:${closedUntil!.minute.toString().padLeft(2, '0')} (${closedUntil!.difference(DateTime.now()).inMinutes} minutes remaining)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isClosedTemporarily = false;
                                closedUntil = null;
                                selectedMinutes = null;
                              });
                            },
                            child: const Text('Open Now'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDurationChip(
                            context,
                            '15 Menit',
                            15,
                            selectedMinutes == 15,
                            (dt) {
                              setState(() {
                                isClosedTemporarily = true;
                                closedUntil = dt;
                                selectedMinutes = 15;
                              });
                            },
                          ),
                          _buildDurationChip(
                            context,
                            '30 Menit',
                            30,
                            selectedMinutes == 30,
                            (dt) {
                              setState(() {
                                isClosedTemporarily = true;
                                closedUntil = dt;
                                selectedMinutes = 30;
                              });
                            },
                          ),
                          _buildDurationChip(
                            context,
                            '1 Jam',
                            60,
                            selectedMinutes == 60,
                            (dt) {
                              setState(() {
                                isClosedTemporarily = true;
                                closedUntil = dt;
                                selectedMinutes = 60;
                              });
                            },
                          ),
                          _buildDurationChip(
                            context,
                            '2 Jam',
                            120,
                            selectedMinutes == 120,
                            (dt) {
                              setState(() {
                                isClosedTemporarily = true;
                                closedUntil = dt;
                                selectedMinutes = 120;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(
                              'Custom',
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedMinutes == -1
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: selectedMinutes == -1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: selectedMinutes == -1,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: selectedMinutes == -1
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            onSelected: (val) async {
                              if (val) {
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                      initialEntryMode:
                                          TimePickerEntryMode.inputOnly,
                                    );
                                if (pickedTime != null) {
                                  final now = DateTime.now();
                                  var targetDateTime = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  if (targetDateTime.isBefore(now)) {
                                    targetDateTime = targetDateTime.add(
                                      const Duration(days: 1),
                                    );
                                  }
                                  setState(() {
                                    isClosedTemporarily = true;
                                    closedUntil = targetDateTime;
                                    selectedMinutes = -1;
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Text(
              'Operation Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSettingField(
                    'Opening Time',
                    openingTimeController,
                    onTap: () async {
                      final time = await _selectTime(
                        context,
                        openingTimeController.text,
                      );
                      if (time != null) {
                        openingTimeController.text = time;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSettingField(
                    'Closing Time',
                    closingTimeController,
                    onTap: () async {
                      final time = await _selectTime(
                        context,
                        closingTimeController.text,
                      );
                      if (time != null) {
                        closingTimeController.text = time;
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(widget.sheetCtx),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    onPressed: () async {
                      // Pop the bottom sheet first to prevent unmounting race conditions
                      Navigator.pop(widget.sheetCtx);

                      try {
                        await FirebaseFirestore.instance
                            .collection('settings')
                            .doc('store')
                            .set({
                              'restaurantName': nameController.text.trim(),
                              'logoUrl': logoController.text.trim(),
                              'isShopOpen': isShopOpen,
                              'isClosedTemporarily': isClosedTemporarily,
                              'closedUntil': closedUntil?.toUtc().toIso8601String(),
                              'openingTime': openingTimeController.text.trim(),
                              'closingTime': closingTimeController.text.trim(),
                            }, SetOptions(merge: true));

                        if (widget.parentCtx.mounted) {
                          showAppToast(
                            widget.parentCtx,
                            'Settings saved successfully!',
                            type: AppToastType.success,
                          );
                        }
                      } catch (e) {
                        if (widget.parentCtx.mounted) {
                          showAppToast(
                            widget.parentCtx,
                            'Failed to save settings: $e',
                            type: AppToastType.error,
                          );
                        }
                      }
                    },
                    borderRadius: 12,
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
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
    );
  }
}

Widget _buildDurationChip(
  BuildContext context,
  String label,
  int minutes,
  bool isSelected,
  void Function(DateTime) onSelect,
) {
  return ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    selected: isSelected,
    selectedColor: AppColors.primary,
    backgroundColor: Colors.white,
    checkmarkColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
        width: 1,
      ),
    ),
    onSelected: (val) {
      if (val) {
        final targetTime = DateTime.now().add(Duration(minutes: minutes));
        onSelect(targetTime);
      }
    },
  );
}

Widget _buildProfileRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    ),
  );
}

Widget _buildSettingField(
  String label,
  TextEditingController controller, {
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: onTap != null
            ? IconButton(
                icon: const Icon(Icons.access_time, size: 18),
                onPressed: onTap,
              )
            : null,
      ),
    ),
  );
}

// ==========================================
// Bottom Navigation Bar Widget and Helpers
// ==========================================

class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final bool isAction;
  final VoidCallback? onTap;

  _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.isAction = false,
    this.onTap,
  });
}

class _AdminBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String adminName;

  const _AdminBottomNavBar({
    required this.navigationShell,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _BottomNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
        index: 0,
      ),
      _BottomNavItem(
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu_rounded,
        label: 'Menu',
        index: 1,
      ),
      _BottomNavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Income',
        index: 2,
      ),
      _BottomNavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Expense',
        index: 3,
      ),
      _BottomNavItem(
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz_rounded,
        label: 'More',
        index: -1,
        isAction: true,
        onTap: () => _showMoreSheet(context),
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final bool isActive =
                  !item.isAction && navigationShell.currentIndex == item.index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (item.isAction) {
                      item.onTap?.call();
                    } else {
                      navigationShell.goBranch(
                        item.index,
                        initialLocation:
                            item.index == navigationShell.currentIndex,
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive ? AppColors.primaryGradient : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header/Profile
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                // Actions
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textDark,
                  ),
                  title: const Text(
                    'System Settings',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showSettingsDialog(context);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.textDark,
                  ),
                  title: const Text(
                    'My Profile',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showProfileDialog(context, adminName);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showLogoutConfirmDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
