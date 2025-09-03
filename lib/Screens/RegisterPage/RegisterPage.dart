import 'package:blood_donation/Screens/RegisterPage/Wdget/DonorCheckBox.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Controller/RegisterController/RegisterController.dart';
import '../../GlobalWidgets/CustomTextField.dart';
import '../../Theme/AppColors.dart';
import 'Wdget/DropdownTextFeld.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final RegisterController controller = Get.put(RegisterController());

  Future<void> _pickDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isDob) {
        controller.dob.value = picked;
      } else {
        controller.lastDonatedDate.value = picked;
      }
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Icon(Icons.water_drop, size: 100, color: Colors.cyan),
                      const SizedBox(height: 10),
                      Text(
                        "Dare To Donate",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Input fields
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      CustomTextField(
                        hintText: "UserName",
                        prefixIcon: Icons.person,
                        controller: controller.usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Username is required";
                          }
                          return null;
                        },
                      ),
                      // CustomTextField(
                      //   hintText: 'Email',
                      //   prefixIcon: Icons.email,
                      //   controller: controller.emailController,
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return "Email is required";
                      //     }
                      //     if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      //       return "Enter a valid email";
                      //     }
                      //     return null;
                      //   },
                      // ),
                      CustomTextField(
                        hintText: "Password",
                        prefixIcon: Icons.password,
                        controller: controller.passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password cannot be empty";
                          } else if (value.length < 6) {
                            return "Minimum 6 letter required";
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        hintText: "Phone",
                        prefixIcon: Icons.phone,
                        controller: controller.phoneController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Phone number is required";
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return "Enter a valid 10-digit phone number";
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        hintText: "Blood Groups",
                        prefixIcon: Icons.bloodtype,
                        controller: controller.bloodGroupController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Blood group is required";
                          }
                          // ✅ Accept only standard blood groups
                          const validGroups = [
                            "A+",
                            "A-",
                            "B+",
                            "B-",
                            "AB+",
                            "AB-",
                            "O+",
                            "O-",
                          ];
                          if (!validGroups.contains(
                            value.toUpperCase().trim(),
                          )) {
                            return "Enter a valid blood group";
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        hintText: "Location",
                        prefixIcon: Icons.location_on_outlined,
                        controller: controller.locationController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Location is required";
                          }
                          if (value.length < 3) {
                            return "Enter a valid location";
                          }
                          return null;
                        },
                      ),
                      CustomDropdownField(
                        hintText: "Select Gender",
                        items: ["Male", "Female", "Other"],
                        selectedValue: controller.gender,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a gender";
                          }
                          return null;
                        },
                      ),
                      // DOB (required)
                      Obx(
                        () => GestureDetector(
                          onTap: () => _pickDate(context, true),
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: controller.dob.value == null
                                    ? "Date of Birth *"
                                    : DateFormat(
                                        "dd/MM/yyyy",
                                      ).format(controller.dob.value!),
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primaryColor,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ), // 👈 Center align
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  // 👈 use OutlineInputBorder instead of Underline
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Last Donated Date (optional)
                      Obx(
                        () => GestureDetector(
                          onTap: () => _pickDate(context, false),
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText:
                                    controller.lastDonatedDate.value == null
                                    ? "Last Donated Date (Optional)"
                                    : DateFormat("dd/MM/yyyy").format(
                                        controller.lastDonatedDate.value!,
                                      ),
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primaryColor,
                                ),
                                filled: true,
                                fillColor: AppColors.textFieldColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ), // 👈 Center align
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  // 👈 use OutlineInputBorder instead of Underline
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      DonorCheckbox(), // bind this with controller.isDonor
                      const SizedBox(height: 30),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Obx(
                          () => controller.isLoading.value
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      controller
                                          .register(); // proceed only if valid
                                    }
                                  },
                                  child: const Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: Text(
                          "Login Now.",
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
        ),
      ),
    );
  }
}
