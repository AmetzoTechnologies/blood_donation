import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/NavController/BottomNavController.dart';
import 'HomePage/HomePage.dart';

class NavigationPage extends StatelessWidget {
  NavigationPage({super.key});

  final BottomNavController navController = Get.put(BottomNavController());

  final iconList = [Icons.home, Icons.person];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => navController.pages[navController.selectedIndex.value]),
      // Floating Center Icon
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: Colors.cyan,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Obx(
        () => AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: navController.selectedIndex.value,
          gapLocation: GapLocation.center, // creates space for FAB
          notchSmoothness: NotchSmoothness.softEdge,
          backgroundColor: Colors.white,
          activeColor: Colors.cyan,
          inactiveColor: Colors.grey,
          onTap: (index) => navController.changePage(index),
        ),
      ),
    );
  }
}
