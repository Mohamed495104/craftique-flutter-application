import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist.dart';
import '../services/firebase_options.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _allProducts = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DatabaseReference? _database;

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
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      print('Initializing Firebase in HomeScreen...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      ).ref();
      print('Firebase Database initialized successfully');
      await fetchProductsFromRealtimeDB();
    } catch (e) {
      print('Error initializing Firebase in HomeScreen: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProductsFromRealtimeDB() async {
    if (_database == null) {
      print('Database not initialized');
      return;
    }
    try {
      print('Fetching products from Firebase at /products...');
      final snapshot = await _database!.child('products').once();
      final rawData = snapshot.snapshot.value;
      print('Raw data: $rawData');

      if (rawData == null) {
        print('No data found at /products');
        setState(() {
          _allProducts = [];
        });
        return;
      }

      if (rawData is List) {
        print('Data is a List with ${rawData.length} items');
        final products = rawData
            .asMap()
            .entries
            .where((entry) => entry.value != null)
            .map((entry) {
          final index = entry.key;
          final map = Map<String, dynamic>.from(entry.value as Map);
          return Product.fromMap(map, map['id'] ?? index.toString());
        }).toList();

        setState(() {
          _allProducts = products;
        });
        print('Successfully loaded ${products.length} products');
      } else if (rawData is Map) {
        print('Data is a Map with ${rawData.length} items');
        final products = rawData.entries.map((entry) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          return Product.fromMap(map, map['id'] ?? entry.key);
        }).toList();

        setState(() {
          _allProducts = products;
        });
        print('Successfully loaded ${products.length} products');
      } else {
        print('Unexpected data format: $rawData');
        print('Data type: ${rawData.runtimeType}');
        setState(() {
          _allProducts = [];
        });
      }
    } catch (e) {
      print('Error fetching products from Realtime DB: $e');
      setState(() {
        _allProducts = [];
      });
    }
  }

  List<Product> get filteredProducts {
    List<Product> filtered = _allProducts;

    if (selectedCategory != 'All') {
      filtered = filtered
          .where((product) => product.category == selectedCategory)
          .toList();
    }

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

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
  }

  void logout() {
    // FirebaseAuth.instance.signOut(); // Uncomment to enable logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
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
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/wishlist');
                },
                icon: const Icon(
                  Icons.favorite,
                  color: Color(0xFF8B4513),
                ),
              ),
              if (Provider.of<WishlistProvider>(context).wishlist.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${Provider.of<WishlistProvider>(context).wishlist.length}',
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
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
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
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFF8B4513),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
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
          ),
          if (searchQuery.isNotEmpty || selectedCategory != 'All')
            Container(
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
                  if (searchQuery.isNotEmpty || selectedCategory != 'All')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          selectedCategory = 'All';
                          _searchController.clear();
                        });
                      },
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
            ),
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.inventory_2_outlined,
                          size: 64,
                          color: const Color(0xFF8B4513).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No products found for "$searchQuery"'
                              : 'No products available',
                          style: const TextStyle(
                            color: Color(0xFF8B4513),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (searchQuery.isNotEmpty || selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                  selectedCategory = 'All';
                                  _searchController.clear();
                                });
                              },
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
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/product-details',
                            arguments: product,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: logout,
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.logout, color: Colors.white),
      ),
    );
  }
}
