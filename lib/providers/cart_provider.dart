import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  DatabaseReference? _database;
  String? _userId;
  bool _isUpdating = false;

  CartProvider() {
    _initializeFirebase();
  }

  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  double get totalPrice => _cartItems.fold(
        0.0,
        (sum, item) => sum + (item['product'].price * (item['quantity'] ?? 1)),
      );

  Future<void> _initializeFirebase() async {
    try {
      _database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      ).ref();
      _userId = 'arm3PES7djfDl8GdO311631x3553'; // Replace with FirebaseAuth.instance.currentUser?.uid
      await _fetchCartFromFirebase();
    } catch (e) {
      debugPrint('Firebase init error in CartProvider: $e');
    }
  }

  Future<void> _fetchCartFromFirebase() async {
    if (_database == null || _userId == null) return;

    _database!.child('cart/$_userId').onValue.listen((event) {
      if (_isUpdating) {
        debugPrint('Skipping onValue update due to ongoing operation');
        return;
      }

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
      debugPrint('Fetched ${_cartItems.length} items from Firebase');
      notifyListeners();
    });
  }

  Future<void> addToCart(Product product, {int quantity = 1, String? imageUrl}) async {
    if (_database == null || _userId == null) return;

    _isUpdating = true;
    try {
      final snapshot = await _database!.child('cart/$_userId').orderByChild('productId').equalTo(product.id).once();
      final cartData = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (cartData != null && cartData.isNotEmpty) {
        final existingKey = cartData.keys.first;
        final existingItem = cartData[existingKey] as Map<dynamic, dynamic>;
        final newQuantity = (existingItem['quantity'] ?? 0) + quantity;

        final localItemIndex = _cartItems.indexWhere((item) => item['product'].id == product.id);
        if (localItemIndex != -1) {
          _cartItems[localItemIndex]['quantity'] = newQuantity;
        } else {
          _cartItems.add({
            'product': product,
            'quantity': newQuantity,
            'firebaseKey': existingKey,
          });
        }

        await _database!.child('cart/$_userId/$existingKey').update({
          'quantity': newQuantity,
          'totalPrice': product.price * newQuantity,
          'timestamp': ServerValue.timestamp,
        });
        debugPrint('Updated ${product.name} in cart, new quantity: $newQuantity');
      } else {
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
        debugPrint('Added ${product.name} to cart, quantity: $quantity');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _updateCartItemInFirebase(String firebaseKey, Product product, int quantity) async {
    if (_database == null || _userId == null) return;

    await _database!.child('cart/$_userId/$firebaseKey').update({
      'quantity': quantity,
      'totalPrice': product.price * quantity,
      'timestamp': ServerValue.timestamp,
    });
    debugPrint('Updated Firebase: ${product.name}, quantity: $quantity');
  }

  Future<void> removeFromCart(Product product) async {
    if (_database == null || _userId == null) return;

    _isUpdating = true;
    try {
      final itemIndex = _cartItems.indexWhere((item) => item['product'].id == product.id);
      if (itemIndex != -1) {
        final firebaseKey = _cartItems[itemIndex]['firebaseKey'];
        await _database!.child('cart/$_userId/$firebaseKey').remove();
        _cartItems.removeAt(itemIndex);
        debugPrint('Removed ${product.name} from cart, remaining: ${_cartItems.length}');
        notifyListeners();
      } else {
        debugPrint('Error: ${product.name} not found in cart');
      }
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> updateQuantity(Product product, int quantity) async {
    if (_database == null || _userId == null) return;

    _isUpdating = true;
    try {
      final itemIndex = _cartItems.indexWhere((item) => item['product'].id == product.id);
      if (itemIndex != -1 && quantity > 0) {
        _cartItems[itemIndex]['quantity'] = quantity;
        await _updateCartItemInFirebase(_cartItems[itemIndex]['firebaseKey'], product, quantity);
        debugPrint('Updated ${product.name} quantity to $quantity');
        notifyListeners();
      } else if (quantity <= 0) {
        await removeFromCart(product);
      } else {
        debugPrint('Error: ${product.name} not found in cart');
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> clearCart() async {
    if (_database == null || _userId == null) return;

    _isUpdating = true;
    try {
      await _database!.child('cart/$_userId').remove();
      _cartItems.clear();
      debugPrint('Cart cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    } finally {
      _isUpdating = false;
    }
  }
}