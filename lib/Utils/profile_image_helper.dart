import 'package:blood_donation/Constant/Constant.dart';

String? resolveProfileImageUrl(String? profilePic) {
  if (profilePic == null || profilePic.trim().isEmpty) {
    return null;
  }

  final trimmed = profilePic.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  return '$baseUrl/${trimmed.replaceFirst(RegExp(r'^/+'), '')}';
}
