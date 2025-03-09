import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NewPipelineScreen extends StatefulWidget {
  const NewPipelineScreen({super.key});

  @override
  _NewPipelineScreenState createState() => _NewPipelineScreenState();
}

class _NewPipelineScreenState extends State<NewPipelineScreen> {
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String? selectedCountry;
  // String? selectedSite;
  List<String> selectedSites = [];
  String? selectedSource;
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> sources = [];

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  void _showMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height *
                        0.6, // Limit height
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.4, // Ensure list is scrollable
                        child: ListView(
                          shrinkWrap: true,
                          children: sites.map((site) {
                            return CheckboxListTile(
                              value: selectedSites.contains(site["name"]),
                              title: Text(
                                site["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onChanged: (bool? newValue) {
                                setDialogState(() {
                                  if (newValue == true) {
                                    selectedSites.add(site["name"]);
                                  } else {
                                    selectedSites.remove(site["name"]);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity
                                  .leading, // Checkbox to the left
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
                              Navigator.pop(context);
                            },
                            child: const Text("Ok",
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> fetchDropdownData() async {
    try {
      countries = await ApiService().fetchCountryData();
      sites = await ApiService().fetchSitesData();
      sources = await ApiService().fetchSourceData();

      // Ensure "selected" key exists for all sites
      for (var site in sites) {
        site["selected"] = site["selected"] ?? false;
      }

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
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
                children: [
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Center(
                          child: const Text(
                            "New Pipeline",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
                                  builder: (context) => const HomeScreen(),
                                ),
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
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Logout failed: $e")),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  _buildTextField("Customer Name", customerNameController,
                      width: 293),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDropdownField(
                        "Country",
                        countries
                            .map((country) => country['name'].toString())
                            .toList(),
                        selectedCountry,
                        (value) {
                          setState(() {
                            selectedCountry = value;
                          });
                        },
                        width: 98,
                      ),
                      const SizedBox(width: 5),
                      _buildTextField(
                        "Phone Number",
                        phoneNumberController,
                        width: 190,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showMultiSelectDialog,
                    child: Container(
                      width: 293,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.3), // Black shadow
                            offset: Offset(4, 4), // Bottom-right shadow
                            blurRadius: 6, // Smooth shadow effect
                          ),
                        ],
                      ),
                      child: Text(
                        selectedSites.isEmpty
                            ? "Site"
                            : selectedSites.join(", "),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDropdownField(
                      "Source",
                      sources
                          .map((source) => source['name'].toString())
                          .toList(),
                      selectedSource, (value) {
                    setState(() {
                      selectedSource = value;
                    });
                  }, width: 293),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                          "Save", const Color(0xff84A441), screenWidth * 0.4,
                          () {
                        // Handle save action
                      }),
                      const SizedBox(width: 10),
                      _buildButton(
                          "Cancel",
                          const Color(0xff000000).withOpacity(0.37),
                          screenWidth * 0.4, () {
                        Navigator.pop(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 215),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "Powered by Ahadubit Technologies",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildTextField(
    String hintText,
    TextEditingController controller, {
    double width = 293,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Black shadow
            offset: Offset(4, 4), // Shadow at bottom-right corner
            blurRadius: 6, // Smooth shadow effect
          ),
        ],
      ),
      child: SizedBox(
        width: width,
        height: 49,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none, // Remove underline border
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String hintText,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged, {
    double width = 293,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Black shadow
            offset: Offset(4, 4), // Shadow at bottom-right corner
            blurRadius: 6, // Smooth shadow effect
          ),
        ],
      ),
      child: SizedBox(
        width: width,
        height: 49,
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none, // Remove underline border
            ),
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
          // Make the dropdown scrollable with a maximum height
          isExpanded: true, // Make dropdown expand horizontally
          dropdownColor: Colors.white, // Background color of the dropdown
          selectedItemBuilder: (BuildContext context) {
            return items.map((String value) {
              return Text(value, style: TextStyle(color: Colors.black));
            }).toList();
          },
          // Add constraints for max height for dropdown items to make it scrollable
          menuMaxHeight: MediaQuery.of(context).size.height *
              0.4, // Limit dropdown height to 40% of screen height
        ),
      ),
    );
  }

  Widget _buildButton(
      String text, Color color, double width, VoidCallback onPressed) {
    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.33)),
        ),
        onPressed: onPressed,
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14.29,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
