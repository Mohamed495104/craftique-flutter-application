import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firebase_options.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Product> _wishlist = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference? _database;

  WishlistProvider() {
    _initializeFirebase();
  }

  List<Product> get wishlist => List.unmodifiable(_wishlist);

  bool isInWishlist(Product product) {
    return _wishlist.any((p) => p.id == product.id);
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      ).ref();

      _auth.authStateChanges().listen((User? user) {
        if (user != null && _database != null) {
          _loadWishlist(user.uid);
        } else {
          _wishlist.clear();
          notifyListeners();
        }
      });
    } catch (e) {
      print('Error initializing WishlistProvider: $e');
    }
  }

  Future<void> addToWishlist(Product product) async {
    if (!isInWishlist(product)) {
      _wishlist.add(product);
      notifyListeners();
      await _saveWishlistToFirebase();
    }
  }

  Future<void> removeFromWishlist(Product product) async {
    _wishlist.removeWhere((p) => p.id == product.id);
    notifyListeners();
    await _saveWishlistToFirebase();
  }

  Future<void> _loadWishlist(String uid) async {
    if (_database == null) return;

    try {
      final snapshot = await _database!.child('users/$uid/wishlist').once();
      final data = snapshot.snapshot.value;

      if (data != null && data is List) {
        _wishlist.clear();
        _wishlist.addAll(
          data.where((item) => item != null).map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return Product.fromMap(map, map['id'] ?? '');
          }),
        );
        notifyListeners();
      } else {
        _wishlist.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> _saveWishlistToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || _database == null) return;

    try {
      final wishlistData = _wishlist.map((product) => product.toMap()).toList();
      await _database!.child('users/${user.uid}/wishlist').set(wishlistData);
    } catch (e) {
      print('Error saving wishlist: $e');
    }
  }
}
