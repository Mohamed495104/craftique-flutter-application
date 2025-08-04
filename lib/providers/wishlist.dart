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

  Future<void> _initializeFirebase() async {
    try {
      print('Initializing Firebase in WishlistProvider...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
      ).ref();
      print('Firebase Database initialized successfully');

      _auth.authStateChanges().listen((User? user) {
        if (user != null && _database != null) {
          print('User logged in: ${user.uid}. Loading wishlist...');
          _loadWishlist(user.uid);
        } else {
          print(
              'No user logged in or database not initialized. Clearing wishlist.');
          _wishlist.clear();
          notifyListeners();
        }
      });
    } catch (e) {
      print('Error initializing Firebase in WishlistProvider: $e');
    }
  }

  List<Product> get wishlist => _wishlist;

  bool isInWishlist(Product product) {
    return _wishlist.any((p) => p.id == product.id);
  }

  Future<void> addToWishlist(Product product) async {
    if (!isInWishlist(product)) {
      print('Adding product to wishlist: ${product.name} (ID: ${product.id})');
      _wishlist.add(product);
      notifyListeners();
      await _saveWishlistToFirebase();
    }
  }

  Future<void> removeFromWishlist(Product product) async {
    print(
        'Removing product from wishlist: ${product.name} (ID: ${product.id})');
    _wishlist.removeWhere((p) => p.id == product.id);
    notifyListeners();
    await _saveWishlistToFirebase();
  }

  Future<void> _loadWishlist(String uid) async {
    if (_database == null) {
      print('Database not initialized');
      return;
    }
    try {
      print('Loading wishlist for user: $uid');
      final snapshot = await _database!.child('users/$uid/wishlist').once();
      final data = snapshot.snapshot.value;
      print('Wishlist data from Firebase: $data');

      if (data != null && data is List) {
        _wishlist.clear();
        _wishlist.addAll(
          data.where((item) => item != null).map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            print('Processing wishlist item: $map');
            return Product.fromMap(map, map['id'] ?? '');
          }).toList(),
        );
        print('Loaded ${_wishlist.length} items into wishlist');
        notifyListeners();
      } else {
        print('No wishlist data or invalid format');
        _wishlist.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading wishlist from Firebase: $e');
    }
  }

  Future<void> _saveWishlistToFirebase() async {
    final user = _auth.currentUser;
    if (user != null && _database != null) {
      try {
        final wishlistData =
            _wishlist.map((product) => product.toMap()).toList();
        print(
            'Saving wishlist to Firebase for user ${user.uid}: $wishlistData');
        await _database!.child('users/${user.uid}/wishlist').set(wishlistData);
        print('Wishlist saved successfully');
      } catch (e) {
        print('Error saving wishlist to Firebase: $e');
      }
    } else {
      print(
          'Cannot save wishlist: No user logged in or database not initialized');
    }
  }
}
