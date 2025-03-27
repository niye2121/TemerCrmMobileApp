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
    debugPrint('Raw Response: ${response.body}', wrapWidth: 2048);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["result"] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("user_id", data["result"]["uid"]);
        await prefs.setString("session", jsonEncode(data["result"]));
        await prefs.setString("user_name", data["result"]["name"]);

        // Extract the max allowed sites safely
        int maxAllowedSites = data["result"]["site"]?["allowed_no_site"] ?? 0;
        await prefs.setInt("maxAllowedSites", maxAllowedSites);
        debugPrint('maxAllowedSites: $maxAllowedSites');

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

  Future<Map<String, dynamic>> createLead({
    required String customerName,
    required int sourceId,
    required int countryId,
    required String phoneNo,
    required List<int> siteIds,
    required int maxAllowedSites,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    // Input Validations
    if (customerName.isEmpty || phoneNo.isEmpty || siteIds.isEmpty) {
      throw Exception("All fields are required.");
    }

    if (!RegExp(r'^\d+$').hasMatch(phoneNo.replaceAll("+", ""))) {
      throw Exception("Phone number must contain only digits.");
    }

    if (phoneNo.length < 7 || phoneNo.length > 14) {
      throw Exception("Phone number must be between 7 and 14 digits long.");
    }

    if (siteIds.length > maxAllowedSites) {
      throw Exception("You cannot select more than $maxAllowedSites sites.");
    }

    final url = Uri.parse("$baseUrl/api/createPipeline");

    final requestBody = {
      "customer_name": customerName,
      "source_id": sourceId,
      "phones": [
        {
          "country_id": countryId,
          "phone_no": phoneNo,
        }
      ],
      "site_ids": siteIds,
    };

    debugPrint('create lead request to be sent: $requestBody');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
      body: jsonEncode(requestBody),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseData;
    } else if (response.statusCode == 500 && responseData["error"] != null) {
      throw Exception(responseData["error"]);
    } else {
      throw Exception(
          "Failed to create lead: ${response.statusCode}, Response: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updatePipeline(
      Map<String, dynamic> pipelineData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/updatePipeline");

    // 🔹 Ensure all phone numbers are correctly formatted
    if (pipelineData.containsKey("phones")) {
      List<dynamic> phones = pipelineData["phones"];
      for (var phone in phones) {
        phone["phone"] = phone["phone"].toString();
        if (phone.containsKey("id") && phone["id"] != null) {
          phone["id"] = int.tryParse(phone["id"].toString()) ?? phone["id"];
        }
      }
    }

    // 🔹 Ensure all site IDs are properly formatted as integers
    if (pipelineData.containsKey("site_ids")) {
      pipelineData["site_ids"] = (pipelineData["site_ids"] as List)
          .map((id) => int.tryParse(id.toString()) ?? id)
          .toList();
    }

    debugPrint('Final API Payload: ${jsonEncode(pipelineData)}');

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
      body: jsonEncode(pipelineData),
    );

    debugPrint('Response: ${response.body}');

    try {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 🔹 Check API-defined status field instead of HTTP statusCode
      if (response.statusCode == 200 && responseData["status"] == 200) {
        debugPrint('Pipeline updated successfully.');
        return responseData;
      } else {
        debugPrint("API Error Response: $responseData");
        return Future.error(responseData);
      }
    } catch (e) {
      debugPrint("Error Parsing Failed: $e");
      return Future.error({"error": "Failed to parse response."});
    }
  }

  Future<List<Map<String, dynamic>>> fetchReservationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/myReservation");
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


  Future<List<Map<String, dynamic>>> fetchReservationsByPipeline(
      int pipelineId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/ReservationByPipline?id=$pipelineId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    debugPrint('fetchReservationByPipeine Response: ${response.body}');

    if (response.statusCode == 200) {
      // Decode the response and extract the 'data' field
      final responseData = jsonDecode(response.body);

      // Ensure that 'data' is present and it contains a list
      if (responseData['data'] is List) {
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        throw Exception(
            'Expected a list of reservations in the response data.');
      }
    } else {
      throw Exception(
          "Failed to load reservations by pipeline: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> fetchReservationDetail(int reservationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/ReservationDetail?id=$reservationId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    debugPrint('fetchReservationDetail Response: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData is Map<String, dynamic>) {
        return responseData;
      } else {
        throw Exception('Unexpected response format. Expected a JSON object.');
      }
    } else {
      throw Exception(
          "Failed to load reservation detail: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyTransferRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/myTransferRequests");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);

      // Ensure 'data' is a list before casting
      if (decodedResponse is Map<String, dynamic> &&
          decodedResponse['data'] is List) {
        return List<Map<String, dynamic>>.from(decodedResponse['data']);
      } else {
        throw Exception("Invalid data format from API");
      }
    } else {
      throw Exception(
          "Failed to load transfer requests: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchReservationTypes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/getReservationType");
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
      throw Exception(
          "Failed to load reservation types: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchBanks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/bank");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );
    debugPrint('fetchBanks response: ${response.body}');

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load banks: ${response.statusCode}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchDocumentTypes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/documentType");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    debugPrint('fetchDocumentTypes response: ${response.body}');

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load document types: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> createReservation(
      Map<String, dynamic> reservationData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/createReservation");

    debugPrint('Reservation to be created: $reservationData');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "session_id=$sessionId",
        },
        body: jsonEncode(reservationData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": response.statusCode,
          "error": "Failed to create reservation"
        };
      }
    } catch (e) {
      return {"status": 500, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkAmount(
      int customerId, int reservationTypeId, int propertyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse(
        "$baseUrl/api/checkAmount?customer_id=$customerId&reservation_type_id=$reservationTypeId&property_id=$propertyId");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "session_id=$sessionId",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": response.statusCode,
          "error": "Failed to check amount"
        };
      }
    } catch (e) {
      return {"status": 500, "error": e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> fetchGeneralUpdates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/general");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );
    debugPrint('fetchGeneralUpdates response: ${response.body}');

    if (response.statusCode == 200) {
      return compute(parseGeneralUpdates, response.body);
    } else {
      throw Exception("Failed to load general updates: ${response.statusCode}");
    }
  }

  List<Map<String, dynamic>> parseGeneralUpdates(String responseBody) {
    final Map<String, dynamic> parsed = json.decode(responseBody);
    final List<dynamic> dataList = parsed["data"];

    return dataList
        .map((e) => {
              "id": e["id"],
              "message": e["message"],
              "sender": e["user"]["name"],
              "date": e["date"],
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> reserveItem(int reservationTypeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    if (sessionId == null) {
      throw Exception("Session ID is missing. Please log in again.");
    }

    final url = Uri.parse("$baseUrl/api/reserve?id=$reservationTypeId");

    debugPrint("Calling API: $url");
    debugPrint("Session ID: $sessionId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    debugPrint("API Response: ${response.body}");

    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      String errorMessage =
          responseBody["error"] ?? "Reservation failed. Please try again.";
      throw Exception(errorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> fetchLostReasons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/lostReasons");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": "session_id=$sessionId",
      },
    );

    debugPrint('fetchLostReasons response: ${response.body}');

    if (response.statusCode == 200) {
      return compute(parseJson, response.body);
    } else {
      throw Exception("Failed to load lost reasons: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> markReservationAsLost({
    required int leadId,
    required int lostReasonId,
    required String lostFeedback,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString("session_id");

    final url = Uri.parse("$baseUrl/api/markAsLost");
    final body = jsonEncode({
      "lead_id": leadId,
      "lost_reason_id": lostReasonId,
      "lost_feedback": lostFeedback,
    });

    debugPrint('Marking reservation as lost: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Cookie": "session_id=$sessionId",
        },
        body: body,
      );

      debugPrint('markReservationAsLost response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": response.statusCode,
          "error": "Failed to mark reservation as lost"
        };
      }
    } catch (e) {
      return {"status": 500, "error": e.toString()};
    }
  }
}
