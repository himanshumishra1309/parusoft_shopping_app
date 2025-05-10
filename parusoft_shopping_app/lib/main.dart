import 'package:flutter/material.dart';
import 'package:parusoft_shopping_app/views/HomePage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Shopping App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: const MyHomePage(),
    debugShowCheckedModeBanner: false,
  ));
}
