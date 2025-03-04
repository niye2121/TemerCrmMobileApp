import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';

class NewPipelineScreen extends StatefulWidget {
  const NewPipelineScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewPipelineScreenState createState() => _NewPipelineScreenState();
}

class _NewPipelineScreenState extends State<NewPipelineScreen> {
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String? selectedCountry;
  String? selectedSite;
  String? selectedSource;

  final List<String> countries = ["USA", "UK", "India", "Germany"];
  final List<String> sites = ["Site A", "Site B", "Site C"];
  final List<String> sources = ["Online", "Referral", "Walk-in"];

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
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      const Text(
                        "My Pipeline",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                                    builder: (context) => const HomeScreen()),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout,
                              color: Color(0xff84A441),
                              size: 30,
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  _buildTextField("Customer Name", customerNameController,
                      width: 293, height: 49),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 293,
                    height: 49,
                    child: IntlPhoneField(
                      controller: phoneNumberController,
                      decoration: InputDecoration(
                        hintText: "Phone Number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 15),
                      ),
                      initialCountryCode: 'ET',
                      onChanged: (phone) {
                        debugPrint(phone.completeNumber);
                      },
                      showDropdownIcon: true,
                      dropdownIconPosition: IconPosition.trailing,
                      disableLengthCheck:
                          true, // Add this line to remove the counter
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDropdownField("Site", sites, selectedSite, (value) {
                    setState(() {
                      selectedSite = value;
                    });
                  }, width: 293, height: 49),
                  const SizedBox(height: 10),
                  _buildDropdownField("Source", sources, selectedSource,
                      (value) {
                    setState(() {
                      selectedSource = value;
                    });
                  }, width: 293, height: 49),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton("Save", const Color(0xff84A441),
                          screenWidth * 0.4, 50, () {
                        // Handle save action
                      }),
                      const SizedBox(width: 10),
                      _buildButton("Cancel", const Color(0xffA47341),
                          screenWidth * 0.4, 50, () {
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

  Widget _buildTextField(String hintText, TextEditingController controller,
      {double width = 293, double height = 49}) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hintText, List<String> items,
      String? selectedValue, Function(String?) onChanged,
      {double width = 129, double height = 49}) {
    return SizedBox(
      width: width,
      height: height,
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildButton(String text, Color color, double width, double height,
      VoidCallback onPressed) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
