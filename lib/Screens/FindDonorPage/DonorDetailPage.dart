import 'package:blood_donation/GlobalWidgets/DonorAvatar.dart';
import 'package:blood_donation/Models/blood_donors/donor.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DonorDetailPage extends StatelessWidget {
  const DonorDetailPage({super.key, required this.donor});

  final Donor donor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Donor Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Header(donor: donor),
          const SizedBox(height: 20),
          _InfoTile(
            title: 'Phone',
            value: _value(donor.phone),
            icon: Icons.phone_outlined,
          ),
          _InfoTile(
            title: 'Place',
            value: _value(donor.place),
            icon: Icons.location_on_outlined,
          ),
          _InfoTile(
            title: 'Blood Group',
            value: _value(donor.bloodGroup),
            icon: Icons.bloodtype_outlined,
          ),
          _InfoTile(
            title: 'Gender',
            value: _value(donor.gender),
            icon: Icons.person_outline,
          ),
          _InfoTile(
            title: 'Date of Birth',
            value: _formatDate(donor.dateOfBirth),
            icon: Icons.cake_outlined,
          ),
          _InfoTile(
            title: 'Last Donation',
            value: _formatDate(donor.lastDonationDate),
            icon: Icons.event_available_outlined,
          ),
          _InfoTile(
            title: 'Available as Donor',
            value: donor.isDonor == true ? 'Available' : 'Not available',
            icon: Icons.volunteer_activism_outlined,
          ),
          const SizedBox(height: 8),
          if (donor.phone != null && donor.phone!.trim().isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _callNumber(donor.phone!.trim()),
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text(
                  'Call Donor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _value(String? value) {
    return value == null || value.trim().isEmpty ? '-' : value.trim();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return date.toLocal().toString().split(' ')[0];
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      Get.snackbar('Error', 'Could not call $phoneNumber');
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.donor});

  final Donor donor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 26),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.26),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          DonorAvatar(
            name: donor.name,
            profilePic: donor.profilePic,
            size: 104,
            borderRadius: BorderRadius.circular(52),
            backgroundColor: Colors.white.withOpacity(.25),
          ),
          const SizedBox(height: 14),
          Text(
            donor.name ?? 'Donor',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (donor.bloodGroup != null && donor.bloodGroup!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Blood Group: ${donor.bloodGroup}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
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
        borderRadius: BorderRadius.circular(12),
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
