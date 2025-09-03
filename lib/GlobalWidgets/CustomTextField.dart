import 'package:flutter/material.dart';
import '../Theme/AppColors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Function(String)? onSubmitted;// 👈 add validator

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    required this.controller,
    this.validator,
    this.onSubmitted// 👈 optional
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onFieldSubmitted: onSubmitted,
      // 👈 change to TextFormField
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: AppColors.primaryColor),
        hintText: hintText,
        filled: true,
        fillColor: AppColors.textFieldColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(5),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
