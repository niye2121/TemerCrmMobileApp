import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "https://staging.temerproperties.com";

  Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/web/session/authenticate");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "db": "dev_temer_feb27",
          "login": username,
          "password": password
        }
      }),
    );

    debugPrint('Response Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["result"] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("user_id", data["result"]["uid"]);
        await prefs.setString("session", jsonEncode(data["result"]));
        await prefs.setString("user_name", data["result"]["name"]);

        // Extract session ID from cookies
        String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          String? sessionId = _extractSessionId(rawCookie);
          if (sessionId != null) {
            await prefs.setString("session_id", sessionId);
            debugPrint('Session ID saved: $sessionId');
          }
        }

        return true;
      }
    }
    return false;
  }

// Extract session ID from cookie string
  String? _extractSessionId(String rawCookie) {
    RegExp regExp = RegExp(r"session_id=([^;]+)");
    Match? match = regExp.firstMatch(rawCookie);
    return match?.group(1);
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    if (sessionId != null) {
      final url = Uri.parse("$baseUrl/web/session/destroy");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "session_id=$sessionId",
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Session successfully destroyed.");
      } else {
        debugPrint("Failed to destroy session: ${response.statusCode}");
      }
    }

    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("user_id");
  }

  Future<List<Map<String, dynamic>>> fetchPipelineData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/myPipeline");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load pipeline data: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchPropertiesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/properties");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load pipeline data: ${response.statusCode}");
    }
  }

  // JSON parsing in a separate thread
  List<Map<String, dynamic>> parseJson(String responseBody) {
    final Map<String, dynamic> responseData = jsonDecode(responseBody);
    if (responseData.containsKey("data") && responseData["data"] is List) {
      return List<Map<String, dynamic>>.from(responseData["data"]);
    } else {
      throw Exception(
          "Invalid response format: Missing 'data' key or incorrect type");
    }
  }

  Future<Map<String, dynamic>> fetchPipelineDetail(int pipelineId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    // Correct API format with query parameter
    final url = Uri.parse("$baseUrl/api/myPipelineDetail?id=$pipelineId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          "Failed to load pipeline details: ${response.statusCode}, Response: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchSitesData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/lookup?name=site");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load site data: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCountryData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/lookup?name=country");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load country data: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchSourceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/lookup?name=source");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load source data: ${response.statusCode}");
    }
  }
}
