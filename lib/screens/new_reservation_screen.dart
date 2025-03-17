import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/screens/pipeline_screen.dart';
import 'package:temer/services/api_service.dart';

class NewReservationScreen extends StatefulWidget {
  const NewReservationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewReservationScreenState createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController endDateController = TextEditingController();
  // String? selectedSite;
  List<String> selectedSites = [];
  String? selectedSource;
  List<Map<String, dynamic>> sites = [];
  List<Map<String, dynamic>> sources = [];
  bool isLoading = false;
  final int maxAllowedSites = 3;

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
      sites = await ApiService().fetchSitesData();
      sources = await ApiService().fetchSourceData();

      for (var site in sites) {
        site["selected"] = site["selected"] ?? false;
      }

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
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
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Ensures vertical alignment
                      children: [
                        // Apply left padding to the column
                        const Padding(
                          padding: EdgeInsets.only(
                              left: 35.0, top: 20.0), // Adjust padding as needed
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Aligns text to the left within the column
                            children: [
                              Text(
                                "New Reservation",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                  height: 5), // Space between the two texts
                              Text(
                                "Test-Lead Lycee",
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Icons aligned to the right
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
                    const SizedBox(height: 60),
                    _buildDropdownField(
                        "Property",
                        sources
                            .map((source) => source['name'].toString())
                            .toList(),
                        selectedSource, (value) {
                      setState(() {
                        selectedSource = value;
                      });
                    }, width: 293),
                    const SizedBox(height: 10),
                    _buildDropdownField(
                        "Reservation Type",
                        sources
                            .map((source) => source['name'].toString())
                            .toList(),
                        selectedSource, (value) {
                      setState(() {
                        selectedSource = value;
                      });
                    }, width: 293),
                    const SizedBox(height: 10),
                    _buildDisabledField("End Date:", endDateController),
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
                        _buildButton("Save", const Color(0xff84A441),
                            screenWidth * 0.4, () {}),
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
            offset: const Offset(4, 4), // Shadow at bottom-right corner
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
              return Text(value, style: const TextStyle(color: Colors.black));
            }).toList();
          },
          // Add constraints for max height for dropdown items to make it scrollable
          menuMaxHeight: MediaQuery.of(context).size.height *
              0.4, // Limit dropdown height to 40% of screen height
        ),
      ),
    );
  }

  Widget _buildDisabledField(String label, TextEditingController controller) {
  return GestureDetector(
    onTap: () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(), // Only allow future dates
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        setState(() {
          controller.text = pickedDate.toLocal().toString().split(' ')[0];
        });
      }
    },
    child: Container(
      width: 293,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[400],
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
        controller.text.isEmpty ? label : controller.text,
        style: const TextStyle(color: Colors.black),
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
