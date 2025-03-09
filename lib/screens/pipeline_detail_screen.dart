import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';
// ignore: depend_on_referenced_packages
import 'package:intl_phone_field/intl_phone_field.dart';

class PipelineDetailScreen extends StatefulWidget {
  final String pipelineId;

  const PipelineDetailScreen({super.key, required this.pipelineId});

  @override
  // ignore: library_private_types_in_public_api
  _PipelineDetailScreenState createState() => _PipelineDetailScreenState();
}

class _PipelineDetailScreenState extends State<PipelineDetailScreen> {
  late TextEditingController nameController;

  List<String> phoneNumbers = [];
  String selectedSource = 'Facebook';
  List<String> sources = [];
  List<String> siteNames = [];

  String stage = "";
  int reservations = 0;
  String phoneCode = '';
  String phoneNumber = '';

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    fetchPipelineDetail();
    fetchSources();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void fetchSources() async {
    List<Map<String, dynamic>> data = await ApiService().fetchSourceData();

    // Assuming the source name is stored under a key like "name"
    setState(() {
      sources = data.map((item) => item['name'].toString()).toList();
    });
  }

  Future<void> fetchPipelineDetail() async {
    try {
      final response =
          await ApiService().fetchPipelineDetail(int.parse(widget.pipelineId));
      final data = response['data'];

      setState(() {
        nameController.text = data['name'] ?? '';
        stage = data['stage']?['name'] ?? "N/A";
        reservations = data['reservation_count'] ?? 0;

        phoneNumbers = (data['phone'] as List?)
                ?.map((p) => p['phone'].toString())
                .toList() ??
            [];

        siteNames = (data['site_ids'] as List?)
                ?.map((site) => site['name'].toString())
                .toList() ??
            [];

        // Ensure `data['source_id']` is in `sources`
        if (sources.contains(data['source_id'])) {
          selectedSource = data['source_id'];
        } else if (sources.isNotEmpty) {
          selectedSource = sources.first; // Default to first valid source
        } else {
          selectedSource = ''; // Empty if no sources available
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load details: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen()),
                                          );
                                        } catch (e) {
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 134,
                                        height: 64,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff84A441),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7.33),
                                            ),
                                            padding: EdgeInsets.zero,
                                            shadowColor: Colors.black,
                                            elevation: 5,
                                          ),
                                          onPressed: () {},
                                          child: const Center(
                                            child: Text(
                                              "View Activities",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 144,
                                        height: 64,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff84A441),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7.33),
                                            ),
                                            padding: EdgeInsets.zero,
                                            shadowColor: Colors.black,
                                            elevation: 5,
                                          ),
                                          onPressed: () {},
                                          child: const Center(
                                            child: Text(
                                              "View Reservations",
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
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 58,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xff84A441),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.33),
                                              ),
                                              shadowColor: Colors.black,
                                              padding: EdgeInsets.zero,
                                              elevation: 5,
                                            ),
                                            onPressed: () {},
                                            child: const Center(
                                              child: Text(
                                                "Add\nActivities",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SizedBox(
                                          height: 58,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xff84A441),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.33),
                                              ),
                                              shadowColor: Colors.black,
                                              padding: EdgeInsets.zero,
                                              elevation: 5,
                                            ),
                                            onPressed: () {},
                                            child: const Center(
                                              child: Text(
                                                "Add\nReservation",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SizedBox(
                                          height: 58,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xffA47341),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.33),
                                              ),
                                              shadowColor: Colors.black,
                                              padding: EdgeInsets.zero,
                                              elevation: 5,
                                            ),
                                            onPressed: () {},
                                            child: const Center(
                                              child: Text(
                                                "Mark\nas Lost",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                      children: [
                                        Expanded(
                                          flex: 2,
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
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 15,
                                                        horizontal: 10),
                                                hintText: 'Country Code',
                                              ),
                                              controller: TextEditingController(
                                                  text: phoneCode),
                                              onChanged: (value) {
                                                setState(() {
                                                  phoneCode = value;
                                                });
                                              },
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 5,
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
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 15,
                                                        horizontal: 10),
                                                hintText: 'Phone Number',
                                              ),
                                              controller: TextEditingController(
                                                  text: phoneNumber),
                                              onChanged: (value) {
                                                setState(() {
                                                  phoneNumber = value;
                                                });
                                              },
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
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
                                      padding: const EdgeInsets.all(10),
                                      child: Wrap(
                                        spacing: 8.0,
                                        runSpacing:
                                            8.0, // Ensures proper spacing in multiple rows
                                        children: phoneNumbers.map((number) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xffd9d9d9), // Background color of each item
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  number,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                GestureDetector(
                                                  onTap: () => setState(() =>
                                                      phoneNumbers
                                                          .remove(number)),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .black, // Background color of the delete button
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
                                        }).toList(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  if (siteNames.isNotEmpty)
                                    SizedBox(
                                      width: 293,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                        child: Wrap(
                                          spacing: 8.0,
                                          children: siteNames
                                              .map((site) => Chip(
                                                    label: Text(site),
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                  ))
                                              .toList(),
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
                                        value: sources.contains(selectedSource)
                                            ? selectedSource
                                            : null, // Ensure valid value
                                        items: sources.toSet().map((source) {
                                          // Use `toSet()` to remove duplicates
                                          return DropdownMenuItem(
                                              value: source,
                                              child: Text(source));
                                        }).toList(),
                                        onChanged: (value) => setState(
                                            () => selectedSource = value!),
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
                                      _actionButton("Save",
                                          const Color(0xff84A441), () {}),
                                      _actionButton("Cancel",
                                          const Color(0xffA47341), () {}),
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

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
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
