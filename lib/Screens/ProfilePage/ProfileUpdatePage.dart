import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controller/AuthController/AuthController.dart';

class ProfileUpdatePage extends StatelessWidget {
  ProfileUpdatePage({super.key});

  final AuthController controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  static const List<String> _bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];

  static const List<String> _genders = ["Male", "Female", "Other"];

  Future<void> _pickDate(BuildContext context, bool isDob) async {
    final initialDate = isDob
        ? controller.googleDateOfBirth.value ?? DateTime(2000)
        : controller.googleLastDonationDate.value ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isDob) {
        controller.googleDateOfBirth.value = picked;
      } else {
        controller.googleLastDonationDate.value = picked;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _panelDecoration().copyWith(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(.16),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_note,
                        color: AppColors.primaryColor,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        "Keep your donor details accurate for faster matching.",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _GlassPanel(
                title: "Basic Details",
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    _TextInput(
                      label: "Name",
                      icon: Icons.person_outline,
                      controller: controller.googleName,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? "Name is required"
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _TextInput(
                      label: "Place",
                      icon: Icons.location_on_outlined,
                      controller: controller.googlePlace,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Place is required";
                        }
                        if (value.trim().length < 3) {
                          return "Enter a valid place";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _DateInput(
                      label: "Date of Birth",
                      icon: Icons.cake_outlined,
                      date: controller.googleDateOfBirth,
                      onTap: () => _pickDate(context, true),
                      validator: () =>
                          controller.googleDateOfBirth.value == null
                          ? "Date of birth is required"
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _ChoiceRow(
                      label: "Gender",
                      values: _genders,
                      selected: controller.googleGender,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _GlassPanel(
                title: "Donation",
                icon: Icons.bloodtype_outlined,
                child: Column(
                  children: [
                    _BloodGroupPicker(
                      bloodGroups: _bloodGroups,
                      selected: controller.googleBloodGroup,
                    ),
                    const SizedBox(height: 18),
                    // _DateInput(
                    //   label: "Last Donation Date",
                    //   icon: Icons.event_available_outlined,
                    //   date: controller.googleLastDonationDate,
                    //   onTap: () => _pickDate(context, false),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Obx(
                () => controller.isProfileUpdateLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              controller.googleBloodGroup.value.isNotEmpty &&
                              controller.googleGender.value.isNotEmpty) {
                            controller.updateProfile();
                          }
                        },
                        child: const Text(
                          "Update Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.icon,
    required this.controller,
    this.validator,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }
}

class _BloodGroupPicker extends StatelessWidget {
  const _BloodGroupPicker({required this.bloodGroups, required this.selected});

  final List<String> bloodGroups;
  final RxString selected;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) =>
          selected.value.isEmpty ? "Blood group is required" : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final selectedBloodGroup = selected.value;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bloodGroups.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final value = bloodGroups[index];
                  final isSelected = selectedBloodGroup == value;
                  return InkWell(
                    onTap: () {
                      selected.value = value;
                      field.didChange(value);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.textFieldColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.white,
                        ),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
  });

  final String label;
  final List<String> values;
  final RxString selected;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => selected.value.isEmpty ? "$label is required" : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Row(
                children: values.map((value) {
                  final isSelected = selected.value == value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: value == values.last ? 0 : 8,
                      ),
                      child: InkWell(
                        onTap: () {
                          selected.value = value;
                          field.didChange(value);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.white,
                            ),
                          ),
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
    required this.label,
    required this.icon,
    required this.date,
    required this.onTap,
    this.validator,
  });

  final String label;
  final IconData icon;
  final Rxn<DateTime> date;
  final VoidCallback onTap;
  final String? Function()? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: (_) => validator?.call(),
      builder: (field) {
        return Obx(() {
          final selectedDate = date.value;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: _inputDecoration(
                label,
                icon,
              ).copyWith(errorText: field.errorText),
              child: Text(
                selectedDate == null
                    ? label
                    : DateFormat("dd/MM/yyyy").format(selectedDate),
                style: TextStyle(
                  color: selectedDate == null ? Colors.black54 : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

InputDecoration _inputDecoration(String hintText, IconData icon) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: AppColors.primaryColor),
    hintText: hintText,
    filled: true,
    fillColor: AppColors.textFieldColor,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primaryColor, width: 1.4),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white.withOpacity(.92),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.white),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.08),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: AppColors.primaryColor.withOpacity(.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
