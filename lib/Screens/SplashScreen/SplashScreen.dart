import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/AuthController/AuthController.dart';
import '../../Theme/AppColors.dart';

class SplashPage extends StatelessWidget {
  SplashPage({super.key});

  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: AppColors.whiteColor,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/bloodmate_logo.png",
                  width: 190,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                CircularProgressIndicator(color: AppColors.primaryColor),
              ],
            ),
          ),
        );
      } else {
        return SizedBox(); // Empty because navigation already handled
      }
    });
  }
}
