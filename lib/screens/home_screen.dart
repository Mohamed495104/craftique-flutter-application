import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/wishlist.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data variables
  List<Product> _allProducts = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Categories for filtering
  final List<String> categories = [
    'All',
    'Paintings',
    'Ceramics',
    'Jewelry',
    'Clothing',
    'Miniature'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load products from Firebase
  Future<void> _loadProducts() async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      );

      final ref = database.ref().child('products');
      final snapshot = await ref.once();
      final rawData = snapshot.snapshot.value;

      if (rawData == null) {
        print('No products found');
        return;
      }

      if (rawData is List) {
        final products = rawData.where((item) => item != null).map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return Product.fromMap(map, map['id'] ?? '');
        }).toList();

        setState(() {
          _allProducts = products;
        });
        print('Loaded ${products.length} products');
      }
    } catch (error) {
      print('Error loading products: $error');
    }
  }

  // Filter products based on category and search
  List<Product> get filteredProducts {
    List<Product> filtered = _allProducts;

    // Filter by category
    if (selectedCategory != 'All') {
      filtered = filtered
          .where((product) => product.category == selectedCategory)
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = product.name.toLowerCase();
        final description = product.description.toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    return filtered;
  }

  // Clear search input
  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
  }

  // Clear all filters
  void _clearAllFilters() {
    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      _searchController.clear();
    });
  }

  // Navigate to product details
  void _navigateToProductDetails(Product product) {
    Navigator.pushNamed(
      context,
      '/product-details',
      arguments: product,
    );
  }

  // Handle logout
  void _handleLogout() {
    // FirebaseAuth.instance.signOut(); // Uncomment when needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildResultsInfo(),
          _buildProductsGrid(),
        ],
      ),
      floatingActionButton: _buildLogoutButton(),
    );
  }

  // Build app bar with title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "Craftique",
        style: TextStyle(
          color: Color(0xFF8B4513),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        _buildWishlistIcon(),
        _buildShoppingCartIcon(),
      ],
    );
  }

  // Build wishlist icon with count
  Widget _buildWishlistIcon() {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final wishlistCount = wishlistProvider.wishlist.length;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/wishlist'),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: wishlistCount > 0
                  ? const Color(0xFF8B4513).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: wishlistCount > 0
                  ? Border.all(color: const Color(0xFF8B4513).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  wishlistCount > 0 ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFF8B4513),
                  size: 22,
                ),
                if (wishlistCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$wishlistCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Build shopping cart icon
  Widget _buildShoppingCartIcon() {
    return IconButton(
      onPressed: () {}, // Add cart functionality when needed
      icon: const Icon(
        Icons.shopping_cart_outlined,
        color: Color(0xFF8B4513),
      ),
    );
  }

  // Build search bar
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
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search for crafts...',
          hintStyle: TextStyle(
            color: const Color(0xFF8B4513).withOpacity(0.6),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF8B4513),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF8B4513),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        style: const TextStyle(
          color: Color(0xFF8B4513),
          fontSize: 16,
        ),
      ),
    );
  }

  // Build category selection chips
  Widget _buildCategoryChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              onSelected: (_) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  // Build results info and clear filters option
  Widget _buildResultsInfo() {
    final hasFilters = searchQuery.isNotEmpty || selectedCategory != 'All';

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Showing ${filteredProducts.length} result${filteredProducts.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: const Color(0xFF8B4513).withOpacity(0.7),
              fontSize: 14,
            ),
          ),
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

  // Build products grid or empty state
  Widget _buildProductsGrid() {
    return Expanded(
      child:
          filteredProducts.isEmpty ? _buildEmptyState() : _buildProductsList(),
    );
  }

  // Build empty state when no products found
  Widget _buildEmptyState() {
    final hasSearch = searchQuery.isNotEmpty;
    final hasFilters = searchQuery.isNotEmpty || selectedCategory != 'All';

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
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build products list grid
  Widget _buildProductsList() {
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
          onTap: () => _navigateToProductDetails(product),
        );
      },
    );
  }

  // Build logout floating action button
  Widget _buildLogoutButton() {
    return FloatingActionButton(
      onPressed: _handleLogout,
      backgroundColor: const Color(0xFF8B4513),
      child: const Icon(Icons.logout, color: Colors.white),
    );
  }
}
