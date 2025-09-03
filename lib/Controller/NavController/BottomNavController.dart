import 'package:blood_donation/Screens/ProfilePage/ProfilePage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../Screens/HomePage/HomePage.dart';

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;

  final List<Widget> pages = [
    HomePage(),
    ProfilePage()
  ];
  void changePage(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }
}
