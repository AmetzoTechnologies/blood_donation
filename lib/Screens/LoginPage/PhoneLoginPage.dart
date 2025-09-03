import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Controller/AuthController/AuthController.dart';
import '../../Theme/AppColors.dart';
import '../RegisterPage/RegisterPage.dart';
import 'PasswordPage.dart';
import 'SetPasswordPage.dart';

class PhoneLoginPage extends StatelessWidget {
  PhoneLoginPage({super.key});
  final AuthController controller = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, size: 100, color: Colors.cyan),
              const SizedBox(height: 20),
              Text(
                "Dare To Donate",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: TextFormField(
                  controller: controller.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter phone number" : null,
                  decoration: InputDecoration(
                    hintText: "Mobile number",
                    prefixIcon: Icon(
                      Icons.phone_android,
                      color: AppColors.primaryColor,
                    ),
                    filled: true,
                    fillColor: AppColors.textFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Obx(
                () => controller.isLoading.value
                    ? CircularProgressIndicator(color: AppColors.primaryColor)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "NEXT",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            bool? hasPassword = await controller
                                .checkUserHasPassword(controller.phone.text);
                            if(hasPassword==null){
                              Get.to(RegisterPage());
                            }else{
                              if (hasPassword) {
                                Get.to(() => PasswordPage());
                              } else {
                                Get.to(() => SetPasswordPage());
                              }
                            }

                          }
                        },
                      ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account? "),
                  GestureDetector(
                    onTap: () {
                      Get.to(RegisterPage());
                    },
                    child: Text(
                      "Register Now.",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
