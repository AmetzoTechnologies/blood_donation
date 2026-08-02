import 'package:blood_donation/Models/user_model/user_model.dart';

String? token;
UserModel? userModel;
String baseUrl = "https://bloodapi.anazko.com";

/// Web client ID from Firebase (client_type 3 in google-services.json).
/// Required so Android returns an idToken.
const String googleWebClientId =
    "354622519459-ld4snk9mrq369vt5qgblp9u3nm9q5rs3.apps.googleusercontent.com";
