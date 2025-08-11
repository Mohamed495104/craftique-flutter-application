import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  DatabaseReference? _rootRef;
  StreamSubscription<DatabaseEvent>? _cartSub;

  String? _userId;
  bool _squelchRemote = false; // prevents remote re-hydration during local ops

  CartProvider() {
    _initialize();
  }

  // ---------------- Public API ----------------

  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  double get totalPrice => _cartItems.fold(
        0.0,
        (sum, item) => sum + (item['product'].price * (item['quantity'] ?? 1)),
      );

  /// Adds product or increments quantity if it already exists
  Future<void> addToCart(Product product,
      {int quantity = 1, String? imageUrl}) async {
    if (_rootRef == null || _userId == null) return;

    _squelchRemote = true;
    try {
      final userCartRef = _rootRef!.child('cart/$_userId');

      final snapshot = await userCartRef
          .orderByChild('productId')
          .equalTo(product.id)
          .once();
      final cartData = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (cartData != null && cartData.isNotEmpty) {
        final String existingKey = cartData.keys.first.toString();
        final existingItem = Map<String, dynamic>.from(cartData[existingKey]);

        final newQuantity = (existingItem['quantity'] ?? 0) + quantity;

        // update local
        final localIdx = _cartItems
            .indexWhere((it) => (it['product'] as Product).id == product.id);
        if (localIdx != -1) {
          _cartItems[localIdx]['quantity'] = newQuantity;
        } else {
          _cartItems.add({
            'product': product,
            'quantity': newQuantity,
            'firebaseKey': existingKey,
          });
        }

        // update remote
        await userCartRef.child(existingKey).update({
          'quantity': newQuantity,
          'totalPrice': product.price * newQuantity,
          'timestamp': ServerValue.timestamp,
        });
        if (kDebugMode) {
          print('Updated ${product.name} in cart, new quantity: $newQuantity');
        }
      } else {
        final newRef = userCartRef.push();

        // update local immediately
        _cartItems.add({
          'product': product,
          'quantity': quantity,
          'firebaseKey': newRef.key,
        });

        // write remote
        await newRef.set({
          'categoryName': product.category,
          'imageUrl': imageUrl ?? '',
          'price': product.price,
          'productId': product.id,
          'productName': product.name,
          'quantity': quantity,
          'timestamp': ServerValue.timestamp,
          'totalPrice': product.price * quantity,
        });
        if (kDebugMode) {
          print('Added ${product.name} to cart, quantity: $quantity');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    } finally {
      _squelchRemote = false;
    }
  }

  /// Decrements to 0 = remove. Here we always remove the line item.
  Future<void> removeFromCart(Product product) async {
    if (_rootRef == null || _userId == null) return;

    _squelchRemote = true;
    try {
      final idx = _cartItems
          .indexWhere((it) => (it['product'] as Product).id == product.id);
      if (idx == -1) {
        debugPrint('removeFromCart: ${product.name} not found');
        return;
      }

      final String? firebaseKey = _cartItems[idx]['firebaseKey'] as String?;
      if (firebaseKey == null) {
        debugPrint('removeFromCart: missing firebaseKey for ${product.id}');
        _cartItems.removeAt(idx);
        notifyListeners();
        return;
      }

      await _rootRef!.child('cart/$_userId/$firebaseKey').remove();
      _cartItems.removeAt(idx);

      if (kDebugMode) {
        print('Removed ${product.name} from cart, left: ${_cartItems.length}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    } finally {
      _squelchRemote = false;
    }
  }

  Future<void> updateQuantity(Product product, int quantity) async {
    if (_rootRef == null || _userId == null) return;

    _squelchRemote = true;
    try {
      final idx = _cartItems
          .indexWhere((it) => (it['product'] as Product).id == product.id);

      if (idx != -1 && quantity > 0) {
        _cartItems[idx]['quantity'] = quantity;
        final String? key = _cartItems[idx]['firebaseKey'] as String?;
        if (key != null) {
          await _updateCartItemInFirebase(key, product, quantity);
        }
        notifyListeners();
      } else if (quantity <= 0) {
        await removeFromCart(product);
      } else {
        debugPrint('updateQuantity: ${product.name} not found');
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    } finally {
      _squelchRemote = false;
    }
  }

  /// Clear cart after successful order
  Future<void> clearCart() async {
    if (_rootRef == null || _userId == null) return;

    _squelchRemote = true;
    try {
      await _rootRef!.child('cart/$_userId').remove();
      _cartItems.clear();
      if (kDebugMode) print('Cart cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    } finally {
      _squelchRemote = false;
    }
  }

  // ---------------- Internal ----------------

  Future<void> _initialize() async {
    try {
      // Use the default Firebase app (must be initialized before Provider is created)
      final app = FirebaseDatabase
          .instance.app; // requires Firebase.initializeApp done once
      _rootRef = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      ).ref();

      // pick current user id; keep it flexible if not logged in yet
      _setUser(FirebaseAuth.instance.currentUser?.uid);

      // Also listen for auth changes (handles logout/login seamlessly)
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _setUser(user?.uid);
      });
    } catch (e) {
      debugPrint('CartProvider init error: $e');
    }
  }

  void _setUser(String? uid) {
    if (_userId == uid && _cartSub != null) return;

    _userId = uid;

    // re-subscribe to this user's cart
    _cartSub?.cancel();
    _cartSub = null;

    if (_rootRef == null || _userId == null) {
      _cartItems.clear();
      notifyListeners();
      return;
    }

    final userCartRef = _rootRef!.child('cart/$_userId');

    _cartSub = userCartRef.onValue.listen((event) {
      if (_squelchRemote) {
        if (kDebugMode) print('onValue ignored (local write in progress)');
        return;
      }

      _cartItems.clear();

      final raw = event.snapshot.value;
      if (raw is Map) {
        raw.forEach((key, value) {
          final item = Map<String, dynamic>.from(value as Map);
          final product = Product(
            id: item['productId']?.toString() ?? '',
            name: item['productName'] ?? '',
            description: '', // not stored remotely
            price: (item['price'] ?? 0).toDouble(),
            category: item['categoryName'] ?? '',
            rating: 0.0,
          );
          _cartItems.add({
            'product': product,
            'quantity': (item['quantity'] ?? 1) as int,
            'firebaseKey': key.toString(),
          });
        });
      }

      if (kDebugMode) {
        print('Realtime: fetched ${_cartItems.length} items for user $_userId');
      }
      notifyListeners();
    });
  }

  Future<void> _updateCartItemInFirebase(
      String firebaseKey, Product product, int quantity) async {
    if (_rootRef == null || _userId == null) return;
    await _rootRef!.child('cart/$_userId/$firebaseKey').update({
      'quantity': quantity,
      'totalPrice': product.price * quantity,
      'timestamp': ServerValue.timestamp,
    });
    if (kDebugMode) {
      print('Firebase updated: ${product.name}, qty: $quantity');
    }
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    super.dispose();
  }
}
