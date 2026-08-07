import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/AuthController/AuthController.dart';
import '../../Theme/AppColors.dart';

class SplashPage extends StatelessWidget {
  SplashPage({super.key});

  final AuthController controller = Get.put(AuthController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: AppColors.whiteColor,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/donormate_logo.png",
                        width: 190,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 28),
                      CircularProgressIndicator(color: AppColors.primaryColor),
                    ],
                  ),
                ),
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: _PoweredByLabel(),
                ),
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

class _PoweredByLabel extends StatelessWidget {
  const _PoweredByLabel();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: "Powered by ",
        style: TextStyle(
          color: AppColors.mutedTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: .2,
        ),
        children: [
          TextSpan(
            text: "MYL MANHAPPATTA",
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
