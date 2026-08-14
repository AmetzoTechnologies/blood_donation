import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Controller/AuthController/AuthController.dart';
import '../../Models/user_model/user.dart';
import 'ProfileUpdatePage.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final user = userModel?.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    controller.googleIsDonor.value = user.isDonor ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            user: user,
            onLogout: () => _showLogoutWarning(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
            child: Column(
              children: [
                _InfoTile(
                  title: "Place",
                  value: _value(user.place),
                  icon: Icons.location_on_outlined,
                ),
                _InfoTile(
                  title: "Blood Group",
                  value: _value(user.bloodGroup),
                  icon: Icons.bloodtype_outlined,
                ),
                _DonorAvailabilityTile(controller: controller),
                _InfoTile(
                  title: "Gender",
                  value: _formatGender(user.gender),
                  icon: Icons.person_outline,
                ),
                _InfoTile(
                  title: "Date of Birth",
                  value: _formatDate(user.dateOfBirth),
                  icon: Icons.cake_outlined,
                ),
                _InfoTile(
                  title: "Last Donation",
                  value: _formatDate(user.lastDonationDate),
                  icon: Icons.event_available_outlined,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.edit_outlined,
                  color: AppColors.primaryColor,
                  title: "Edit Profile",
                  onTap: () {
                    controller.prefillProfileUpdate();
                    Get.to(() => ProfileUpdatePage());
                  },
                ),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  color: Colors.green,
                  title: "Privacy Policy",
                  onTap: () async {
                    final uri = Uri.parse(privacyPolicyUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      Get.snackbar('Error', 'Could not open Privacy Policy');
                    }
                  },
                ),
                _ActionTile(
                  icon: Icons.logout,
                  color: Colors.red,
                  title: "Logout",
                  onTap: () => _showLogoutWarning(context),
                ),
                _ActionTile(
                  icon: Icons.delete_forever_outlined,
                  color: Colors.red.shade700,
                  title: "Delete Account",
                  onTap: () => _showDeleteAccountWarning(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _value(String? value) {
    return value == null || value.trim().isEmpty ? "-" : value;
  }

  String _formatGender(String? gender) {
    if (gender == null || gender.trim().isEmpty) return "-";
    final lower = gender.trim().toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return "$day/$month/$year";
  }

  void _showLogoutWarning(BuildContext context) {
    _showConfirmationDialog(
      context: context,
      title: "Logout?",
      message: "Are you sure you want to log out of your account?",
      confirmText: "Logout",
      icon: Icons.logout,
      iconColor: Colors.redAccent,
      iconBgColor: Colors.red.shade50,
      confirmButtonColor: Colors.redAccent,
      onConfirm: () => controller.logout(),
    );
  }

  void _showDeleteAccountWarning(BuildContext context) {
    _showConfirmationDialog(
      context: context,
      title: "Delete Account?",
      message:
          "Are you sure you want to delete your account? This action cannot be undone and will permanently remove your profile and donation records.",
      confirmText: "Delete",
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.redAccent,
      iconBgColor: Colors.red.shade50,
      confirmButtonColor: Colors.redAccent,
      onConfirm: () async {
        final uri = Uri.parse(deleteAccountUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          Get.snackbar('Error', 'Could not open Account Deletion page');
        }
      },
    );
  }
}

void _showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  required IconData icon,
  required Color iconColor,
  required Color iconBgColor,
  required Color confirmButtonColor,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textFieldColor,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmButtonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onConfirm();
                    },
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.onLogout});

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.26),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: onLogout,
              ),
            ),
            GestureDetector(
              onTap: () {
                final imgUrl = _profileImage(user.profilePic);
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.black,
                    insetPadding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          title: Text(
                            user.name ?? "Profile Photo",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        Flexible(
                          child: InteractiveViewer(
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.network(
                    _profileImage(user.profilePic),
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 54,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user.name ?? "User",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.phone ?? "",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Blood Group: ${user.bloodGroup ?? '-'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _profileImage(String? profilePic) {
    const fallback =
        "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png";
    if (profilePic == null || profilePic.isEmpty) {
      return fallback;
    }
    if (profilePic.startsWith("http://") || profilePic.startsWith("https://")) {
      return profilePic;
    }
    return "$baseUrl$profilePic";
  }
}

class _DonorAvailabilityTile extends StatelessWidget {
  const _DonorAvailabilityTile({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Available as donor",
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    controller.googleIsDonor.value
                        ? "Available"
                        : "Not available",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            controller.isProfileUpdateLoading.value
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primaryColor,
                    ),
                  )
                : Switch(
                    value: controller.googleIsDonor.value,
                    activeColor: AppColors.primaryColor,
                    onChanged: controller.updateDonorAvailability,
                  ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.textFieldColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 15),
          onTap: onTap,
        ),
      ),
    );
  }
}
