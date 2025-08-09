import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  DatabaseReference? _database;
  String? _userId; // To store the user ID for Firebase

  CartProvider() {
    _initializeFirebase();
  }

  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  double get totalPrice => _cartItems.fold(
        0,
        (sum, item) => sum + (item['product'].price * (item['quantity'] ?? 1)),
      );

  // Initialize Firebase
  Future<void> _initializeFirebase() async {
    try {
      _database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL:
            'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      ).ref();
      // Hardcoded userId for demo purposes; replace with FirebaseAuth.instance.currentUser?.uid in a real app
      _userId = 'arm3PES7djfDl8GdO311631x3553';
      await _fetchCartFromFirebase();
    } catch (e) {
      debugPrint('Firebase init error in CartProvider: $e');
    }
  }

  // Fetch cart items from Firebase
  Future<void> _fetchCartFromFirebase() async {
    if (_database == null || _userId == null) return;

   _database!.child('cart/$_userId').onValue.listen((event) {
  final cartData = event.snapshot.value as Map<dynamic, dynamic>?;
  _cartItems.clear();
  if (cartData != null) {
    cartData.forEach((key, value) {
      final item = Map<String, dynamic>.from(value);
      final product = Product(
        id: item['productId'].toString(),
        name: item['productName'] ?? '',
        description: '',
        price: (item['price'] ?? 0).toDouble(),
        category: item['categoryName'] ?? '',
        rating: 0.0,
      );
      _cartItems.add({
        'product': product,
        'quantity': item['quantity'] ?? 1,
        'firebaseKey': key,
      });
    });
  }
  notifyListeners();
});
  }

  // Add product to cart
  Future<void> addToCart(Product product, {int quantity = 1, String? imageUrl}) async {
    if (_database == null || _userId == null) return;

    // Check if the product already exists in Firebase cart
    final snapshot = await _database!.child('cart/$_userId').orderByChild('productId').equalTo(product.id).once();
    final cartData = snapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (cartData != null && cartData.isNotEmpty) {
      // Product exists, update the quantity
      final existingKey = cartData.keys.first;
      final existingItem = cartData[existingKey] as Map<dynamic, dynamic>;
      final newQuantity = (existingItem['quantity'] ?? 0) + quantity;

      // Update local cart
      final localItem = _cartItems.firstWhere(
        (item) => item['product'].id == product.id,
        orElse: () => {},
      );
      if (localItem.isNotEmpty) {
        localItem['quantity'] = newQuantity;
      } else {
        _cartItems.add({
          'product': product,
          'quantity': newQuantity,
          'firebaseKey': existingKey,
        });
      }

      // Update Firebase
      await _database!.child('cart/$_userId/$existingKey').update({
        'quantity': newQuantity,
        'totalPrice': product.price * newQuantity,
        'timestamp': ServerValue.timestamp,
      });
    } else {
      // Add new item to Firebase
      final newCartItemRef = _database!.child('cart/$_userId').push();
      final newItem = {
        'product': product,
        'quantity': quantity,
        'firebaseKey': newCartItemRef.key,
      };
      _cartItems.add(newItem);

      await newCartItemRef.set({
        'categoryName': product.category,
        
        'imageUrl': imageUrl ?? '',
        'price': product.price,
        'productId': product.id,
        'productName': product.name,
        'quantity': quantity,
        
        'timestamp': ServerValue.timestamp,
        'totalPrice': product.price * quantity,
      });
    }
    notifyListeners();
  }

  // Update cart item in Firebase
  Future<void> _updateCartItemInFirebase(String firebaseKey, Product product, int quantity, String? imageUrl) async {
    if (_database == null || _userId == null) return;

    await _database!.child('cart/$_userId/$firebaseKey').update({
      'quantity': quantity,
      'totalPrice': product.price * quantity,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Remove product from cart
  Future<void> removeFromCart(Product product) async {
    if (_database == null || _userId == null) return;

    final item = _cartItems.firstWhere(
      (item) => item['product'].id == product.id,
      orElse: () => {},
    );

    if (item.isNotEmpty) {
      await _database!.child('cart/$_userId/${item['firebaseKey']}').remove();
      _cartItems.removeWhere((item) => item['product'].id == product.id);
      notifyListeners();
    }
  }

  // Update quantity in cart
  Future<void> updateQuantity(Product product, int quantity) async {
    if (_database == null || _userId == null) return;

    final existingItem = _cartItems.firstWhere(
      (item) => item['product'].id == product.id,
      orElse: () => {},
    );

    if (existingItem.isNotEmpty && quantity > 0) {
      existingItem['quantity'] = quantity;
      await _updateCartItemInFirebase(existingItem['firebaseKey'], product, quantity, null);
    } else if (quantity <= 0) {
      await removeFromCart(product);
    }
    notifyListeners();
  }

  // Clear cart
  Future<void> clearCart() async {
    if (_database == null || _userId == null) return;

    await _database!.child('cart/$_userId').remove();
    _cartItems.clear();
    notifyListeners();
  }
}