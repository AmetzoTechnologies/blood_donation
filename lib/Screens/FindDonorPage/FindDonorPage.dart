import 'package:blood_donation/GlobalWidgets/CustomTextField.dart';
import 'package:blood_donation/Models/blood_donors/donor.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Constant/Constant.dart';
import '../../Controller/DonatorController/DonatorController.dart';
import 'package:get/get.dart';
class FindDonorsPage extends StatelessWidget {
  final String bloodGroup;
  const FindDonorsPage({super.key, required this.bloodGroup});

  @override
  Widget build(BuildContext context) {
    final DonatorController controller = Get.put(DonatorController());

    // Call API when page is built
    controller.bloodGroups = bloodGroup;
    controller.getDonors();

    TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Find Donors",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box
            CustomTextField(
              hintText: "Search",
              prefixIcon: Icons.search,
              controller: searchController,
              onSubmitted: (value) {
                controller.searchQuery = value;
                controller.getDonors(loadMore: false); // reset search
              },
            ),
            const SizedBox(height: 20),

            Text(
              "$bloodGroup Donors",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // LIST WITH LOADING
            Expanded(
              child: GetBuilder<DonatorController>(
                builder: (ctrl) {
                  if (ctrl.isLoading.value && ctrl.bloodDonorsList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (ctrl.bloodDonorsList.isEmpty) {
                    return const Center(child: Text("No donors found"));
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!ctrl.isLoading.value &&
                          ctrl.hasMore.value &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                        ctrl.getDonors(loadMore: true); // ✅ load next page
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: ctrl.bloodDonorsList.length +
                          ((ctrl.hasMore.value && ctrl.isLoading.value && ctrl.page > 1) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < ctrl.bloodDonorsList.length) {
                          final donor = ctrl.bloodDonorsList[index];
                          return buildDonorCard(donor);
                        } else {
                          // ✅ show loader only when loading next page
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
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

  Container buildDonorCard(Donor donor) {
    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Profile Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              donor.profilePic != null
                                  ? "${baseUrl}${donor.profilePic}"
                                  : "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // fallback if URL is invalid / not loading
                                return Image.network(
                                  "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Name + Location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donor.name ?? "",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        donor.place ?? "",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Call Button
                          InkWell(
                            onTap: (){
                              callNumber(donor.phone!);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.cyan,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
  }
  Future<void> callNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication, // 👈 This is important
      );
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

}
