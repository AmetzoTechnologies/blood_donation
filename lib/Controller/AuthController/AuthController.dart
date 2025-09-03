import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Models/user_model/user_model.dart';
import 'package:blood_donation/Screens/NavigationPage.dart';
import 'package:blood_donation/Screens/RegisterPage/RegisterPage.dart';
import 'package:blood_donation/Service/ApiService.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Screens/HomePage/HomePage.dart';
import '../../Screens/LoginPage/PhoneLoginPage.dart';

class AuthController extends GetxController {
  TextEditingController phone = TextEditingController();
  TextEditingController password = TextEditingController();
  final ApiService _apiService = ApiService();
  RxBool isLoading = false.obs;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    if (token != null) {
      // ✅ Call your API to get user data
      print(token);
      await getUserData();

      // Navigate to Home
      Get.offAll(() => NavigationPage());
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

  Future<bool?> checkUserHasPassword(String phone)async{
    final endpoint="/api/v1/user/password-status?phone=$phone";
    isLoading.value=true;
    try{
      final response=await _apiService.getRequest(endpoint,bearerToken: token);
      if(response.isOk){
        final bool isPassword=response.body['passwordSet'];
        return isPassword;
      }else{
        return null;
      }
    }catch(e){
      rethrow;
    }finally{
      isLoading.value=false;
    }
  }
  Future setPassword() async {
    isLoading.value=true;
    final endpoint = "/api/v1/user/set-password";
    final data = {
      'phone': phone.text,
      'password': password.text,
    };

    try {
      final response = await _apiService.postRequest(endpoint, data);

      if (response.isOk) {
        print(response.body);
        token = response.body['token'];
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setString("token", token!);
        await getUserData();
        Get.offAll(NavigationPage());
      }else{
        Get.snackbar("Error", response.body['message']);
        print(response.body);
      }
    } catch (e) {
      print(e);

      rethrow;
    }finally{
      isLoading.value=false;
    }
  }
  Future logout()async{
    SharedPreferences pref=await SharedPreferences.getInstance();
    pref.clear();
    Get.offAll(PhoneLoginPage());
  }

  Future changePassword(String oldPassword,String newPassword)async{
    final endpoint="/api/v1/user/change-password";
    final data={
      'currentPassword':oldPassword,
      'newPassword':newPassword
    };
    try{
      final response=await _apiService.putRequest(endpoint,data: data,bearerToken: token);
      if(response.isOk){
        Get.defaultDialog(
          title: "Success ✅",
          middleText: "Password change successfully.",
          textConfirm: "OK",
          onConfirm: () {
            Get.back(); // close dialog
            Get.back();// navigate to login page
          },
        );
      }else{
        Get.snackbar("Error", response.body);
      }
    }catch(e){
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
