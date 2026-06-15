import 'package:flutter/material.dart';

import '../../../Theme/AppColors.dart';
import 'package:get/get.dart';

class CustomDropdownField extends StatelessWidget {
  final String hintText;
  final List<String> items;
  final RxString selectedValue;
  final String? Function(String?)? validator;

  const CustomDropdownField({
    super.key,
    required this.hintText,
    required this.items,
    required this.selectedValue,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DropdownButtonFormField<String>(
        value: selectedValue.value.isEmpty ? null : selectedValue.value,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person, color: AppColors.primaryColor),
          hintText: hintText,
          filled: true,
          fillColor: AppColors.textFieldColor,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            selectedValue.value = value;
          }
        },
        validator: validator,
      ),
    );
  }
}
