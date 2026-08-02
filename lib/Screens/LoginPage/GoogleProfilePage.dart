import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Controller/AuthController/AuthController.dart';
import '../../GlobalWidgets/profile_upload_fields.dart';

class GoogleProfilePage extends StatefulWidget {
  const GoogleProfilePage({super.key});

  @override
  State<GoogleProfilePage> createState() => _GoogleProfilePageState();
}

class _GoogleProfilePageState extends State<GoogleProfilePage> {
  final AuthController controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _genderKey = GlobalKey();

  String? _genderError;
  String? _bloodGroupError;

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      setState(() {
        if (isDob) {
          controller.googleDateOfBirth.value = picked;
        } else {
          controller.googleLastDonationDate.value = picked;
        }
      });
    }
  }

  void _showMissingDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Missing details"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToGender() {
    final genderContext = _genderKey.currentContext;
    if (genderContext != null) {
      Scrollable.ensureVisible(
        genderContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _onSavePressed() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final genderMissing = controller.googleGender.value.trim().isEmpty;
    final bloodMissing = controller.googleBloodGroup.value.trim().isEmpty;

    setState(() {
      _genderError = genderMissing ? "Please select a gender" : null;
      _bloodGroupError = bloodMissing ? "Please select a blood group" : null;
    });

    if (genderMissing || bloodMissing || !formValid) {
      if (genderMissing) {
        _scrollToGender();
        _showMissingDialog("Please select a gender to continue.");
      } else if (bloodMissing) {
        _showMissingDialog("Please select a blood group to continue.");
      } else {
        _showMissingDialog("Please fill all required fields.");
      }
      return;
    }

    controller.completeGoogleProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          "Complete Profile",
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
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primaryColor,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 62,
                      width: 62,
                      child: Icon(
                        Icons.water_drop,
                        color: AppColors.whiteColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Donor profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Add the details donors and receivers need.",
                            style: TextStyle(
                              color: AppColors.backgroundColor,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _GlassPanel(
                title: "Personal",
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    _TextInput(
                      label: "Name",
                      icon: Icons.person_outline,
                      controller: controller.googleName,
                      validator: (value) =>
                          _required(value, "Name is required"),
                    ),
                    const SizedBox(height: 12),
                    _DateInput(
                      label: "Date of Birth",
                      icon: Icons.calendar_today_outlined,
                      date: controller.googleDateOfBirth,
                      onTap: () => _pickDate(context, true),
                      validator: () =>
                          controller.googleDateOfBirth.value == null
                          ? "Date of birth is required"
                          : null,
                    ),
                    const SizedBox(height: 12),
                    KeyedSubtree(
                      key: _genderKey,
                      child: _ChoiceRow(
                        label: "Gender",
                        values: _genders,
                        selected: controller.googleGender,
                        showLabel: true,
                        errorText: _genderError,
                        onSelected: () {
                          setState(() => _genderError = null);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _GlassPanel(
                title: "Uploads",
                icon: Icons.cloud_upload_outlined,
                child: Column(
                  children: [
                    ProfilePhotoPicker(controller: controller),
                    const SizedBox(height: 12),
                    ProofDocumentPicker(
                      controller: controller,
                      requireProof: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _GlassPanel(
                title: "Contact",
                icon: Icons.call_outlined,
                child: Column(
                  children: [
                    _TextInput(
                      label: "Phone",
                      icon: Icons.phone_outlined,
                      controller: controller.googlePhone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final message = _required(
                          value,
                          "Phone number is required",
                        );
                        if (message != null) {
                          return message;
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value!.trim())) {
                          return "Enter a valid 10-digit phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _TextInput(
                      label: "Address",
                      icon: Icons.home_outlined,
                      controller: controller.googleAddress,
                      validator: (value) {
                        final message = _required(value, "Address is required");
                        if (message != null) {
                          return message;
                        }
                        if (value!.trim().length < 5) {
                          return "Enter a valid address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _TextInput(
                      label: "Place",
                      icon: Icons.location_on_outlined,
                      controller: controller.googlePlace,
                      validator: (value) {
                        final message = _required(value, "Place is required");
                        if (message != null) {
                          return message;
                        }
                        if (value!.trim().length < 3) {
                          return "Enter a valid place";
                        }
                        return null;
                      },
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
                      errorText: _bloodGroupError,
                      onSelected: () {
                        setState(() => _bloodGroupError = null);
                      },
                    ),
                    const SizedBox(height: 18),
                    _DonorSwitch(controller: controller),
                    const SizedBox(height: 12),
                    _DateInput(
                      label: "Last Donation Date",
                      icon: Icons.event_available_outlined,
                      date: controller.googleLastDonationDate,
                      onTap: () => _pickDate(context, false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Obx(
                () =>
                    controller.isGoogleProfileLoading.value ||
                        controller.isMediaUploadLoading.value
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
                        onPressed: _onSavePressed,
                        child: const Text(
                          "Save Profile",
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

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w800,
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
              _SectionTitle(title),
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
    this.keyboardType,
    this.validator,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    this.showLabel = false,
    this.errorText,
    this.onSelected,
  });

  final String label;
  final List<String> values;
  final RxString selected;
  final bool showLabel;
  final String? errorText;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              color: hasError ? Colors.redAccent : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
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
                      onSelected?.call();
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
                          color: hasError && !isSelected
                              ? Colors.redAccent
                              : isSelected
                              ? AppColors.primaryColor
                              : Colors.white,
                          width: hasError && !isSelected ? 1.5 : 1,
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
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _BloodGroupPicker extends StatelessWidget {
  const _BloodGroupPicker({
    required this.bloodGroups,
    required this.selected,
    this.errorText,
    this.onSelected,
  });

  final List<String> bloodGroups;
  final RxString selected;
  final String? errorText;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Blood Group",
          style: TextStyle(
            color: hasError ? Colors.redAccent : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
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
                  onSelected?.call();
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
                      color: hasError && !isSelected
                          ? Colors.redAccent
                          : isSelected
                          ? AppColors.primaryColor
                          : Colors.white,
                      width: hasError && !isSelected ? 1.5 : 1,
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
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _DonorSwitch extends StatelessWidget {
  const _DonorSwitch({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Available as donor",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            Switch(
              value: controller.googleIsDonor.value,
              activeColor: AppColors.primaryColor,
              onChanged: (value) => controller.googleIsDonor.value = value,
            ),
          ],
        ),
      ),
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
