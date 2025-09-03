import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/AuthController/AuthController.dart';
import '../PasswordChangePage/PasswordChangePage.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔹 Top Header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => controller.logout(),
                      ),
                    ),

                    /// Profile Image
                    CircleAvatar(
                      radius: 50,
                      child: ClipOval(
                        child: Image.network(
                          userModel!.user!.profilePic != null
                              ? "${baseUrl}${userModel!.user!.profilePic}"
                              : "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      userModel!.user!.name ?? "User",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      userModel!.user!.phone ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Blood Group: ${userModel!.user!.bloodGroup ?? '-'}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoCard("Place", userModel!.user!.place ?? "-",
                      Icons.location_on),
                  _buildInfoCard(
                    "Date of Birth",
                    userModel!.user!.dateOfBirth != null
                        ? userModel!.user!.dateOfBirth!
                        .toLocal()
                        .toString()
                        .split(' ')[0]
                        : "-",
                    Icons.cake,
                  ),
                  _buildInfoCard(
                      "Gender", userModel!.user!.gender ?? "-", Icons.person),
                  _buildInfoCard("Donor Status",
                      userModel!.user!.isDonor == true ? "Yes" : "No", Icons.favorite),
                  _buildInfoCard(
                    "Last Donation",
                    userModel!.user!.lastDonationDate != null
                        ? userModel!.user!.lastDonationDate!
                        .toLocal()
                        .toString()
                        .split(' ')[0]
                        : "-",
                    Icons.bloodtype,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 Actions Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.lock,
                    color: Colors.blue,
                    title: "Change Password",
                    onTap: () => Get.to(() => ChangePasswordPage()),
                  ),
                  _buildActionTile(
                    icon: Icons.privacy_tip,
                    color: Colors.green,
                    title: "Privacy Policy",
                    onTap: () {
                      // Get.to(() => PrivacyPolicyPage());
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.logout,
                    color: Colors.red,
                    title: "Logout",
                    onTap: () => controller.logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      {required IconData icon,
        required Color color,
        required String title,
        required VoidCallback onTap}) {
    return Card(
      color: Colors.cyan.shade100,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
