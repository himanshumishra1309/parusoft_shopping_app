import 'package:flutter/material.dart';
import 'package:parusoft_shopping_app/views/Cart_view.dart';
import 'package:parusoft_shopping_app/views/HomePage.dart';
import 'package:parusoft_shopping_app/constants/routes.dart';
import 'package:parusoft_shopping_app/views/ProductDetailPage.dart';
import 'package:parusoft_shopping_app/views/SignIn_SignUp_View.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParusoftShoppingApp());
}

class ParusoftShoppingApp extends StatelessWidget {
  const ParusoftShoppingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parusoft Shopping',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF3F51B5),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          primary: const Color(0xFF3F51B5),
          secondary: const Color(0xFF303F9F),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3F51B5),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF3F51B5),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          primary: const Color(0xFF3F51B5),
          secondary: const Color(0xFF303F9F),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3F51B5),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
        ),
      ),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      // Simply set the home to the sign-in view
      home: const SignInSignUpView(),
      onGenerateRoute: (settings) {
        if (settings.name == productDetailPageRoute) {
          // Extract the product from the arguments
          final args = settings.arguments as Map<String, dynamic>;
          final product = args['product'];
          
          // Return the ProductDetailPage with the correct product
          return MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          );
        }
        
        // For other routes, use the routes map
        return null;
      },
      routes: {
        homePageRoute: (context) => const MyHomePage(),
        cartViewPageRoute: (context) => const CartView(),
        signInSignUpRoute: (context) => const SignInSignUpView(),
      },
    );
  }
}