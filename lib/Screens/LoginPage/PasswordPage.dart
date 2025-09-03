import 'package:flutter/material.dart';

import '../../Controller/AuthController/AuthController.dart';
import 'package:get/get.dart';

import '../../Theme/AppColors.dart';

class PasswordPage extends StatelessWidget {
  PasswordPage({super.key});
  final AuthController controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  RxBool isObscure = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(title: const Text("Enter Password"),backgroundColor: AppColors.backgroundColor,centerTitle: true,iconTheme: IconThemeData(color: AppColors.primaryColor),),
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

              Obx(() => TextFormField(
                controller: controller.password,
                obscureText: isObscure.value,
                validator: (v) =>
                v == null || v.isEmpty ? "Enter password" : null,
                decoration: InputDecoration(
                  hintText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(isObscure.value
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                    isObscure.value = !isObscure.value,
                  ),
                  prefixIcon: Icon(Icons.lock,
                      color: AppColors.primaryColor),
                  filled: true,
                  fillColor: AppColors.textFieldColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none),
                ),
              )),
              const SizedBox(height: 30),
              Obx(() => controller.isLoading.value
                  ? CircularProgressIndicator(color: AppColors.primaryColor)
                  : ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await controller.loginUser();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("LOG IN",
                    style: TextStyle(color: Colors.white)),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
