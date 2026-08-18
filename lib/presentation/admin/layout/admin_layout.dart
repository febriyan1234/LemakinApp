import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const AdminLayout({super.key, required this.child, required this.title});

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
                currentPath: GoRouterState.of(context).uri.path,
                adminName: authState.adminName,
              );

              return Scaffold(
                backgroundColor: AppColors.scaffoldBackground,
                drawer: isMobile ? Drawer(child: sidebarWidget) : null,
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
                            showMenu: isMobile,
                            adminName: authState.adminName,
                          ),
                          // Content Body
                          Expanded(child: SelectionArea(child: child)),
                        ],
                      ),
                    ),
                  ],
                ),
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
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!showMenu) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          adminName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.person, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
            offset: const Offset(0, 50),
            position: PopupMenuPosition.under,
            onSelected: (val) {
              if (val == 1) {
                _showProfileDialog(context);
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
              const PopupMenuDivider(),
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
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of the Admin session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AdminAuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('My Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(adminName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Super Admin Role', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildProfileRow('Email', 'admin@lemakin.com'),
            _buildProfileRow('Permissions', 'All Access'),
            _buildProfileRow('Joined', 'August 2026'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    bool isShopOpen = true;
    bool isPrinterEnabled = true;
    bool isNotifEnabled = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('System Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingField('Shop Name', 'Lemakin Restaurant'),
                  _buildSettingField('Tax Rate (%)', '10'),
                  _buildSettingField('Service Charge (%)', '5'),
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
                      isShopOpen ? 'Shop is OPEN for orders' : 'Shop is CLOSED for orders',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: isShopOpen,
                    onChanged: (val) {
                      setState(() {
                        isShopOpen = val;
                      });
                    },
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSettingField('Opening Time', '09:00'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSettingField('Closing Time', '22:00'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Devices & Notifications',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    title: const Text('Kitchen Printer', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Print order ticket on checkout', style: TextStyle(fontSize: 11)),
                    value: isPrinterEnabled,
                    onChanged: (val) {
                      setState(() {
                        isPrinterEnabled = val;
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Play sound on new orders', style: TextStyle(fontSize: 11)),
                    value: isNotifEnabled,
                    onChanged: (val) {
                      setState(() {
                        isNotifEnabled = val;
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _seedFirestoreData(context);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text(
                        'Seed Initial Data to Firestore',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSettingField(String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final bool isCollapsed;
  final String currentPath;
  final String adminName;

  const _SidebarContent({
    required this.isCollapsed,
    required this.currentPath,
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
            path: '/admin/dashboard',
          ),
          _buildSidebarItem(
            context,
            icon: Icons.restaurant_menu,
            label: 'Menu Management',
            path: '/admin/menu',
          ),
          _buildSidebarItem(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Income Reports',
            path: '/admin/reports/income',
          ),
          _buildSidebarItem(
            context,
            icon: Icons.receipt_long,
            label: 'Expense Reports',
            path: '/admin/reports/expense',
          ),
          _buildSidebarItem(
            context,
            icon: Icons.settings,
            label: 'Settings',
            path: 'settings',
            isSettings: true,
          ),
          const Spacer(),
          // Logout at bottom
          _buildSidebarItem(
            context,
            icon: Icons.power_settings_new,
            label: 'Logout',
            path: 'logout',
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
    required String path,
    bool isLogout = false,
    bool isSettings = false,
  }) {
    // Determine active route
    final bool isActive = !isLogout && !isSettings && currentPath.startsWith(path);
    final activeColor = AppColors.primary;
    final inactiveColor = Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () {
          if (isLogout) {
            _showLogoutConfirm(context);
          } else if (isSettings) {
            if (Scaffold.of(context).hasDrawer) {
              Navigator.pop(context);
            }
            _showSettingsDialog(context);
          } else {
            if (Scaffold.of(context).hasDrawer) {
              Navigator.pop(context);
            }
            context.go(path);
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

  void _showLogoutConfirm(BuildContext context) {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    bool isShopOpen = true;
    bool isPrinterEnabled = true;
    bool isNotifEnabled = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('System Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingField('Shop Name', 'Lemakin Restaurant'),
                  _buildSettingField('Tax Rate (%)', '10'),
                  _buildSettingField('Service Charge (%)', '5'),
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
                      isShopOpen ? 'Shop is OPEN for orders' : 'Shop is CLOSED for orders',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: isShopOpen,
                    onChanged: (val) {
                      setState(() {
                        isShopOpen = val;
                      });
                    },
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSettingField('Opening Time', '09:00'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSettingField('Closing Time', '22:00'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Devices & Notifications',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    title: const Text('Kitchen Printer', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Print order ticket on checkout', style: TextStyle(fontSize: 11)),
                    value: isPrinterEnabled,
                    onChanged: (val) {
                      setState(() {
                        isPrinterEnabled = val;
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Play sound on new orders', style: TextStyle(fontSize: 11)),
                    value: isNotifEnabled,
                    onChanged: (val) {
                      setState(() {
                        isNotifEnabled = val;
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _seedFirestoreData(context);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text(
                        'Seed Initial Data to Firestore',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingField(String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

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
        description: 'Crispy chicken breast with savory tonkatsu sauce, cabbage salad and warm rice.',
        price: 35000,
        imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3e73ae83b?q=80&w=600',
        isRecommended: true,
        categoryId: 'cat_chicken',
        variants: [
          MenuVariant(
            id: 'v_katsu_flavor',
            name: 'Flavor',
            isRequired: true,
            options: [
              VariantOption(id: 'opt_katsu_orig', name: 'Original Sauce'),
              VariantOption(id: 'opt_katsu_spicy', name: 'Spicy Fire Sauce', additionalPrice: 3000),
              VariantOption(id: 'opt_katsu_cheese', name: 'Cheese Dip Sauce', additionalPrice: 5000),
            ],
          ),
        ],
      ),
      const MenuItem(
        id: 'item_teriyaki',
        name: 'Beef Teriyaki Rice Bowl',
        description: 'Stir-fried sliced beef with sweet teriyaki sauce, onions, and sesame seeds over rice.',
        price: 42000,
        imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?q=80&w=600',
        isRecommended: true,
        categoryId: 'cat_rice',
        variants: [
          MenuVariant(
            id: 'v_teriyaki_size',
            name: 'Size',
            isRequired: true,
            options: [
              VariantOption(id: 'opt_teriyaki_reg', name: 'Regular'),
              VariantOption(id: 'opt_teriyaki_large', name: 'Jumbo Beef Portion', additionalPrice: 12000),
            ],
          ),
        ],
      ),
      const MenuItem(
        id: 'item_spicy_ramen',
        name: 'Spicy Miso Ramen',
        description: 'Noodles in spicy rich miso broth topped with egg, chashu chicken, corn and green onions.',
        price: 38000,
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=600',
        isRecommended: true,
        categoryId: 'cat_noodles',
        variants: [
          MenuVariant(
            id: 'v_ramen_spicy',
            name: 'Spicy Level',
            isRequired: true,
            options: [
              VariantOption(id: 'opt_ramen_lvl1', name: 'Level 1 - Mild'),
              VariantOption(id: 'opt_ramen_lvl3', name: 'Level 3 - Medium Spicy', additionalPrice: 2000),
              VariantOption(id: 'opt_ramen_lvl5', name: 'Level 5 - Extreme Spicy', additionalPrice: 4000),
            ],
          ),
        ],
      ),
      const MenuItem(
        id: 'item_iced_tea',
        name: 'Iced Sweet Jasmine Tea',
        description: 'Refreshing brewed jasmine green tea served chilled with pure sugar syrup.',
        price: 8000,
        imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?q=80&w=600',
        isRecommended: false,
        categoryId: 'cat_drink',
        variants: [
          MenuVariant(
            id: 'v_tea_size',
            name: 'Size',
            isRequired: false,
            options: [
              VariantOption(id: 'opt_tea_reg', name: 'Regular Size'),
              VariantOption(id: 'opt_tea_jumbo', name: 'Jumbo Size', additionalPrice: 3000),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore Database seeded successfully! Please refresh pages.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to seed database: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
