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
  List<String> sources = ['Facebook', 'LinkedIn', 'Google', 'Twitter'];

  String stage = "";
  int reservations = 0;
  String phoneCode = '+251';
  String phoneNumber = '';

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    fetchPipelineDetail();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> fetchPipelineDetail() async {
    try {
      final response =
          await ApiService().fetchPipelineDetail(int.parse(widget.pipelineId));
      final data = response['data'];

      setState(() {
        nameController.text = data['name'] ?? '';
        stage = data['stage']?['name'] ?? "N/A";
        reservations = data['reservations'] ?? 0;
        phoneNumbers = (data['phone'] as List?)
                ?.map((p) => p['phone'] as String)
                .toList() ??
            [];

        selectedSource = sources.contains(data['source_id'])
            ? data['source_id']
            : 'Facebook';

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
                            const SizedBox(height: 80),
                            Text("Stage: $stage",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("Reservations: $reservations",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _actionButton(
                                    "View Activities", Colors.green, () {}),
                                _actionButton(
                                    "View Reservations", Colors.green, () {}),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _actionButton(
                                    "Add Activities", Colors.green, () {}),
                                _actionButton(
                                    "Add Reservation", Colors.green, () {}),
                                _actionButton(
                                    "Mark as Lost", Colors.brown, () {}),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Name Field
                            TextField(
                              decoration:
                                  const InputDecoration(labelText: "Name"),
                              controller: nameController,
                            ),
                            const SizedBox(height: 10),

                            // Phone Number Section
                            Row(
                              children: [
                                Expanded(
                                  child: IntlPhoneField(
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(),
                                      ),
                                    ),
                                    initialCountryCode: 'ET',
                                    onChanged: (phone) {
                                      setState(() {
                                        phoneCode = '+${phone.countryCode}';
                                        phoneNumber = phone.number;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                  onPressed: () {
                                    if (phoneNumber.isNotEmpty) {
                                      setState(() {
                                        phoneNumbers
                                            .add('$phoneCode$phoneNumber');
                                        phoneNumber = '';
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),

                            // Display Phone Numbers
                            Wrap(
                              spacing: 8.0,
                              children: phoneNumbers.map((number) {
                                return Chip(
                                  label: Text(number),
                                  onDeleted: () => setState(
                                      () => phoneNumbers.remove(number)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),

                            // Source Dropdown
                            DropdownButtonFormField(
                              value: selectedSource,
                              items: sources.map((source) {
                                return DropdownMenuItem(
                                    value: source, child: Text(source));
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => selectedSource = value!),
                              decoration:
                                  const InputDecoration(labelText: "Source"),
                            ),
                            const SizedBox(height: 20),

                            // Save & Cancel Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _actionButton("Save", Colors.green, () {}),
                                _actionButton("Cancel", Colors.brown, () {}),
                              ],
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
