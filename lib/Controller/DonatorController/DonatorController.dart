import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Models/blood_donors/blood_donors.dart';
import 'package:blood_donation/Models/blood_donors/donor.dart';
import 'package:blood_donation/Service/ApiService.dart';
import 'package:get/get.dart';

class DonatorController extends GetxController {
  final ApiService _apiService = ApiService();
  BloodDonors bloodDonors = BloodDonors();
  List<Donor> bloodDonorsList = [];
  int page = 1; // start page
  int limit = 10;
  String searchQuery = "";
  String? bloodGroups;
  String sortOrder = "";
  RxBool isLoading = false.obs;
  RxBool hasMore = true.obs; // ✅ to check if more data is available

  Future<void> getDonors({bool loadMore = false}) async {
    if (isLoading.value) return; // prevent duplicate calls

    if (loadMore) {
      page++; // next page
    } else {
      page = 1;
      bloodDonorsList.clear(); // reset list when new search or refresh
      hasMore.value = true;
    }

    isLoading.value = true;
    update();

    final encodedSearch = Uri.encodeComponent(searchQuery);
    final encodedBloodGroup =
    bloodGroups != null ? Uri.encodeComponent(bloodGroups!) : "";
    final endpoint =
        "/api/v1/user/get-donors?page=$page&limit=$limit&search=$encodedSearch&sortOrder=$sortOrder&bloodGroup=$encodedBloodGroup";

    try {
      final response =
      await _apiService.getRequest(endpoint, bearerToken: token);

      if (response.isOk) {
        bloodDonors = BloodDonors.fromJson(response.body);

        final newDonors = bloodDonors.donors ?? [];

        if (newDonors.isEmpty) {
          hasMore.value = false; // no more data
        } else {
          bloodDonorsList.addAll(newDonors);
        }
      } else {
        print("Error: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
