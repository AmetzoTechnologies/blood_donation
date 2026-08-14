import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blood_donation/Constant/Constant.dart';
import 'package:blood_donation/Models/user_model/user_model.dart';
import 'package:blood_donation/Screens/NavigationPage.dart';
import 'package:blood_donation/Service/ApiService.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:blood_donation/Utils/image_compressor.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../Screens/LoginPage/GoogleProfilePage.dart';
import '../../Screens/LoginPage/PhoneLoginPage.dart';

class AuthController extends GetxController {
  static const String _tokenKey = "token";
  static const String _cachedUserKey = "cached_user";

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
  Rxn<File> selectedProfilePic = Rxn<File>();
  Rxn<File> proofFrontFile = Rxn<File>();
  Rxn<File> proofBackFile = Rxn<File>();
  final ApiService _apiService = ApiService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // serverClientId (Web client) is required on Android to receive idToken.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: googleWebClientId,
  );
  RxBool isLoading = false.obs;
  RxBool isGoogleProfileLoading = false.obs;
  RxBool isProfileUpdateLoading = false.obs;
  RxBool isMediaUploadLoading = false.obs;

  Future<void> checkAuth() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_tokenKey);
      userModel = null;

      if (token != null) {
        print(token);
        final hasUserData = await getUserData();

        if (hasUserData) {
          _openNextPage();
          return;
        }

        if (token != null && await _restoreCachedUserData()) {
          _openNextPage();
          return;
        }
      }

      if (await _restoreGoogleSession()) {
        return;
      }

      Get.offAll(() => PhoneLoginPage());
    } finally {
      isLoading.value = false;
    }
  }

  void _openNextPage() {
    if (_isUserProfileIncomplete()) {
      _prefillGoogleProfile();
      Get.offAll(() => GoogleProfilePage());
    } else {
      Get.offAll(() => NavigationPage());
    }
  }

  Future<bool> _restoreGoogleSession() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        return false;
      }

      return _signInWithGoogleAccount(googleUser, showErrors: false);
    } catch (e) {
      print("Silent Google restore error: $e");
      return false;
    }
  }

  Future<bool> _restoreCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString(_cachedUserKey);
      if (cachedUser == null || cachedUser.isEmpty) {
        return false;
      }

      final decoded = jsonDecode(cachedUser);
      if (decoded is! Map) {
        await prefs.remove(_cachedUserKey);
        return false;
      }

      userModel = UserModel.fromJson(Map<String, dynamic>.from(decoded));
      return userModel?.user != null;
    } catch (e) {
      print("Cached user restore error: $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
      return false;
    }
  }

  Future<void> _cacheUserData() async {
    if (userModel?.user == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(userModel!.toJson()));
  }

  Future<void> _saveToken(String value) async {
    token = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }

  bool _setUserDataFromResponse(dynamic body) {
    if (body is! Map || body['user'] == null) {
      return false;
    }

    userModel = UserModel.fromJson(Map<String, dynamic>.from(body));
    return userModel?.user != null;
  }

  Future<GoogleSignInAccount?> _getGoogleUserForSignIn() async {
    try {
      final silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        return silentUser;
      }
    } catch (e) {
      print("Silent Google sign in before prompt failed: $e");
    }

    return _googleSignIn.signIn();
  }

  bool _isAuthFailureResponse(Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return true;
    }

    final body = response.body;
    if (body is! Map) {
      return false;
    }

    final message = body['message']?.toString().toLowerCase();
    if (message == null) {
      return false;
    }

    return message.contains("invalid token") ||
        message.contains("unauthorized") ||
        message.contains("jwt");
  }

  Future<bool> _signInWithGoogleAccount(
    GoogleSignInAccount googleUser, {
    required bool showErrors,
  }) async {
    try {
      var signedInUser = googleUser;
      print("Google account selected: ${signedInUser.email}");

      final googleAuth = await signedInUser.authentication;
      var idToken = googleAuth.idToken;
      var accessToken = googleAuth.accessToken;

      // Retry once if token is missing (common after first install / config change).
      if (idToken == null) {
        await _googleSignIn.signOut();
        final retryUser = await _googleSignIn.signIn();
        if (retryUser != null) {
          final retryAuth = await retryUser.authentication;
          idToken = retryAuth.idToken;
          accessToken = retryAuth.accessToken;
          signedInUser = retryUser;
        }
      }

      if (idToken == null) {
        if (showErrors) {
          _showAuthError(
            "Google token missing",
            "Your google-services.json has no OAuth clients yet.\n\n"
            "1) Firebase Console → Project settings → Your Android app → add SHA-1 keys\n"
            "2) Authentication → Sign-in method → enable Google\n"
            "3) Re-download google-services.json into android/app/\n"
            "4) Put the Web client ID into googleWebClientId in Constant.dart\n"
            "5) flutter clean && flutter run",
          );
        }
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
      print("Firebase Google sign-in complete for ${signedInUser.email}");

      return _loginWithIdToken(idToken, showErrors: showErrors);
    } on FirebaseAuthException catch (e) {
      print("Firebase auth error: ${e.code} ${e.message}");
      if (showErrors) {
        _showAuthError(
          "Google sign in failed",
          e.message ?? e.code,
        );
      }
      return false;
    } catch (e) {
      print("Google sign in error: $e");
      if (showErrors) {
        _showAuthError(
          "Google sign in failed",
          _friendlyErrorMessage(
            e,
            fallback: "Google sign in failed. Please try again.",
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _loginWithIdToken(
    String idToken, {
    String endpoint = "/api/v1/user/google-login",
    String providerName = "Google",
    String? rawAppleToken,
    Map<String, dynamic>? appleDetails,
    required bool showErrors,
  }) async {
    try {
      print("$providerName id token received");

      final body = <String, dynamic>{
        "idToken": idToken,
        "token": idToken,
        if (rawAppleToken != null && rawAppleToken.isNotEmpty) ...{
          "identityToken": rawAppleToken,
          "appleToken": rawAppleToken,
        },
        if (appleDetails != null) ...appleDetails,
      };

      final response = await _apiService
          .postRequest(
            endpoint,
            body,
            bearerToken: idToken,
          )
          .timeout(const Duration(seconds: 25));

      print(
        "$providerName login response: ${response.statusCode} ${response.statusText} ${response.body}",
      );

      if (response.isOk) {
        final jwtToken = response.body['token']?.toString();
        if (jwtToken == null || jwtToken.isEmpty) {
          if (showErrors) {
            _showAuthError(
              "$providerName sign in failed",
              "Server accepted the request but did not return a token.",
            );
          }
          return false;
        }

        await _saveToken(jwtToken);
        final hasResponseUser = _setUserDataFromResponse(response.body);
        if (hasResponseUser) {
          await _cacheUserData();
        }

        final hasUserData = await getUserData();
        if (!hasUserData && token == null) {
          if (showErrors) {
            _showAuthError(
              "$providerName sign in failed",
              "Your saved session was rejected. Please try signing in again.",
            );
          }
          return false;
        }

        if (!hasUserData && !hasResponseUser) {
          if (showErrors) {
            _showAuthError(
              "$providerName sign in failed",
              "Could not load your profile. Please try again.",
            );
          }
          return false;
        }

        _openNextPage();

        return true;
      }

      if (!showErrors) {
        return false;
      }

      if (response.statusCode == null) {
        _showAuthError(
          "$providerName sign in failed",
          _messageFromResponse(
            response.body,
            response.statusCode,
            statusText: response.statusText,
          ),
        );
        return false;
      }

      if (response.statusCode == 404) {
        _showAuthError(
          "$providerName login API missing",
          "Backend route POST $endpoint was not found.",
        );
        return false;
      }

      _showSnack(
        "$providerName sign in failed",
        _messageFromResponse(
          response.body,
          response.statusCode,
          statusText: response.statusText,
        ),
      );

      return false;
    } on TimeoutException {
      if (showErrors) {
        _showAuthError(
          "$providerName sign in timed out",
          "The app did not get a response from $endpoint.",
        );
      }
      return false;
    } catch (e) {
      print("Backend $providerName login error: $e");
      if (showErrors) {
        _showAuthError(
          "$providerName sign in failed",
          _friendlyErrorMessage(
            e,
            fallback: "$providerName sign in failed. Please try again.",
          ),
        );
      }
      return false;
    }
  }

  Future loginUser() async {
    final data = {"phone": phone.text, 'password': password.text};
    final endpoint = "/api/v1/user/login";
    isLoading.value = true;
    try {
      final response = await _apiService.postRequest(endpoint, data);
      if (response.isOk) {
        final jwtToken = response.body['token']?.toString();
        if (jwtToken == null || jwtToken.isEmpty) {
          _showAuthError(
            "Login failed",
            "Server accepted the request but did not return a token.",
          );
          return;
        }

        await _saveToken(jwtToken);
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
    isLoading.value = true;
    try {
      print("Google sign in started");
      final googleUser = await _getGoogleUserForSignIn();
      if (googleUser == null) {
        print("Google sign in cancelled");
        _showSnack(
          "Google sign in cancelled",
          "No Google account was selected.",
        );
        return;
      }

      await _signInWithGoogleAccount(googleUser, showErrors: true);
    } catch (e) {
      print("Google sign in error: $e");
      _showAuthError(
        "Google sign in failed",
        _friendlyErrorMessage(
          e,
          fallback: "Google sign in failed. Please try again.",
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in with Apple → Firebase Auth → POST /api/v1/user/apple-login
  Future<void> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      _showAuthError(
        "Not available",
        "Sign in with Apple is only available on Apple devices.",
      );
      return;
    }

    isLoading.value = true;
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        _showAuthError(
          "Sign in with Apple unavailable",
          "This device does not support Sign in with Apple.",
        );
        return;
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        _showAuthError(
          "Apple sign in failed",
          "Apple did not return an identity token. Please try again.",
        );
        return;
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      // Prefer given name from Apple (only provided on first authorization).
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      if ((givenName != null && givenName.isNotEmpty) ||
          (familyName != null && familyName.isNotEmpty)) {
        final displayName = [givenName, familyName]
            .where((part) => part != null && part.trim().isNotEmpty)
            .join(' ')
            .trim();
        if (displayName.isNotEmpty &&
            (userCredential.user?.displayName == null ||
                userCredential.user!.displayName!.isEmpty)) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        _showAuthError(
          "Apple sign in failed",
          "Could not get a Firebase token after Apple sign in.",
        );
        return;
      }

      await _loginWithIdToken(
        firebaseIdToken,
        endpoint: "/api/v1/user/apple-login",
        providerName: "Apple",
        rawAppleToken: identityToken,
        appleDetails: {
          "authorizationCode": appleCredential.authorizationCode,
          "userIdentifier": appleCredential.userIdentifier,
          if (appleCredential.email != null && appleCredential.email!.isNotEmpty)
            "email": appleCredential.email,
          if (givenName != null && givenName.isNotEmpty) "givenName": givenName,
          if (familyName != null && familyName.isNotEmpty)
            "familyName": familyName,
        },
        showErrors: true,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _showSnack(
          "Apple sign in cancelled",
          "Sign in with Apple was cancelled.",
        );
        return;
      }
      _showAuthError(
        "Apple sign in failed",
        e.message.isNotEmpty ? e.message : e.code.toString(),
      );
    } on FirebaseAuthException catch (e) {
      print("Firebase Apple auth error: ${e.code} ${e.message}");
      _showAuthError(
        "Apple sign in failed",
        e.message ?? e.code,
      );
    } catch (e) {
      print("Apple sign in error: $e");
      _showAuthError(
        "Apple sign in failed",
        _friendlyErrorMessage(
          e,
          fallback: "Apple sign in failed. Please try again.",
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _messageFromResponse(
    dynamic body,
    int? statusCode, {
    String? statusText,
  }) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    if (body != null && body.toString().isNotEmpty) {
      return "Status $statusCode: ${body.toString()}";
    }
    if (statusCode == null && statusText != null && statusText.isNotEmpty) {
      return statusText;
    }
    if (statusCode == null) {
      return "No response from server. Check your internet connection and try again. If the backend is waking up, wait a few seconds before retrying.";
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
                  onPressed: _safePop,
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
      barrierDismissible: false,
    );
  }

  /// Avoid Get.back() — it tries to close GetX snackbars and can throw
  /// LateInitializationError when the snackbar controller was never initialized.
  void _safePop() {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) {
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showSnack(String title, String message) {
    final context = Get.context;
    if (context == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("$title\n$message"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  /// Never surface raw exception text (paths, errno, stack) in the UI.
  String _friendlyErrorMessage(
    Object error, {
    required String fallback,
  }) {
    if (error is StateError) {
      final message = error.message.trim();
      if (message.isNotEmpty && !_looksTechnical(message)) {
        return message;
      }
    }

    if (error is PathNotFoundException || error is FileSystemException) {
      return "Could not read the selected file. Please choose it again.";
    }

    final raw = error.toString().trim();
    if (raw.isEmpty || _looksTechnical(raw)) {
      return fallback;
    }

    return raw
        .replaceFirst(RegExp(r'^Bad state:\s*'), '')
        .replaceFirst(RegExp(r'^StateError:\s*'), '');
  }

  bool _looksTechnical(String message) {
    final lower = message.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('errno') ||
        lower.contains('os error') ||
        lower.contains('path =') ||
        lower.contains('/data/') ||
        lower.contains('file_picker') ||
        lower.contains('stack trace') ||
        lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('timeoutexception') ||
        RegExp(r'[A-Za-z]:\\').hasMatch(message);
  }

  Future<File> _persistPickedFile(File source) async {
    if (!await source.exists()) {
      throw StateError(
        "Could not read the selected file. Please choose it again.",
      );
    }

    final tempDir = await getTemporaryDirectory();
    final extension = p.extension(source.path);
    final destPath = p.join(
      tempDir.path,
      "pick_${DateTime.now().millisecondsSinceEpoch}$extension",
    );
    return source.copy(destPath);
  }

  bool _isUserProfileIncomplete([dynamic user]) {
    return _missingProfileFields(user).isNotEmpty;
  }

  List<String> _missingProfileFields([dynamic user]) {
    final currentUser = user ?? userModel?.user;
    if (currentUser == null) {
      return ["user"];
    }

    // Required fields for a usable account. If these exist, send the user
    // to home even when backend flags like isProfileComplete / isNewUser
    // are missing or wrong (avoids "Phone already in use" on complete page).
    final missing = <String>[];
    if (_isBlank(currentUser.name)) missing.add("name");
    if (currentUser.dateOfBirth == null) missing.add("dateOfBirth");
    if (_isBlank(currentUser.gender)) missing.add("gender");
    if (_isBlank(currentUser.phone)) missing.add("phone");
    if (_isBlank(currentUser.place)) missing.add("place");
    if (_isBlank(currentUser.bloodGroup)) missing.add("bloodGroup");

    if (missing.isEmpty) {
      return [];
    }

    if (currentUser.isProfileComplete == true) {
      return [];
    }

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
    clearPendingUploads();
  }

  String _displayValue(String? value) {
    if (value == null || value.isEmpty) {
      return "";
    }

    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  String? get savedProfilePicUrl {
    final profilePic = userModel?.user?.profilePic;
    if (profilePic == null || profilePic.trim().isEmpty) {
      return null;
    }
    if (profilePic.startsWith("http://") || profilePic.startsWith("https://")) {
      return profilePic;
    }
    return "$baseUrl/${profilePic.replaceFirst(RegExp(r'^/+'), '')}";
  }

  String fileName(File? file) {
    if (file == null) {
      return "";
    }
    final segments = file.uri.pathSegments;
    if (segments.isNotEmpty) {
      return Uri.decodeComponent(segments.last);
    }
    return file.path.split(Platform.pathSeparator).last;
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickProfilePic() async {
    final file = await _selectImageFile();
    if (file != null) {
      selectedProfilePic.value = file;
    }
  }

  Future<void> pickProofFront() async {
    final file = await _selectImageFile();
    if (file != null) {
      proofFrontFile.value = file;
    }
  }

  Future<void> pickProofBack() async {
    final file = await _selectImageFile();
    if (file != null) {
      proofBackFile.value = file;
    }
  }

  void clearSelectedProfilePic() {
    selectedProfilePic.value = null;
  }

  void clearProofFront() {
    proofFrontFile.value = null;
  }

  void clearProofBack() {
    proofBackFile.value = null;
  }

  void clearPendingUploads() {
    selectedProfilePic.value = null;
    proofFrontFile.value = null;
    proofBackFile.value = null;
  }

  bool _isImageExtension(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    return const ["jpg", "jpeg", "png", "webp", "heic", "heif"].contains(ext);
  }

  Future<File?> _selectImageFile() async {
    final context = Get.context;
    if (context == null) {
      return _pickImage(source: ImageSource.gallery);
    }

    final option = await showModalBottomSheet<_ImagePickOption>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "Choose Image Source",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primaryColor,
                    ),
                    title: const Text(
                      "Photo Library / Gallery",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "Select from iOS Photos or Android Gallery",
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () => Navigator.of(ctx).pop(_ImagePickOption.gallery),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primaryColor,
                    ),
                    title: const Text(
                      "Camera",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "Take a new photo with camera",
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () => Navigator.of(ctx).pop(_ImagePickOption.camera),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(
                      Icons.folder_open_outlined,
                      color: AppColors.primaryColor,
                    ),
                    title: const Text(
                      "Files App",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "Browse files on your device",
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () => Navigator.of(ctx).pop(_ImagePickOption.files),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (option == null) {
      return null;
    }

    switch (option) {
      case _ImagePickOption.gallery:
        return _pickImage(source: ImageSource.gallery);
      case _ImagePickOption.camera:
        return _pickImage(source: ImageSource.camera);
      case _ImagePickOption.files:
        return _pickImage(useFilePicker: true);
    }
  }

  Future<File?> _pickImage({
    ImageSource? source,
    bool useFilePicker = false,
  }) async {
    try {
      String? path;
      if (useFilePicker) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ["jpg", "jpeg", "png", "webp", "heic", "heif"],
          allowMultiple: false,
        );
        path = result?.files.single.path;
      } else {
        final selectedSource = source ?? ImageSource.gallery;
        final XFile? xFile = await _imagePicker.pickImage(
          source: selectedSource,
          imageQuality: 90,
        );
        path = xFile?.path;
      }

      if (path == null || path.isEmpty) {
        return null;
      }

      if (!_isImageExtension(path)) {
        _showSnack(
          "Invalid file format",
          "Only image files (JPG, JPEG, PNG, WEBP, HEIC) are allowed.",
        );
        return null;
      }

      final picked = await _persistPickedFile(File(path));
      return await ImageCompressor.compressIfNeeded(picked);
    } catch (e) {
      debugPrint("Image selection error: $e");
      _showSnack(
        "Image selection failed",
        _friendlyErrorMessage(
          e,
          fallback: "Could not select the image. Please try again.",
        ),
      );
      return null;
    }
  }

  Future<void> completeGoogleProfile() async {
    const endpoint = "/api/v1/user/google-complete-profile";
    isGoogleProfileLoading.value = true;
    try {
      if (!_validateRequiredProofSelection()) {
        return;
      }

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
        await _syncGoogleProfileDetails(data);
        final filesUploaded = await _uploadSelectedMediaIfNeeded();
        if (!filesUploaded) {
          return;
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
      _showAuthError(
        "Profile update failed",
        _friendlyErrorMessage(
          e,
          fallback: "Something went wrong. Please try again.",
        ),
      );
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
          .putRequest("/api/v1/user/update", data: data, bearerToken: token)
          .timeout(const Duration(seconds: 25));
      print(
        "Sync profile update response: ${response.statusCode} ${response.body}",
      );
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
    clearPendingUploads();
  }

  Future<void> updateProfile() async {
    const endpoint = "/api/v1/user/update";
    isProfileUpdateLoading.value = true;
    try {
      if (!_validateProofSelection()) {
        return;
      }

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
        final filesUploaded = await _uploadSelectedMediaIfNeeded();
        if (!filesUploaded) {
          return;
        }
        final hasUserData = await getUserData();
        if (!hasUserData) {
          Get.offAll(() => PhoneLoginPage());
          return;
        }
        _safePop();
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
      _showAuthError(
        "Profile update failed",
        _friendlyErrorMessage(
          e,
          fallback: "Something went wrong. Please try again.",
        ),
      );
    } finally {
      isProfileUpdateLoading.value = false;
    }
  }

  bool _validateProofSelection() {
    final hasFront = proofFrontFile.value != null;
    final hasBack = proofBackFile.value != null;
    if (hasFront == hasBack) {
      return true;
    }

    _showAuthError(
      "Proof documents incomplete",
      "Please select both proof front and proof back files.",
    );
    return false;
  }

  bool _validateRequiredProofSelection() {
    final hasFront = proofFrontFile.value != null;
    final hasBack = proofBackFile.value != null;
    if (hasFront && hasBack) {
      return true;
    }

    _showAuthError(
      "ID proof required",
      "Please upload ID proof front and back.",
    );
    return false;
  }

  Future<bool> _uploadSelectedMediaIfNeeded() async {
    final profilePic = selectedProfilePic.value;
    final proofFront = proofFrontFile.value;
    final proofBack = proofBackFile.value;

    if (profilePic == null && proofFront == null && proofBack == null) {
      return true;
    }

    isMediaUploadLoading.value = true;
    try {
      if (profilePic != null) {
        if (!await profilePic.exists()) {
          clearSelectedProfilePic();
          _showAuthError(
            "Upload failed",
            "Could not read the selected photo. Please choose it again.",
          );
          return false;
        }
        debugPrint("Profile photo upload request: ${profilePic.path}");
        final response = await _apiService
            .putMultipartRequest(
              "/api/v1/user/update",
              files: {"profilePic": profilePic},
              bearerToken: token,
            )
            .timeout(const Duration(seconds: 30));

        debugPrint(
          "Profile photo upload response: ${response.statusCode} ${response.body}",
        );

        if (!response.isOk) {
          _showAuthError(
            "Profile photo upload failed",
            "Could not upload your photo. Please try again.",
          );
          return false;
        }
      }

      if (proofFront != null && proofBack != null) {
        if (!await proofFront.exists() || !await proofBack.exists()) {
          clearProofFront();
          clearProofBack();
          _showAuthError(
            "Upload failed",
            "Could not read the selected proof files. Please choose them again.",
          );
          return false;
        }
        debugPrint(
          "Proof upload request: ${proofFront.path}, ${proofBack.path}",
        );
        final response = await _apiService
            .putMultipartRequest(
              "/api/v1/user/upload-proof",
              files: {"proofFront": proofFront, "proofBack": proofBack},
              bearerToken: token,
            )
            .timeout(const Duration(seconds: 30));

        debugPrint(
          "Proof upload response: ${response.statusCode} ${response.body}",
        );

        if (!response.isOk) {
          _showAuthError(
            "Proof upload failed",
            "Could not upload your proof documents. Please try again.",
          );
          return false;
        }
      }

      clearPendingUploads();
      return true;
    } on TimeoutException {
      _showAuthError(
        "Upload timed out",
        "Upload took too long. Please check your connection and try again.",
      );
      return false;
    } catch (e) {
      debugPrint("Media upload error: $e");
      _showAuthError(
        "Upload failed",
        _friendlyErrorMessage(
          e,
          fallback: "Could not upload your file. Please try again.",
        ),
      );
      return false;
    } finally {
      isMediaUploadLoading.value = false;
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
      _showAuthError(
        "Donor status update failed",
        _friendlyErrorMessage(
          e,
          fallback: "Could not update donor status. Please try again.",
        ),
      );
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
        _showSnack(
          "Donation date updated",
          "Last donation date has been saved.",
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
      _showAuthError(
        "Donation date update failed",
        _friendlyErrorMessage(
          e,
          fallback: "Could not update donation date. Please try again.",
        ),
      );
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
      final response = await _apiService
          .getRequest(endpoint, bearerToken: token)
          .timeout(const Duration(seconds: 25));
      if (response.isOk) {
        print(response.body);
        userModel = UserModel.fromJson(response.body);
        await _cacheUserData();
        return true;
      } else {
        print(response.body);
        if (_isAuthFailureResponse(response)) {
          await _clearSavedSession();
        }
        return false;
      }
    } catch (e) {
      print("Get user data error: $e");
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
        final jwtToken = response.body['token']?.toString();
        if (jwtToken == null || jwtToken.isEmpty) {
          _showAuthError(
            "Login failed",
            "Server accepted the request but did not return a token.",
          );
          return;
        }

        await _saveToken(jwtToken);
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
        _showSnack("Error", response.body['message']?.toString() ?? "Login failed");
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
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _clearSavedSession();
    Get.offAll(PhoneLoginPage());
  }

  Future<void> _clearSavedSession() async {
    token = null;
    userModel = null;
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_tokenKey);
    await pref.remove(_cachedUserKey);
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
            _safePop(); // close dialog
            _safePop(); // leave password page
          },
        );
      } else {
        _showSnack("Error", response.body?.toString() ?? "Password change failed");
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

enum _ImagePickOption { gallery, camera, files }
