import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_category.dart';

abstract class MenuLocalDataSource {
  Future<List<MenuCategory>> getCategories();
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
  });
  Future<MenuItem?> getMenuItemDetail(String id);
  Future<List<MenuItem>> getRecommendedItems();
}

class MenuLocalDataSourceImpl implements MenuLocalDataSource {
  final List<MenuCategory> _categories = const [
    MenuCategory(id: 'cat_rice', name: 'Rice'),
    MenuCategory(id: 'cat_noodles', name: 'Noodles'),
    MenuCategory(id: 'cat_chicken', name: 'Chicken'),
    MenuCategory(id: 'cat_snack', name: 'Snack'),
    MenuCategory(id: 'cat_drink', name: 'Drink'),
    MenuCategory(id: 'cat_dessert', name: 'Dessert'),
  ];

  late final List<MenuItem> _menuItems = [
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
        MenuVariant(
          id: 'v_katsu_size',
          name: 'Size',
          isRequired: false,
          options: [
            VariantOption(id: 'opt_katsu_reg', name: 'Regular Size'),
            VariantOption(
              id: 'opt_katsu_large',
              name: 'Large Size + Rice',
              additionalPrice: 7000,
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
      id: 'item_karaage',
      name: 'Chicken Karaage',
      description:
          'Japanese style bite-sized deep-fried chicken, crispy outside and juicy inside.',
      price: 25000,
      imageUrl:
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_snack',
      variants: [
        MenuVariant(
          id: 'v_karaage_flavor',
          name: 'Dip Sauce',
          isRequired: false,
          options: [
            VariantOption(id: 'opt_karaage_mayo', name: 'Spicy Mayo'),
            VariantOption(
              id: 'opt_karaage_garlic',
              name: 'Garlic Butter Sauce',
              additionalPrice: 2000,
            ),
          ],
        ),
      ],
    ),
    const MenuItem(
      id: 'item_beef_ramen',
      name: 'Beef Shoyu Ramen',
      description:
          'Noodles in soy sauce broth topped with premium beef slices, seaweed, and soft boiled egg.',
      price: 40000,
      imageUrl:
          'https://images.unsplash.com/photo-1557872943-16a5ac26437e?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_noodles',
      variants: [
        MenuVariant(
          id: 'v_beef_ramen_size',
          name: 'Size',
          isRequired: false,
          options: [
            VariantOption(id: 'opt_beef_ramen_reg', name: 'Regular'),
            VariantOption(
              id: 'opt_beef_ramen_large',
              name: 'Double Noodles',
              additionalPrice: 6000,
            ),
          ],
        ),
      ],
    ),
    const MenuItem(
      id: 'item_gyoza',
      name: 'Pan-Fried Gyoza',
      description:
          'Classic chicken and vegetable dumplings pan-seared to crispy bottom perfection.',
      price: 20000,
      imageUrl:
          'https://images.unsplash.com/photo-1563245372-f21724e3856d?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_snack',
      variants: [],
    ),
    const MenuItem(
      id: 'item_fries',
      name: 'Shake Shake Fries',
      description:
          'Crispy French Fries shaken with your choice of premium savory seasoning powder.',
      price: 18000,
      imageUrl:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_snack',
      variants: [
        MenuVariant(
          id: 'v_fries_flavor',
          name: 'Flavor Seasoning',
          isRequired: true,
          options: [
            VariantOption(id: 'opt_fries_salt', name: 'Sea Salt'),
            VariantOption(
              id: 'opt_fries_bbq',
              name: 'Smoky Barbecue',
              additionalPrice: 1000,
            ),
            VariantOption(
              id: 'opt_fries_cheese',
              name: 'Cheesy Cheddar',
              additionalPrice: 1000,
            ),
          ],
        ),
      ],
    ),
    const MenuItem(
      id: 'item_matcha',
      name: 'Matcha Latte Ice',
      description:
          'Authentic stone-ground Uji matcha green tea whisked with cold milk and sweet syrup.',
      price: 22000,
      imageUrl:
          'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_drink',
      variants: [
        MenuVariant(
          id: 'v_matcha_size',
          name: 'Size',
          isRequired: false,
          options: [
            VariantOption(id: 'opt_matcha_reg', name: 'Regular 12oz'),
            VariantOption(
              id: 'opt_matcha_large',
              name: 'Large 16oz',
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
    const MenuItem(
      id: 'item_mango',
      name: 'Mango Pudding Dessert',
      description:
          'Silky smooth sweet mango pudding layered with fresh mango cubes and condensed cream.',
      price: 18000,
      imageUrl:
          'https://images.unsplash.com/photo-1587314168485-3236d6710814?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_dessert',
      variants: [],
    ),
    const MenuItem(
      id: 'item_nasgor',
      name: 'Special Nasi Goreng',
      description:
          'Traditional Indonesian fried rice with egg, chicken pieces, meatball, and crispy crackers.',
      price: 30000,
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-685f58884a24?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_rice',
      variants: [
        MenuVariant(
          id: 'v_nasgor_spicy',
          name: 'Spiciness',
          isRequired: true,
          options: [
            VariantOption(id: 'opt_nasgor_no', name: 'Non-spicy'),
            VariantOption(id: 'opt_nasgor_med', name: 'Spicy Level 2'),
            VariantOption(
              id: 'opt_nasgor_max',
              name: 'Spicy Level 5 + Egg',
              additionalPrice: 5000,
            ),
          ],
        ),
      ],
    ),
    const MenuItem(
      id: 'item_miegor',
      name: 'Javanese Mie Goreng',
      description:
          'Stir-fried egg noodles with sweet soy sauce, fresh vegetables, chicken slices and egg.',
      price: 28000,
      imageUrl:
          'https://images.unsplash.com/photo-1585032226651-759b368d7246?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_noodles',
      variants: [],
    ),
    const MenuItem(
      id: 'item_penyet',
      name: 'Ayam Penyet Sambal Ijo',
      description:
          'Smashed fried chicken served with fiery green chili paste, tofu, tempeh and fresh cabbage.',
      price: 32000,
      imageUrl:
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_chicken',
      variants: [
        MenuVariant(
          id: 'v_penyet_sambal',
          name: 'Chili Option',
          isRequired: true,
          options: [
            VariantOption(
              id: 'opt_penyet_ijo',
              name: 'Sambal Ijo (Green Chili)',
            ),
            VariantOption(
              id: 'opt_penyet_merah',
              name: 'Sambal Merah (Red Chili)',
            ),
          ],
        ),
      ],
    ),
    const MenuItem(
      id: 'item_boba',
      name: 'Brown Sugar Bubble Tea',
      description:
          'Ice milk tea with fresh cooked brown sugar tapioca boba pearls and heavy cream top.',
      price: 24000,
      imageUrl:
          'https://images.unsplash.com/photo-1541658016709-82535e94bc69?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_drink',
      variants: [
        MenuVariant(
          id: 'v_boba_size',
          name: 'Size',
          isRequired: true,
          options: [
            VariantOption(id: 'opt_boba_reg', name: 'Regular size'),
            VariantOption(
              id: 'opt_boba_large',
              name: 'Large size',
              additionalPrice: 5000,
            ),
          ],
        ),
      ],
    ),
    const MenuItem(
      id: 'item_icecream',
      name: 'Matcha & Vanilla Gelato',
      description:
          'Double scoop of premium artisanal Italian ice cream with chocolate drizzle.',
      price: 20000,
      imageUrl:
          'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?q=80&w=600',
      isRecommended: false,
      categoryId: 'cat_dessert',
      variants: [
        MenuVariant(
          id: 'v_gelato_flavor',
          name: 'Flavor Combo',
          isRequired: true,
          options: [
            VariantOption(id: 'opt_gelato_mix', name: 'Matcha & Vanilla Mix'),
            VariantOption(
              id: 'opt_gelato_double_matcha',
              name: 'Double Matcha scoops',
              additionalPrice: 2000,
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  Future<List<MenuCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _categories;
  }

  @override
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    Iterable<MenuItem> items = _menuItems;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      items = items.where((item) => item.name.toLowerCase().contains(query));
    } else if (categoryId != null &&
        categoryId != 'All' &&
        categoryId.isNotEmpty) {
      items = items.where((item) => item.categoryId == categoryId);
    }

    return items.toList();
  }

  @override
  Future<MenuItem?> getMenuItemDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _menuItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MenuItem>> getRecommendedItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _menuItems.where((item) => item.isRecommended).toList();
  }
}
