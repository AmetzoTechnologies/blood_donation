import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:blood_donation/Controller/AuthController/AuthController.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/NavController/BottomNavController.dart';

class NavigationPage extends StatelessWidget {
  NavigationPage({super.key});

  final BottomNavController navController = Get.put(BottomNavController());
  final AuthController authController = Get.find<AuthController>();

  final iconList = [Icons.home, Icons.person];

  Future<void> _showLastDonationDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now();

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          final dateText = MaterialLocalizations.of(
            context,
          ).formatMediumDate(selectedDate);

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: AppColors.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Last Donation Date",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textFieldColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dateText,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: Get.back,
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
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Get.back();
                            authController.updateLastDonationDate(
                              selectedDate,
                            );
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => navController.pages[navController.selectedIndex.value]),
      // Floating Center Icon
      floatingActionButton: Obx(
        () {
          final isUpdating = authController.isProfileUpdateLoading.value;

          return SizedBox(
            height: 70,
            width: 70,
            child: FloatingActionButton(
              heroTag: "lastDonationDateButton",
              backgroundColor: Colors.cyan,
              elevation: 4,
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white, width: 4),
              ),
              onPressed: isUpdating
                  ? null
                  : () => _showLastDonationDialog(context),
              child: isUpdating
                  ? const SizedBox(
                      height: 26,
                      width: 26,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(
                      Icons.water_drop,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(
        () => AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: navController.selectedIndex.value,
          gapLocation: GapLocation.center, // creates space for FAB
          notchSmoothness: NotchSmoothness.softEdge,
          backgroundColor: Colors.white,
          activeColor: Colors.cyan,
          inactiveColor: Colors.grey,
          onTap: (index) => navController.changePage(index),
        ),
      ),
    );
  }
}
