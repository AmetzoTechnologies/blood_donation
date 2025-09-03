import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Screens/NavigationPage.dart';
import 'package:blood_donation/Service/ApiService.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/user_model/user_model.dart';
import '../../Screens/LoginPage/PhoneLoginPage.dart';

class RegisterController extends GetxController {
  final ApiService _apiService = ApiService();
  var isDonor = false.obs;
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  // will hold "Male", "Female", "Other"
  final gender = "".obs;

  List<String> genders = ["Male", "Female", "Other"];
  final bloodGroupController = TextEditingController();
  final locationController = TextEditingController();
  RxBool isLoading = false.obs;
  // Dates
  var dob = Rxn<DateTime>(); // Required
  var lastDonatedDate = Rxn<DateTime>(); // Optional

  // Validation
  bool validateFields() {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        phoneController.text.isEmpty ||
        bloodGroupController.text.isEmpty ||
        locationController.text.isEmpty ||
        dob.value == null) {
      return false;
    }
    return true;
  }

  void register() {

    // Example: Collect data
    final data = {
      "name": usernameController.text,
      "password": passwordController.text,
      "phone": phoneController.text,
      "bloodGroup": bloodGroupController.text.toUpperCase(),
      "place": locationController.text,
      'gender': gender.value.toLowerCase(),
      "dateOfBirth": dob.value?.toIso8601String(),
      "lastDonatedDate": lastDonatedDate.value?.toIso8601String(),
      "isDonor": isDonor.value,
    };
    registerUser(data);
    print(data); // you can call API here
  }

  Future registerUser(data) async {
    final endpoint = '/api/v1/user/register';
    isLoading.value = true;
    try {
      final response = await _apiService.postRequest(endpoint, data);
      if (response.isOk) {
        print(response.body);
        final jwtToken = response.body['token'];
        token = jwtToken;
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setString("token", jwtToken);
        await getUserData();
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
  Future getUserData() async {
    final endpoint = "/api/v1/user/get";
    try {
      final response = await _apiService.getRequest(
        endpoint,
        bearerToken: token,
      );
      if (response.isOk) {
        print(response.body);
        userModel = UserModel.fromJson(response.body);
      } else {
        print(response.body);
        if (response.body['message'] == "Invalid token") {
          Get.offAll(PhoneLoginPage());
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
