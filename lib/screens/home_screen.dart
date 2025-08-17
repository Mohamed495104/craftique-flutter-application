import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist.dart';
import '../services/firebase_options.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> categories = [
    'All',
    'Paintings',
    'Ceramics',
    'Jewelry',
    'Clothing',
    'Miniature',
  ];

  final TextEditingController _searchController = TextEditingController();

  DatabaseReference? _database;
  List<Product> _allProducts = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  bool _isLoading = true;
  String? _error;

  static const String _dbUrl =
      'https://flutter-group-project-3541f-default-rtdb.firebaseio.com';

  @override
  void initState() {
    super.initState();
    _setupAndLoad();
  }

  Future<void> _setupAndLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _dbUrl,
      ).ref();

      await _loadProducts();
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProducts() async {
    if (_database == null) return;

    final snapshot = await _database!.child('products').once();
    final raw = snapshot.snapshot.value;
    final List<Product> loaded = [];

    if (raw == null) {
      _allProducts = [];
      return;
    }

    if (raw is List) {
      for (final item in raw) {
        if (item == null) continue;
        final map = Map<String, dynamic>.from(item as Map);
        loaded.add(Product.fromMap(map, map['id']?.toString() ?? ''));
      }
    } else if (raw is Map) {
      raw.forEach((key, value) {
        if (value == null) return;
        final map = Map<String, dynamic>.from(value as Map);
        loaded
            .add(Product.fromMap(map, map['id']?.toString() ?? key.toString()));
      });
    }

    if (mounted) {
      setState(() {
        _allProducts = loaded;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get filteredProducts {
    List<Product> filtered = _allProducts;

    if (selectedCategory != 'All') {
      filtered = filtered
          .where((p) => p.category == selectedCategory)
          .toList(growable: false);
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList(growable: false);
    }

    return filtered;
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
  }

  void _clearAllFilters() {
    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      _searchController.clear();
    });
  }

  void _openProduct(Product product) {
    Navigator.pushNamed(context, '/product-details', arguments: product);
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F0),
      drawer: _buildNavDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildCategoryChips(),
                    _buildResultsInfo(),
                    _buildProductsGrid(),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.donut_small, color: Color(0xFF8B4513)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        'Craftique',
        style: TextStyle(
          color: Color(0xFF8B4513),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        _buildWishlistIcon(),
        _buildCartIcon(),
      ],
    );
  }

  Widget _buildNavDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? 'Guest');

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF8B4513)),
              accountName: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              accountEmail: Text(
                user?.email ?? '',
                overflow: TextOverflow.ellipsis,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF8B4513)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Wishlist'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wishlist');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Cart'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cart');
              },
            ),
            const Spacer(),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 150));
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistIcon() {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, _) {
        final count = wishlistProvider.wishlist.length;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/wishlist'),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: count > 0
                  ? const Color(0xFF8B4513).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: count > 0
                  ? Border.all(color: const Color(0xFF8B4513).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border,
                    color: Color(0xFF8B4513), size: 22),
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartIcon() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final count = cartProvider.cartItems.fold<int>(
          0,
          (sum, item) => sum + ((item['quantity'] as int?) ?? 1),
        );

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/cart'),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: count > 0
                  ? const Color(0xFF8B4513).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: count > 0
                  ? Border.all(color: const Color(0xFF8B4513).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFF8B4513), size: 22),
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search for crafts...',
          hintStyle: TextStyle(color: const Color(0xFF8B4513).withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8B4513)),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear, color: Color(0xFF8B4513)),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: const TextStyle(
          color: Color(0xFF8B4513),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8B4513),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF8B4513),
              backgroundColor: Colors.white.withOpacity(0.8),
              side: BorderSide(
                color: const Color(0xFF8B4513).withOpacity(0.3),
              ),
              onSelected: (_) => setState(() => selectedCategory = category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsInfo() {
    final hasFilters = searchQuery.isNotEmpty || selectedCategory != 'All';
    if (!hasFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Showing ${filteredProducts.length} result${filteredProducts.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: const Color(0xFF8B4513).withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text(
              'Clear filters',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Expanded(
      child: filteredProducts.isEmpty ? _buildEmptyState() : _buildGrid(),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = searchQuery.isNotEmpty;
    final hasFilters = hasSearch || selectedCategory != 'All';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: const Color(0xFF8B4513).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No products found for "$searchQuery"'
                : 'No products available',
            style: const TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: _clearAllFilters,
                child: const Text(
                  'Clear filters',
                  style: TextStyle(color: Color(0xFF8B4513)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 300,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () => _openProduct(product),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setupAndLoad,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
