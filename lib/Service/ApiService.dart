import 'dart:io';

import 'package:get/get.dart';
import 'package:get/get_connect/connect.dart';

class ApiService extends GetConnect {
  ApiService() {
    // Set your base URL
    baseUrl = "https://blooddonorapi-nyk3.onrender.com";
  }
  Future<Response> getRequest(String endpoint, {String? bearerToken}) async {
    try {
      final headers = {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type':
            'application/json', // Optional: Use if API expects JSON.
      };
      final response = await get(endpoint, headers: headers);
      return response;
    } catch (e) {
      print(e);
      rethrow; // Preserve the original exception.
    }
  }

  Future<Response> deleteRequest(String endpoint, {String? bearerToken}) async {
    try {
      final headers = {
        if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
      };
      return await delete(endpoint, headers: headers);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patchRequest(
    String endpoint, {
    dynamic data,
    String? bearerToken,
  }) async {
    try {
      final headers = {
        if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
      };
      if (data != null) {
        return await patch(endpoint, data, headers: headers);
      } else {
        return await patch(endpoint, null, headers: headers);
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<Response> putRequest(
      String endpoint, {
        dynamic data,
        String? bearerToken,
      }) async {
    try {
      final headers = {
        if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
      };
      if (data != null) {
        return await put(endpoint, data, headers: headers);
      } else {
        return await put(endpoint, null, headers: headers);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> postRequest(
    String endpoint,
    dynamic data, {
    String? bearerToken,
    bool isMultipart = false,
  }) async {
    try {
      // Add headers
      final headers = {
        if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
      };

      // Check if the request is multipart
      if (isMultipart && data is Map<String, dynamic>) {
        // Create FormData for multipart upload
        final formData = FormData(
          data.map((key, value) {
            if (value is File) {
              return MapEntry(
                key,
                MultipartFile(value, filename: value.path.split('/').last),
              );
            } else {
              return MapEntry(key, value.toString());
            }
          }),
        );

        // Send POST request
        return await post(endpoint, formData, headers: headers);
      } else {
        // For JSON requests
        print("post request is done");
        print(endpoint);
        print("Final URL: ${baseUrl! + endpoint}");

        return await post(endpoint, data, headers: headers);
      }
    } catch (e) {
      print("Error in POST request: $e");
      rethrow;
    }
  }
}
