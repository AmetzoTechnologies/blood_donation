import 'package:blood_donation/Screens/LoginPage/PhoneLoginPage.dart';
import 'package:blood_donation/Screens/SplashScreen/SplashScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(home: SplashPage());
  }
}
