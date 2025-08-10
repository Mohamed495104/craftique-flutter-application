import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_group_project/providers/cart_provider.dart';
import 'package:flutter_group_project/providers/wishlist.dart';
import 'package:flutter_group_project/screens/auth_screen.dart';
import 'package:flutter_group_project/screens/cart_screen.dart';
import 'package:flutter_group_project/screens/home_screen.dart';
import 'package:flutter_group_project/screens/product_details_screen.dart';
import 'package:flutter_group_project/screens/splash_screen.dart';
import 'package:flutter_group_project/screens/wishlist_screen.dart';
import 'package:flutter_group_project/services/firebase_options.dart';
import 'package:flutter_group_project/utils/constants.dart';
import 'package:flutter_group_project/screens/checkout_screen.dart';
import 'package:flutter_group_project/screens/order_confirmation_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://flutter-group-project-3541f-default-rtdb.firebaseio.com',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const CraftiqueApp(),
    ),
  );
}

class CraftiqueApp extends StatelessWidget {
  const CraftiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Craftique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final routeName = settings.name;

        if (routeName == null || routeName == '/' || routeName == '') {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }

        switch (routeName) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/wishlist':
            return MaterialPageRoute(builder: (_) => const WishlistScreen());

          case '/auth':
            return MaterialPageRoute(builder: (_) => const AuthScreen());

          case '/product-details':
            return MaterialPageRoute(
                builder: (_) => const ProductDetailsScreen(),
                settings: settings);

          case '/cart':
            return MaterialPageRoute(builder: (_) => const CartScreen());

          case '/checkout':
            final args = settings.arguments as Map<String, dynamic>?;
            final total = args?['total'] as double? ?? 0.0;
            return MaterialPageRoute(
              builder: (_) => CheckoutScreen(totalAmount: total),
            );

          case '/order-confirmation':
            final args = settings.arguments as Map<String, dynamic>?;
            final totalAmount = args?['totalAmount'] as double? ?? 0.0;
            final paymentMethod = args?['paymentMethod'] as String? ?? 'N/A';
            return MaterialPageRoute(
              builder: (_) => OrderConfirmationScreen(
                totalAmount: totalAmount,
                paymentMethod: paymentMethod,
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Page not found")),
              ),
            );
        }
      },
    );
  }
}
