import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_group_project/models/product.dart';
import 'package:flutter_group_project/screens/home_screen.dart';
import 'package:flutter_group_project/screens/product_details_screen.dart';
import 'package:flutter_group_project/screens/splash_screen.dart';
import 'package:flutter_group_project/services/firebase_options.dart';
import 'package:flutter_group_project/utils/constants.dart';

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

  runApp(const CraftiqueApp());
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

          case '/product-details':
            final args = settings.arguments;
            if (args is Product) {
              return MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: args),
              );
            } else {
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            }

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
