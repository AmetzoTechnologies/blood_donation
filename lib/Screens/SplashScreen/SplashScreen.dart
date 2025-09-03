import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/AuthController/AuthController.dart';

class SplashPage extends StatelessWidget {
  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      } else {
        return SizedBox(); // Empty because navigation already handled
      }
    });
  }
}
