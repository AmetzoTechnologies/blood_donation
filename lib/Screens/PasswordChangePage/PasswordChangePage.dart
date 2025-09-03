import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/AuthController/AuthController.dart';
import '../../Theme/AppColors.dart';

class ChangePasswordPage extends StatelessWidget {
  ChangePasswordPage({super.key});

  final AuthController controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 🔹 Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock_reset, color: Colors.cyan, size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Update your password regularly to keep your account secure.",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 Old Password
              _buildPasswordField(
                controller: oldPassword,
                hint: "Old Password",
                icon: Icons.lock_outline,
                validator: (v) => v!.isEmpty ? "Enter old password" : null,
              ),

              const SizedBox(height: 16),

              /// 🔹 New Password
              _buildPasswordField(
                controller: newPassword,
                hint: "New Password",
                icon: Icons.lock,
                validator: (v) => v!.isEmpty ? "Enter new password" : null,
              ),

              const SizedBox(height: 16),

              /// 🔹 Confirm Password
              _buildPasswordField(
                controller: confirmPassword,
                hint: "Confirm New Password",
                icon: Icons.lock_person,
                validator: (v) =>
                v != newPassword.text ? "Passwords do not match" : null,
              ),

              const SizedBox(height: 30),

              /// 🔹 Update Button
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: controller.isLoading.value
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.cyan,
                  ),
                )
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await controller.changePassword(
                        oldPassword.text,
                        newPassword.text,
                      );
                      Get.back();
                    }
                  },
                  child: const Text(
                    "Update Password",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Custom Password Field Builder
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
