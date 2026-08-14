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
  final PageController _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();

  int _currentStep = 0;
  static const int _totalSteps = 3;

  String? _dobError;
  String? _genderError;
  String? _proofError;
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
    _pageController.dispose();
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
          _dobError = null;
        } else {
          controller.googleLastDonationDate.value = picked;
        }
      });
    }
  }

  void _onNextOrSubmitPressed() {
    if (_currentStep == 0) {
      final formValid = _step1FormKey.currentState?.validate() ?? false;
      final dobMissing = controller.googleDateOfBirth.value == null;
      final genderMissing = controller.googleGender.value.trim().isEmpty;

      setState(() {
        _dobError = dobMissing ? "Please select your date of birth" : null;
        _genderError = genderMissing ? "Please select a gender" : null;
      });

      if (formValid && !dobMissing && !genderMissing) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      final hasFront = controller.proofFrontFile.value != null;
      final hasBack = controller.proofBackFile.value != null;

      setState(() {
        _proofError = (!hasFront || !hasBack)
            ? "Please upload both ID proof front and back"
            : null;
      });

      if (hasFront && hasBack) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 2) {
      final bloodMissing = controller.googleBloodGroup.value.trim().isEmpty;

      setState(() {
        _bloodGroupError = bloodMissing ? "Please select a blood group" : null;
      });

      if (!bloodMissing) {
        controller.completeGoogleProfile();
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
        child: Column(
          children: [
            _buildStepProgressHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1Personal(),
                  _buildStep2Uploads(),
                  _buildStep3Donation(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressHeader() {
    final stepLabels = ["Personal", "Uploads", "Donation"];

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                final isPassed = stepBefore < _currentStep;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isDone = stepIndex < _currentStep;
              final isCurrent = stepIndex == _currentStep;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isCurrent
                      ? AppColors.primaryColor
                      : Colors.white,
                  border: Border.all(
                    color: isDone || isCurrent
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : Text(
                          "${stepIndex + 1}",
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isDone = index < _currentStep;
              final isCurrent = index == _currentStep;
              return SizedBox(
                width: 68,
                child: Text(
                  stepLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent || isDone
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isCurrent
                        ? AppColors.primaryColor
                        : isDone
                            ? Colors.black87
                            : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildStep1Personal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          children: [
            _GlassPanel(
              title: "Personal Information",
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _TextInput(
                    label: "Name",
                    icon: Icons.person_outline,
                    controller: controller.googleName,
                    validator: (value) => _required(value, "Name is required"),
                  ),
                  const SizedBox(height: 12),
                  _DateInput(
                    label: "Date of Birth",
                    icon: Icons.calendar_today_outlined,
                    date: controller.googleDateOfBirth,
                    isDob: true,
                    onTap: () => _pickDate(context, true),
                    errorText: _dobError,
                  ),
                  const SizedBox(height: 12),
                  _ChoiceRow(
                    label: "Gender",
                    values: _genders,
                    selected: controller.googleGender,
                    showLabel: true,
                    errorText: _genderError,
                    onSelected: () {
                      setState(() => _genderError = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _GlassPanel(
              title: "Contact & Location",
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
                      if (message != null) return message;
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
                      if (message != null) return message;
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
                      if (message != null) return message;
                      if (value!.trim().length < 3) {
                        return "Enter a valid place";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Uploads() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          _GlassPanel(
            title: "Profile Photo & Identification",
            icon: Icons.cloud_upload_outlined,
            child: Column(
              children: [
                ProfilePhotoPicker(controller: controller),
                const SizedBox(height: 14),
                ProofDocumentPicker(
                  controller: controller,
                  requireProof: true,
                ),
                if (_proofError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _proofError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Donation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          _GlassPanel(
            title: "Blood Group & Donation Status",
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
                  label: "Last Donation Date (Optional)",
                  icon: Icons.event_available_outlined,
                  date: controller.googleLastDonationDate,
                  onTap: () => _pickDate(context, false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 18),
                      SizedBox(width: 6),
                      Text("Back", style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: Obx(
                () {
                  final isBusy = controller.isGoogleProfileLoading.value ||
                      controller.isMediaUploadLoading.value;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isBusy ? null : _onNextOrSubmitPressed,
                    child: isBusy
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStep == _totalSteps - 1
                                    ? "Complete Profile ✓"
                                    : "Continue →",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
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
                  color: AppColors.primaryColor.withValues(alpha: .12),
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
              activeThumbColor: AppColors.primaryColor,
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
    this.isDob = false,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final Rxn<DateTime> date;
  final VoidCallback onTap;
  final bool isDob;
  final String? errorText;

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Obx(() {
      final selectedDate = date.value;
      final age = isDob ? _calculateAge(selectedDate) : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: _inputDecoration(label, icon).copyWith(
                errorText: hasError ? errorText : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate == null
                        ? label
                        : DateFormat("dd/MM/yyyy").format(selectedDate),
                    style: TextStyle(
                      color: selectedDate == null
                          ? Colors.black54
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  if (isDob && age != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$age yrs old",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    });
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
    color: Colors.white.withValues(alpha: .92),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.white),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .08),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: AppColors.primaryColor.withValues(alpha: .06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
