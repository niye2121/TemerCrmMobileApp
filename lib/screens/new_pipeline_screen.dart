import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/screens/pipeline_screen.dart';
import 'package:temer/services/api_service.dart';

class NewPipelineScreen extends StatefulWidget {
  const NewPipelineScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewPipelineScreenState createState() => _NewPipelineScreenState();
}

class _NewPipelineScreenState extends State<NewPipelineScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String selectedCountry = 'Ethiopia';
  String selectedPhoneCode = '251';
  // String? selectedSite;
  List<String> selectedSites = [];
  String? selectedSource;
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> sources = [];
  bool isLoading = false;
  final int maxAllowedSites = 3;

  @override
  void initState() {
    super.initState();
    setDefaultCountry();
    fetchDropdownData();
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

      for (var site in sites) {
        site["selected"] = site["selected"] ?? false;
      }

      // Preserve Ethiopia as default country unless the user selects another
      final ethiopia = countries.firstWhere(
        (country) => country['name'] == "Ethiopia",
        orElse: () => {'name': "Ethiopia", 'phone_code': 251},
      );
      selectedCountry = ethiopia['name'];
      selectedPhoneCode = "${ethiopia['phone_code']}";

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> createNewLead() async {
    final customerName = customerNameController.text.trim();
    final phoneNo = phoneNumberController.text.trim();

    final country = countries.firstWhere(
      (c) => c['name'] == selectedCountry,
      orElse: () => {'id': 0, 'phone_code': ''}, // Default values
    );
    final countryId = country['id'] ?? 0;
    final phoneCode = country['phone_code'] ?? '';

    final source = sources.firstWhere(
      (s) => s['name'] == selectedSource,
      orElse: () => {'id': 0},
    );
    final sourceId = source['id'] ?? 0;

    final siteIds = selectedSites
        .map((siteName) {
          return sites.firstWhere((s) => s['name'] == siteName,
              orElse: () => {'id': null})['id'];
        })
        .whereType<int>() // Filters out null values
        .toList();

    if (customerName.isEmpty ||
        phoneNo.isEmpty ||
        selectedCountry == null ||
        selectedSource == null ||
        siteIds.isEmpty) {
      showErrorDialog("All fields are required.");
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(phoneNo.replaceAll("+", ""))) {
      showErrorDialog("Phone number must contain only digits.");
      return;
    }
    if (phoneNo.length < 7 || phoneNo.length > 14) {
      showErrorDialog("Phone number must be between 7 and 14 digits.");
      return;
    }
    if (siteIds.length > maxAllowedSites) {
      showErrorDialog("You cannot select more than $maxAllowedSites sites.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService().createLead(
        customerName: customerName,
        sourceId: sourceId,
        countryId: countryId,
        phoneNo: phoneNo,
        siteIds: siteIds,
        maxAllowedSites: maxAllowedSites,
      );

      // ✅ Check if status is 200 (success) or 500 (error)
      if (response["status"] == 200 && response.containsKey("data")) {
        showSuccessDialog(response["data"]["message"]);
      } else if (response["status"] == 500 && response.containsKey("error")) {
        showErrorDialog(response["error"]);
      } else if (response["status"] == 400 && response.containsKey("error")) {
        showErrorDialog(response["error"]);
      }else {
        showErrorDialog("Unexpected response: ${response.toString()}");
      }
    } catch (e) {
      showErrorDialog("API Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
                padding: EdgeInsets.all(16),
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
                      SizedBox(height: 12),

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
                                    selectedCountry = country['name'];
                                    selectedPhoneCode =
                                        "+${country['phone_code']}";
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
                                          "+${country['phone_code']}",
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
            onPressed: () => Navigator.pop(context),
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
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
                                    // ignore: use_build_context_synchronously
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                } catch (e) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Logout failed: $e")),
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
                        width: 293, validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Customer name is required!";
                      }
                      return null;
                    }),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 15),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedPhoneCode),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _buildTextField(
                          "Phone Number",
                          phoneNumberController,
                          width: 190,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Phone number is required!";
                            }
                            if (!RegExp(r'^\d+$').hasMatch(value)) {
                              return "Phone number must contain only digits!";
                            }
                            if (value.length < 7 || value.length > 14) {
                              return "Phone number must be between 7 and 14 digits long!";
                            }
                            return null;
                          },
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
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(4, 4),
                              blurRadius: 6,
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
                          if (_formKey.currentState!.validate()) {
                            createNewLead();
                          }
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
          ),
        ],
      ),
    );
  }

 Widget _buildTextField(
  String hintText,
  TextEditingController controller, {
  required String? Function(String?)? validator,
  double width = 293,
}) {
  return SizedBox(
    width: width,
    child: FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conditionally show error message only if there's an error
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 4), // Add some spacing
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            // Text Field Container
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  field.didChange(value);
                },
              ),
            ),
          ],
        );
      },
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
