import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/screens/new_reservation_screen.dart';
import 'package:temer/screens/pipeline_screen.dart';
import 'package:temer/screens/reservations_screen.dart';
import 'package:temer/services/api_service.dart';

class PipelineDetailScreen extends StatefulWidget {
  final String pipelineId;

  const PipelineDetailScreen({super.key, required this.pipelineId});

  @override
  // ignore: library_private_types_in_public_api
  _PipelineDetailScreenState createState() => _PipelineDetailScreenState();
}

class _PipelineDetailScreenState extends State<PipelineDetailScreen> {
  late TextEditingController nameController;
  final TextEditingController phoneNumberController = TextEditingController();

  List<String> phoneNumbers = [];
  String? selectedSource;
  List<String> siteNames = [];
  List<String> selectedSites = [];

  String stage = "";
  int reservations = 0;
  String phoneCode = '';
  String phoneNumber = '';

  bool isLoading = true;
  bool isReservationStage = false;
  String errorMessage = '';
  String selectedCountry = 'Ethiopia';
  String selectedPhoneCode = '251';
  int? selectedCountryId;
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> sources = [];
  List<Map<String, dynamic>> pipelineReservations = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    fetchPipelineDetail();
    fetchDropdownData();
    fetchReservations();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> fetchedPhones = []; // Store fetched phones

  Future<void> fetchDropdownData() async {
    try {
      countries = await ApiService().fetchCountryData();
      sites = await ApiService().fetchSitesData();
      sources = await ApiService().fetchSourceData();

      for (var site in sites) {
        site["selected"] = site["selected"] ?? false;
      }

      // Preserve Ethiopia as default country unless the user selects another
      final ethiopia = countries.firstWhere(
        (country) => country['name'] == "Ethiopia",
        orElse: () => {'id': -1, 'name': "Ethiopia", 'phone_code': 251},
      );

      // Set default values for Ethiopia
      selectedCountry = ethiopia['name']; // Store the name
      selectedPhoneCode = ethiopia['id']; // Store the numeric ID
      selectedPhoneCode = "${ethiopia['phone_code']}"; // Store the phone code

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> fetchPipelineDetail() async {
    try {
      if (sources.isEmpty) {
        await fetchDropdownData();
      }

      final response =
          await ApiService().fetchPipelineDetail(int.parse(widget.pipelineId));
      final data = response['data'];

      setState(() {
        nameController.text = data['customer'] ?? '';
        stage = data['stage']?['name'] ?? "N/A";
        debugPrint('stage in fetchPipelineDetail: $stage');
        reservations = data['reservation_count'] ?? 0;

        isReservationStage = stage == "Reservation";

        if (data.containsKey('partner_id')) {
          int partnerId = data['partner_id'];
          _savePartnerId(partnerId);
        }

        if (data.containsKey('id')) {
          int leadId = data['id'];
          _saveLeadId(leadId);
        }

        if (data.containsKey('name')) {
          String name = data['name'];
          _saveCustomerName(name);
        }

        fetchedPhones = (data['phone'] as List?)
                ?.where(
                    (p) => p is Map<String, dynamic> && p.containsKey('phone'))
                .map((p) => {
                      "id": p["id"].toString(),
                      "country_id": p["country_id"],
                      "phone": p["phone"]
                    })
                .toList() ??
            [];

        phoneNumbers = fetchedPhones.map((p) => p["phone"].toString()).toList();

        siteNames = (data['site_ids'] as List?)
                ?.where((site) =>
                    site is Map<String, dynamic> && site.containsKey('name'))
                .map((site) => site['name'].toString())
                .toList() ??
            [];

        selectedSites = List.from(siteNames);

        // Store registered sites in SharedPreferences
        _saveRegisteredSites(siteNames);

        if (data.containsKey('source_id')) {
          int sourceId = data['source_id'];

          try {
            var foundSource = sources.firstWhere(
              (source) => source['id'] == sourceId,
              orElse: () => {},
            );

            selectedSource =
                foundSource.isNotEmpty ? foundSource['name'] : 'Unknown Source';
          } catch (e) {
            selectedSource = 'Unknown Source';
          }
        }

        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load details: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _savePartnerId(int partnerId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt("partner_id", partnerId);
    } catch (e) {
      debugPrint("Error saving partner ID: $e");
    }
  }

  Future<void> _saveCustomerName(String name) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("name", name);
    } catch (e) {
      debugPrint("Error saving name: $e");
    }
  }

  Future<void> _saveLeadId(int leadId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt("lead_id", leadId);
    } catch (e) {
      debugPrint("Error saving partner ID: $e");
    }
  }

// Save registered sites in SharedPreferences
  Future<void> _saveRegisteredSites(List<String> sites) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList("registered_sites", sites);
    } catch (e) {
      debugPrint("Error saving registered sites: $e");
    }
  }

  int getDefaultCountryId() {
    // Find Ethiopia in the countries list
    final ethiopia = countries.firstWhere(
      (country) => country["name"] == "Ethiopia",
      orElse: () => countries.isNotEmpty ? countries.first : {"id": 1},
    );

    return ethiopia["id"];
  }

  Future<void> fetchReservations() async {
    try {
      final reservations = await ApiService()
          .fetchReservationsByPipeline(int.parse(widget.pipelineId));
      setState(() {
        pipelineReservations = reservations;
      });
    } catch (e) {
      debugPrint("Error fetching reservations: $e");
    }
  }

  Future<void> updatePipelineDetail() async {
    setState(() {
      isLoading = true;
    });

    try {
      int defaultCountryId = getDefaultCountryId();
      List<Map<String, dynamic>> updatedPhones = [];

      // Preserve existing phone numbers
      for (var existingPhone in fetchedPhones) {
        updatedPhones.add({
          "id": existingPhone["id"].toString(),
          "country_id": existingPhone["country_id"],
          "phone": existingPhone["phone"].toString(),
        });
      }

      // Add new phone from text field (WITHOUT ID)
      String newPhoneNumber = phoneNumberController.text.trim();
      if (newPhoneNumber.isNotEmpty) {
        updatedPhones.add({
          "country_id": selectedCountryId ?? defaultCountryId,
          "phone": newPhoneNumber.replaceAll("+", "").trim().toString()
        });
      }

      debugPrint("updated phones: ${jsonEncode(updatedPhones)}");

      // Ensure at least one phone exists
      if (updatedPhones.isEmpty) {
        showErrorDialog("At least one phone number is required.");
        return;
      }

      updatedPhones = updatedPhones
          .where((p) =>
              phoneNumbers.contains(p["phone"]) ||
              p["phone"] == newPhoneNumber.replaceAll("+", "").trim())
          .toList();

      // Build final payload
      final Map<String, dynamic> pipelineData = {
        "id": int.parse(widget.pipelineId),
        "customer_name": nameController.text,
        "source_id": sources
            .firstWhere((source) => source['name'] == selectedSource)['id'],
        "phones": updatedPhones.map((p) {
          return {
            if (p["id"] != null)
              "id": p["id"],
            "country_id": p["country_id"] ?? selectedCountryId,
            "phone": p["id"] != null
                ? p["phone"]
                : p["phone"]
                    .replaceAll("+", "")
                    .replaceAll(selectedPhoneCode, "")
                    .trim()
          };
        }).toList(),
        "site_ids": selectedSites.map((site) {
          return sites.firstWhere((s) => s['name'] == site)['id'];
        }).toList(),
      };

      final response = await ApiService().updatePipeline(pipelineData);

      if (response["status"] == 200) {
        await fetchPipelineDetail();
        setState(() {
          isLoading = false;
        });
        showSuccessDialog(response["data"]["message"]);
      } else {
        showErrorDialog(response["data"]["message"]);
      }
    } catch (error) {
      debugPrint("Caught Error: $error");
      if (error is Map<String, dynamic> && error.containsKey("error")) {
        showErrorDialog(error["error"]);
      } else {
        showErrorDialog("Something went wrong. Please try again.");
      }
    }
  }

  void _showMultiSelectDialog() {
    List<String> tempSelectedSites = List.from(selectedSites);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: ListView(
                        shrinkWrap: true,
                        children: sites.map((site) {
                          bool isSelected =
                              tempSelectedSites.contains(site["name"]);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              site["name"],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onChanged: isReservationStage
                                ? null
                                : (bool? newValue) {
                                    setDialogState(() {
                                      if (newValue == true) {
                                        tempSelectedSites.add(site["name"]);
                                      } else {
                                        if (tempSelectedSites.length > 1) {
                                          tempSelectedSites
                                              .remove(site["name"]);
                                        } else {
                                          showErrorDialog(
                                              "At least one site must be selected.");
                                        }
                                      }
                                    });
                                  },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff84A441),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7.33),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedSites = List.from(tempSelectedSites);
                              siteNames = List.from(tempSelectedSites);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("OK",
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffA47341),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7.33),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void setDefaultCountry() {
    // Ensure Ethiopia is set as the default country
    final ethiopia = countries.firstWhere(
      (country) => country['name'] == "Ethiopia",
      orElse: () =>
          {'name': "Ethiopia", 'phone_code': 251}, // Hardcoded fallback
    );
    selectedCountry = ethiopia['name'];
    selectedPhoneCode = "${ethiopia['phone_code']}";
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredCountries = List.from(countries);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  // 🔹 Allow scrolling if content overflows
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Field
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search country...",
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            filteredCountries = countries
                                .where((country) => country['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Country List (🔹 Flexible to avoid overflow)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height *
                              0.5, // 50% of screen height
                        ),
                        child: Scrollbar(
                          child: ListView.builder(
                            shrinkWrap:
                                true, // 🔹 Prevents infinite height issue
                            itemCount: filteredCountries.length,
                            itemBuilder: (context, index) {
                              var country = filteredCountries[index];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedCountryId = country['id'];
                                    selectedCountry = country['name'];
                                    selectedPhoneCode =
                                        country['phone_code'].toString();
                                  });
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff84A441)
                                              .withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                              8), // Rounded corners
                                          border: Border.all(
                                              color: const Color(0xff84A441)
                                                  .withOpacity(0.5),
                                              width: 1),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          "+${country['phone_code'].toString()}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .white, // White text to contrast with the theme color
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Country Name
                                      Expanded(
                                        child: Text(
                                          country['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("Error",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isLoading = false; // Ensure loading stops
              });
              Navigator.pop(context); // Close dialog
            },
            child: const Text("OK",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle,
                color: Colors.green, size: 28), // ✅ Success icon
            SizedBox(width: 8),
            Text("Success",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PipelineScreen(),
                ),
              );
            },
            child: const Text("OK",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Current stage: $stage');
    debugPrint('isReservationStage: $isReservationStage');

    bool isInactiveStage = stage == "Expired" || stage == "Lost";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    Positioned(
                      left: -130,
                      top: -140,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: const Color(0xff84A441).withOpacity(0.38),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Spacer(),
                                const Text(
                                  "My Pipeline",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.house,
                                        color: Color(0xff84A441),
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomeScreen()),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.logout,
                                        color: Color(0xff84A441),
                                        size: 30,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await ApiService().logout();
                                          Navigator.pushReplacement(
                                            // ignore: use_build_context_synchronously
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen()),
                                          );
                                        } catch (e) {
                                          // ignore: use_build_context_synchronously
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text("Logout failed: $e")),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 60),
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Stage: $stage",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1.0, 1.0),
                                              blurRadius: 2.0,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "Reservations: $reservations",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1.0, 1.0),
                                              blurRadius: 2.0,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .end, // Aligns to the right
                                    children: [
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (isInactiveStage) return;
                                          switch (value) {
                                            case 'add_reservation':
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const NewReservationScreen()),
                                              );
                                              break;
                                            case 'view_reservations':
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReservationsScreen(
                                                    reservations:
                                                        pipelineReservations,
                                                  ),
                                                ),
                                              );
                                              break;

                                            case 'add_activity':
                                              showAddActivityPopup(context);
                                              break;
                                            case 'view_activities':
                                              showActivityPopup(context);
                                              break;
                                            case 'mark_lost':
                                              _showMarkAsLostDialog(
                                                  int.parse(widget.pipelineId));
                                              break;
                                          }
                                        },
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem(
                                            value: 'add_reservation',
                                            enabled: !isInactiveStage,
                                            child:
                                                const Text('Add Reservation'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'view_reservations',
                                            child: Text('View Reservations'),
                                          ),
                                          PopupMenuItem(
                                            value: 'add_activity',
                                            enabled: !isInactiveStage,
                                            child: const Text('Add Activity'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'view_activities',
                                            child: Text('View Activities'),
                                          ),
                                          PopupMenuItem(
                                            value: 'mark_lost',
                                            enabled: !isInactiveStage,
                                            child: Container(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              padding: const EdgeInsets.all(5),
                                              child: const Text(
                                                'Mark as Lost',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ],
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isInactiveStage
                                                ? Colors.grey
                                                : const Color(0xff84A441),
                                            borderRadius:
                                                BorderRadius.circular(7.33),
                                          ),
                                          width: 116,
                                          height: 52,
                                          child: const Center(
                                            child: Text(
                                              "Action",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 25),
                                  SizedBox(
                                    width: 293,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: nameController,
                                        enabled: !isReservationStage,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 10),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: 293,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: _showCountryPicker,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 25, vertical: 15),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  offset: const Offset(4, 4),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(selectedPhoneCode),
                                                const Icon(
                                                    Icons.arrow_drop_down),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),

                                        // Use a TextField with the controller
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                  offset: const Offset(2, 2),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              controller: phoneNumberController,
                                              keyboardType: TextInputType.phone,
                                              enabled: !isReservationStage,
                                              decoration: const InputDecoration(
                                                hintText: "phone number",
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 15),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: 293,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xffd9d9d9),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8, bottom: 8),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 2.0,
                                          mainAxisSpacing: 2.0,
                                          childAspectRatio: 3,
                                        ),
                                        itemCount: phoneNumbers.length,
                                        itemBuilder: (context, index) {
                                          final number = phoneNumbers[index];
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xffd9d9d9),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 3),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    number,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: isReservationStage
                                                      ? null
                                                      : () {
                                                          if (phoneNumbers
                                                                  .length >
                                                              1) {
                                                            setState(() =>
                                                                phoneNumbers
                                                                    .remove(
                                                                        number));
                                                          } else {
                                                            showErrorDialog(
                                                                "At least one phone number is required.");
                                                          }
                                                        },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _showMultiSelectDialog,
                                    child: Container(
                                      width: 293,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (siteNames.isNotEmpty)
                                            Expanded(
                                              child: Wrap(
                                                spacing: 4.0,
                                                runSpacing: 2.0,
                                                children: siteNames
                                                    .map((site) => Chip(
                                                          label: Text(site),
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                        ))
                                                    .toList(),
                                              ),
                                            ),
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(left: 10.0),
                                            child: Icon(Icons.arrow_drop_down,
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: 293,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: selectedSource,
                                        items: sources.map((source) {
                                          return DropdownMenuItem<String>(
                                            value: source[
                                                'name'], // Ensure the source name is used
                                            child: Text(source['name']),
                                          );
                                        }).toList(),
                                        onChanged: isReservationStage
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  selectedSource = value!;
                                                });
                                              },
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _actionButton(
                                        "Save",
                                        isInactiveStage
                                            ? Colors.grey
                                            : const Color(0xff84A441),
                                        isInactiveStage
                                            ? null
                                            : updatePipelineDetail,
                                      ),
                                      _actionButton(
                                        "Cancel",
                                        const Color(0xff000000)
                                            .withOpacity(0.37),
                                        () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const PipelineScreen()),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Footer
                            const Center(
                              child: Text(
                                "Powered by Ahadubit Technologies",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void showActivityPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Make background transparent for shadow effect
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // Black shadow
                offset: const Offset(4, 4), // Shadow at bottom-right corner
                blurRadius: 6, // Smooth shadow effect
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "March 22, 2025",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    activityItem(
                        "Dawit Bekele", "Empire → Empire, New road (site)", 6),
                    activityItem("Dawit Bekele", "Office Visit done", 6),
                    activityItem("Dawit Bekele",
                        "Stage changed\n• Prospect → Follow Up (Stage)", 6),
                    activityItem("Dawit Bekele", "Site Visit done", 6),
                    activityItem(
                        "Dawit Bekele",
                        "Subject: Lead/Opportunity\nLead/Opportunity created with phone +251911657038",
                        6),
                    activityItem("Dawit Bekele", "Lead/Opportunity created", 6),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget activityItem(String name, String description, int daysAgo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text(name[0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$name - $daysAgo days ago",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showAddActivityPopup(BuildContext context) async {
    List<Map<String, dynamic>> lostReasons =
        await ApiService().fetchLostReasons();
    int? selectedLostReasonId;
    TextEditingController closingNoteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffd9d9d9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Schedule Activity",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff84A441))),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(4, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        // ✅ Fix applied
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Activity Type",
                            border: InputBorder.none,
                          ),
                          items: lostReasons.map((reason) {
                            return DropdownMenuItem<int>(
                              value: reason["id"],
                              child: Text(
                                reason["bank"],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLostReasonId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(4, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: closingNoteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Summary",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _actionButton(
                        "Cancel",
                        const Color(0xff000000).withOpacity(0.37),
                        () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: _actionButton(
                          "Mark as Lost",
                          selectedLostReasonId == null
                              ? Colors.grey
                              : const Color(0xff84A441),
                          () {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMarkAsLostDialog(int leadId) async {
    List<Map<String, dynamic>> lostReasons =
        await ApiService().fetchLostReasons();
    int? selectedLostReasonId;
    TextEditingController closingNoteController = TextEditingController();

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      "Mark as Lost",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff84A441),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Lost Reason Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            // ✅ Fix applied
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Lost Reason",
                                border: InputBorder.none,
                              ),
                              items: lostReasons.map((reason) {
                                return DropdownMenuItem<int>(
                                  value: reason["id"],
                                  child: Text(
                                    reason["bank"],
                                    overflow: TextOverflow
                                        .ellipsis, // ✅ Prevents long text overflow
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedLostReasonId = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Closing Note Text Area
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: closingNoteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "What went wrong?",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _actionButton(
                            "Cancel",
                            const Color(0xff000000).withOpacity(0.37),
                            () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 10), // Optional spacing
                        Expanded(
                          child: _actionButton(
                            "Mark as Lost",
                            selectedLostReasonId == null
                                ? Colors.grey
                                : const Color(0xff84A441),
                            selectedLostReasonId == null
                                ? null
                                : () async {
                                    Map<String, dynamic> response =
                                        await ApiService()
                                            .markReservationAsLost(
                                      leadId: leadId,
                                      lostReasonId: selectedLostReasonId!,
                                      lostFeedback:
                                          closingNoteController.text.trim(),
                                    );

                                    if (response["status"] == 200) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context);
                                      showSuccessDialog(
                                          "Reservation marked as lost.");
                                    } else {
                                      showErrorDialog(response["error"]);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: 129,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.33),
          ),
          shadowColor: Colors.black,
          elevation: 5,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
