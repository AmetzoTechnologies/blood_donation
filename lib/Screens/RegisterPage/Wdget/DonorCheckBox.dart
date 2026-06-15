import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Controller/RegisterController/RegisterController.dart';
import '../../../Theme/AppColors.dart';

class DonorCheckbox extends StatelessWidget {
  DonorCheckbox({super.key});

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
            activeColor: AppColors.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          const Text("I want to be a donor", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
