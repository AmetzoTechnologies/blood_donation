import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/AuthController/AuthController.dart';
import '../../Theme/AppColors.dart';
import 'PhoneLoginPage.dart';
class SetPasswordPage extends StatelessWidget {
  SetPasswordPage({super.key});
  final AuthController controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final confirmPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(title: const Text("Set Password"),backgroundColor: AppColors.backgroundColor,centerTitle: true,iconTheme: IconThemeData(color: AppColors.primaryColor),),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, size: 100, color: Colors.cyan),
              const SizedBox(height: 20),
              Text("Dare To Donate",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor)),
              const SizedBox(height: 40),

              Column(
                children: [
                  TextFormField(
                    controller: controller.password,
                    validator: (v) =>
                    v == null || v.isEmpty ? "Enter new password" : null,
                    decoration: InputDecoration(
                      hintText: "New Password",
                      prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
                      filled: true,
                      fillColor: AppColors.textFieldColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmPassword,
                    validator: (v) => v != controller.password.text
                        ? "Passwords do not match"
                        : null,
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
                      prefixIcon: Icon(Icons.lock_outline,
                          color: AppColors.primaryColor),
                      filled: true,
                      fillColor: AppColors.textFieldColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Obx(() => controller.isLoading.value
                      ? CircularProgressIndicator(color: AppColors.primaryColor)
                      : ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await controller.setPassword();
                      }
                    },
                    child: const Text("SET PASSWORD",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
