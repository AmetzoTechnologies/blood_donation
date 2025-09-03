import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controller/RegisterController/RegisterController.dart';

class DonorCheckbox extends StatelessWidget {
  final RegisterController controller = Get.put(RegisterController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: controller.isDonor.value,
            onChanged: (val) => controller.isDonor.value = val!,
            activeColor: Colors.cyan,
            materialTapTargetSize: MaterialTapTargetSize
                .shrinkWrap, // 👈 reduces extra tap padding
          ),
          const SizedBox(width: 8), // 👈 space between box & text
          const Text(
            "I want to be a donor",
            style: TextStyle(fontSize: 16), // 👈 make text aligned nicely
          ),
        ],
      ),
    );
  }
}
