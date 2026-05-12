import 'dart:async';

import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Models/user_model/user_model.dart';
import 'package:blood_donation/Screens/NavigationPage.dart';
import 'package:blood_donation/Service/ApiService.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Screens/LoginPage/GoogleProfilePage.dart';
import '../../Screens/LoginPage/PhoneLoginPage.dart';

class AuthController extends GetxController {
  TextEditingController phone = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController googleName = TextEditingController();
  TextEditingController googlePhone = TextEditingController();
  TextEditingController googleAddress = TextEditingController();
  TextEditingController googlePlace = TextEditingController();
  RxString googleBloodGroup = "".obs;
  RxString googleGender = "".obs;
  RxBool googleIsDonor = true.obs;
  Rxn<DateTime> googleDateOfBirth = Rxn<DateTime>();
  Rxn<DateTime> googleLastDonationDate = Rxn<DateTime>();
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        "679441613367-f716gr54d5jnoil30c0nap53iaprot02.apps.googleusercontent.com",
  );
  RxBool isLoading = false.obs;
  RxBool isGoogleProfileLoading = false.obs;
  RxBool isProfileUpdateLoading = false.obs;

  Future<void> checkAuth() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userModel = null;

    if (token != null) {
      // ✅ Call your API to get user data
      print(token);
      final hasUserData = await getUserData();

      if (!hasUserData || token == null) {
        await _clearSavedSession();
        Get.offAll(() => PhoneLoginPage());
        isLoading.value = false;
        return;
      }

      if (_isUserProfileIncomplete()) {
        _prefillGoogleProfile();
        Get.offAll(() => GoogleProfilePage());
      } else {
        Get.offAll(() => NavigationPage());
      }
    } else {
      // Navigate to Login
      Get.offAll(() => PhoneLoginPage());
    }

    isLoading.value = false;
  }

  Future loginUser() async {
    final data = {"phone": phone.text, 'password': password.text};
    final endpoint = "/api/v1/user/login";
    isLoading.value = true;
    try {
      final response = await _apiService.postRequest(endpoint, data);
      if (response.isOk) {
        token = response.body['token'];
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setString("token", token!);
        final hasUserData = await getUserData();
        if (!hasUserData) {
          _showAuthError(
            "Login failed",
            "Could not load your profile. Please sign in again.",
          );
          return;
        }
        Get.offAll(NavigationPage());
      } else {
        print(response.body);
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    const endpoint = "/api/v1/user/google-login";
    isLoading.value = true;
    try {
      print("Google sign in started");
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google sign in cancelled");
        return;
      }
      print("Google account selected: ${googleUser.email}");

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _showAuthError(
          "Google token missing",
          "Check that this Android app package and SHA-1/SHA-256 are added in your Google Cloud OAuth/Firebase config.",
        );
        return;
      }
      print("Google id token received");

      final response = await _apiService
          .postRequest(endpoint, {"idToken": idToken})
          .timeout(const Duration(seconds: 25));

      print("Google login response: ${response.statusCode} ${response.body}");

      if (response.isOk) {
        token = response.body['token'];
        if (token == null) {
          _showAuthError(
            "Google sign in failed",
            "Server accepted the request but did not return a token.",
          );
          return;
        }

        final pref = await SharedPreferences.getInstance();
        await pref.setString("token", token!);
        final hasUserData = await getUserData();
        if (!hasUserData) {
          _showAuthError(
            "Google sign in failed",
            "Could not load your profile. Please sign in again.",
          );
          return;
        }

        if (_needsGoogleProfile(response.body)) {
          _prefillGoogleProfile();
          Get.offAll(() => GoogleProfilePage());
        } else {
          Get.offAll(() => NavigationPage());
        }
      } else {
        if (response.statusCode == 404) {
          _showAuthError(
            "Google login API missing",
            "Backend route POST /api/v1/user/google-login was not found. For Android emulator local backend, run with API_BASE_URL=http://10.0.2.2:8165.",
          );
          return;
        }

        Get.snackbar(
          "Google sign in failed",
          _messageFromResponse(response.body, response.statusCode),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on TimeoutException {
      _showAuthError(
        "Google sign in timed out",
        "Google account was selected, but the app did not get a response from /api/v1/user/google-login.",
      );
    } catch (e) {
      print("Google sign in error: $e");
      _showAuthError("Google sign in failed", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _messageFromResponse(dynamic body, int? statusCode) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    if (body != null && body.toString().isNotEmpty) {
      return "Status $statusCode: ${body.toString()}";
    }
    return "Status $statusCode. Please try again.";
  }

  void _showAuthError(String title, String message) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: Get.back,
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _needsGoogleProfile(dynamic responseBody) {
    if (responseBody is Map) {
      final profileComplete = responseBody['profileComplete'];
      if (profileComplete is bool) {
        return !profileComplete;
      }

      final isProfileComplete = responseBody['isProfileComplete'];
      if (isProfileComplete is bool) {
        return !isProfileComplete;
      }

      final isNewUser = responseBody['isNewUser'];
      if (isNewUser is bool && isNewUser) {
        return true;
      }
    }

    final user = userModel?.user;
    return _isUserProfileIncomplete(user);
  }

  bool _isUserProfileIncomplete([dynamic user]) {
    return _missingProfileFields(user).isNotEmpty;
  }

  List<String> _missingProfileFields([dynamic user]) {
    final currentUser = user ?? userModel?.user;
    if (currentUser == null) {
      return ["user"];
    }

    if (currentUser.isProfileComplete == true) {
      return [];
    }

    final missing = <String>[];
    if (_isBlank(currentUser.name)) missing.add("name");
    if (currentUser.dateOfBirth == null) missing.add("dateOfBirth");
    if (_isBlank(currentUser.gender)) missing.add("gender");
    if (_isBlank(currentUser.phone)) missing.add("phone");
    if (_isBlank(currentUser.place)) missing.add("place");
    if (_isBlank(currentUser.bloodGroup)) missing.add("bloodGroup");
    if (currentUser.isDonor == null) missing.add("isDonor");
    return missing;
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  void _prefillGoogleProfile() {
    final user = userModel?.user;
    googleName.text = user?.name ?? "";
    googlePhone.text = user?.phone ?? "";
    googleAddress.text = user?.address ?? "";
    googlePlace.text = user?.place ?? "";
    googleBloodGroup.value = user?.bloodGroup ?? "";
    googleGender.value = _displayValue(user?.gender);
    googleDateOfBirth.value = user?.dateOfBirth;
    googleLastDonationDate.value = user?.lastDonationDate;
    googleIsDonor.value = user?.isDonor ?? true;
  }

  String _displayValue(String? value) {
    if (value == null || value.isEmpty) {
      return "";
    }

    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Future<void> completeGoogleProfile() async {
    const endpoint = "/api/v1/user/google-complete-profile";
    isGoogleProfileLoading.value = true;
    try {
      final data = _googleProfileData();

      print("Complete profile request: $data");

      final response = await _apiService
          .postRequest(endpoint, data, bearerToken: token)
          .timeout(const Duration(seconds: 25));

      print(
        "Complete profile response: ${response.statusCode} ${response.body}",
      );

      if (response.isOk) {
        userModel = UserModel.fromJson(response.body);
        if (userModel?.user?.isDonor != googleIsDonor.value) {
          await _syncGoogleProfileDetails(data);
        }
        final hasUserData = await getUserData();
        if (!hasUserData) {
          Get.offAll(() => PhoneLoginPage());
          return;
        }
        if (_isUserProfileIncomplete()) {
          _prefillGoogleProfile();
          final missingFields = _missingProfileFields();
          print("Profile still incomplete. Missing fields: $missingFields");
          _showAuthError(
            "Profile still incomplete",
            "The server saved the request, but these fields are still missing from /user/get: ${missingFields.join(', ')}.",
          );
        } else {
          Get.offAll(() => NavigationPage());
        }
      } else {
        _showAuthError(
          "Profile update failed",
          _messageFromResponse(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      _showAuthError(
        "Profile update timed out",
        "The app did not get a response from /api/v1/user/google-complete-profile.",
      );
    } catch (e) {
      print("Complete profile error: $e");
      _showAuthError("Profile update failed", e.toString());
    } finally {
      isGoogleProfileLoading.value = false;
    }
  }

  Map<String, dynamic> _googleProfileData() {
    return {
      "phone": googlePhone.text.trim(),
      "name": googleName.text.trim(),
      "dateOfBirth": googleDateOfBirth.value?.toIso8601String(),
      "gender": googleGender.value.toLowerCase(),
      "address": googleAddress.text.trim(),
      "place": googlePlace.text.trim(),
      "bloodGroup": googleBloodGroup.value.trim().toUpperCase(),
      "isDonor": googleIsDonor.value,
      "lastDonationDate": googleLastDonationDate.value?.toIso8601String(),
    };
  }

  Future<void> _syncGoogleProfileDetails(Map<String, dynamic> data) async {
    try {
      print("Sync profile update request: $data");
      final response = await _apiService
          .putRequest(
            "/api/v1/user/update",
            data: data,
            bearerToken: token,
          )
          .timeout(const Duration(seconds: 25));
      print("Sync profile update response: ${response.statusCode} ${response.body}");
    } catch (e) {
      print("Sync profile update error: $e");
    }
  }

  void prefillProfileUpdate() {
    final user = userModel?.user;
    googleName.text = user?.name ?? "";
    googlePhone.text = user?.phone ?? "";
    googleAddress.text = user?.address ?? "";
    googlePlace.text = user?.place ?? "";
    googleBloodGroup.value = user?.bloodGroup ?? "";
    googleGender.value = _displayValue(user?.gender);
    googleDateOfBirth.value = user?.dateOfBirth;
    googleLastDonationDate.value = user?.lastDonationDate;
    googleIsDonor.value = user?.isDonor ?? false;
  }

  Future<void> updateProfile() async {
    const endpoint = "/api/v1/user/update";
    isProfileUpdateLoading.value = true;
    try {
      final user = userModel?.user;
      final data = {
        "name": googleName.text.trim(),
        "bloodGroup": googleBloodGroup.value.trim().toUpperCase(),
        "place": googlePlace.text.trim(),
        "dateOfBirth": googleDateOfBirth.value?.toIso8601String(),
        "gender": googleGender.value.toLowerCase(),
        if (user?.isDonor != null) "isDonor": user?.isDonor,
        "lastDonationDate": googleLastDonationDate.value?.toIso8601String(),
      };

      print("Profile update request: $data");

      final response = await _apiService
          .putRequest(endpoint, data: data, bearerToken: token)
          .timeout(const Duration(seconds: 25));

      print("Profile update response: ${response.statusCode} ${response.body}");

      if (response.isOk) {
        final hasUserData = await getUserData();
        if (!hasUserData) {
          Get.offAll(() => PhoneLoginPage());
          return;
        }
        Get.back();
        _showAuthError("Profile updated", "Your profile has been updated.");
      } else {
        _showAuthError(
          "Profile update failed",
          _messageFromResponse(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      _showAuthError(
        "Profile update timed out",
        "The app did not get a response from /api/v1/user/update.",
      );
    } catch (e) {
      print("Profile update error: $e");
      _showAuthError("Profile update failed", e.toString());
    } finally {
      isProfileUpdateLoading.value = false;
    }
  }

  Future<void> updateDonorAvailability(bool isAvailable) async {
    const endpoint = "/api/v1/user/update";
    if (isProfileUpdateLoading.value) return;

    final user = userModel?.user;
    final previousValue = googleIsDonor.value;
    googleIsDonor.value = isAvailable;

    final data = {
      if (user?.name != null) "name": user?.name,
      if (user?.bloodGroup != null) "bloodGroup": user?.bloodGroup,
      if (user?.place != null) "place": user?.place,
      if (user?.dateOfBirth != null)
        "dateOfBirth": user?.dateOfBirth?.toIso8601String(),
      if (user?.gender != null) "gender": user?.gender,
      "isDonor": isAvailable,
      if (user?.lastDonationDate != null)
        "lastDonationDate": user?.lastDonationDate?.toIso8601String(),
    };

    isProfileUpdateLoading.value = true;
    try {
      print("Donor availability update request: $data");

      final response = await _apiService
          .putRequest(endpoint, data: data, bearerToken: token)
          .timeout(const Duration(seconds: 25));

      print(
        "Donor availability update response: ${response.statusCode} ${response.body}",
      );

      if (response.isOk) {
        userModel?.user?.isDonor = isAvailable;
        final hasUserData = await getUserData();
        if (!hasUserData) {
          Get.offAll(() => PhoneLoginPage());
          return;
        }
        googleIsDonor.value = userModel?.user?.isDonor ?? isAvailable;
      } else {
        googleIsDonor.value = previousValue;
        _showAuthError(
          "Donor status update failed",
          _messageFromResponse(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      googleIsDonor.value = previousValue;
      _showAuthError(
        "Donor status update timed out",
        "The app did not get a response from /api/v1/user/update.",
      );
    } catch (e) {
      googleIsDonor.value = previousValue;
      print("Donor availability update error: $e");
      _showAuthError("Donor status update failed", e.toString());
    } finally {
      isProfileUpdateLoading.value = false;
    }
  }

  Future<void> updateLastDonationDate(DateTime selectedDate) async {
    const endpoint = "/api/v1/user/update";
    if (isProfileUpdateLoading.value) return;

    final donationDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final user = userModel?.user;
    final data = {
      if (user?.name != null) "name": user?.name,
      if (user?.bloodGroup != null) "bloodGroup": user?.bloodGroup,
      if (user?.place != null) "place": user?.place,
      if (user?.isDonor != null) "isDonor": user?.isDonor,
      "lastDonationDate": donationDate.toIso8601String(),
    };

    isProfileUpdateLoading.value = true;
    try {
      print("Last donation date update request: $data");

      final response = await _apiService
          .putRequest(endpoint, data: data, bearerToken: token)
          .timeout(const Duration(seconds: 25));

      print(
        "Last donation date update response: ${response.statusCode} ${response.body}",
      );

      if (response.isOk) {
        userModel?.user?.lastDonationDate = donationDate;
        final hasUserData = await getUserData();
        if (!hasUserData) {
          Get.offAll(() => PhoneLoginPage());
          return;
        }
        Get.snackbar(
          "Donation date updated",
          "Last donation date has been saved.",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        _showAuthError(
          "Donation date update failed",
          _messageFromResponse(response.body, response.statusCode),
        );
      }
    } on TimeoutException {
      _showAuthError(
        "Donation date update timed out",
        "The app did not get a response from /api/v1/user/update.",
      );
    } catch (e) {
      print("Last donation date update error: $e");
      _showAuthError("Donation date update failed", e.toString());
    } finally {
      isProfileUpdateLoading.value = false;
    }
  }

  Future<void> updateLastDonationDateToToday() {
    return updateLastDonationDate(DateTime.now());
  }

  Future<bool> getUserData() async {
    final endpoint = "/api/v1/user/get";
    try {
      final response = await _apiService.getRequest(
        endpoint,
        bearerToken: token,
      );
      if (response.isOk) {
        print(response.body);
        userModel = UserModel.fromJson(response.body);
        return true;
      } else {
        print(response.body);
        await _clearSavedSession();
        return false;
      }
    } catch (e) {
      print("Get user data error: $e");
      await _clearSavedSession();
      return false;
    }
  }

  Future<bool?> checkUserHasPassword(String phone) async {
    final endpoint = "/api/v1/user/password-status?phone=$phone";
    isLoading.value = true;
    try {
      final response = await _apiService.getRequest(
        endpoint,
        bearerToken: token,
      );
      if (response.isOk) {
        final bool isPassword = response.body['passwordSet'];
        return isPassword;
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future setPassword() async {
    isLoading.value = true;
    final endpoint = "/api/v1/user/set-password";
    final data = {'phone': phone.text, 'password': password.text};

    try {
      final response = await _apiService.postRequest(endpoint, data);

      if (response.isOk) {
        print(response.body);
        token = response.body['token'];
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setString("token", token!);
        final hasUserData = await getUserData();
        if (!hasUserData) {
          _showAuthError(
            "Login failed",
            "Could not load your profile. Please sign in again.",
          );
          return;
        }
        Get.offAll(NavigationPage());
      } else {
        Get.snackbar("Error", response.body['message']);
        print(response.body);
      }
    } catch (e) {
      print(e);

      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future logout() async {
    await _googleSignIn.signOut();
    await _clearSavedSession();
    Get.offAll(PhoneLoginPage());
  }

  Future<void> _clearSavedSession() async {
    token = null;
    userModel = null;
    final pref = await SharedPreferences.getInstance();
    await pref.remove("token");
  }

  Future changePassword(String oldPassword, String newPassword) async {
    final endpoint = "/api/v1/user/change-password";
    final data = {'currentPassword': oldPassword, 'newPassword': newPassword};
    try {
      final response = await _apiService.putRequest(
        endpoint,
        data: data,
        bearerToken: token,
      );
      if (response.isOk) {
        Get.defaultDialog(
          title: "Success ✅",
          middleText: "Password change successfully.",
          textConfirm: "OK",
          onConfirm: () {
            Get.back(); // close dialog
            Get.back(); // navigate to login page
          },
        );
      } else {
        Get.snackbar("Error", response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    checkAuth();
  }
}
