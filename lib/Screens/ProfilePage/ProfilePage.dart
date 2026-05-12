import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          _Header(user: user, onLogout: controller.logout),
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
                _DonorAvailabilityTile(
                  controller: controller,
                ),
                _InfoTile(
                  title: "Gender",
                  value: _value(user.gender),
                  icon: Icons.person_outline,
                ),
                _InfoTile(
                  title: "Date of Birth",
                  value: user.dateOfBirth == null
                      ? "-"
                      : user.dateOfBirth!.toLocal().toString().split(' ')[0],
                  icon: Icons.cake_outlined,
                ),
                _InfoTile(
                  title: "Last Donation",
                  value: user.lastDonationDate == null
                      ? "-"
                      : user.lastDonationDate!
                          .toLocal()
                          .toString()
                          .split(' ')[0],
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
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.logout,
                  color: Colors.red,
                  title: "Logout",
                  onTap: controller.logout,
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
            CircleAvatar(
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
      decoration: BoxDecoration(
        color: AppColors.textFieldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        onTap: onTap,
      ),
    );
  }
}
