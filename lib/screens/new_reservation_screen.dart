import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';
import 'package:file_picker/file_picker.dart';

class NewReservationScreen extends StatefulWidget {
  const NewReservationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewReservationScreenState createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  String? requestLetterBase64;
  String? paymentReceiptsBase64;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController endDateController = TextEditingController();
  String? selectedProperty;
  String? selectedReservationType;
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> reservationTypes = [];
  List<Map<String, String>> payments = [];
  bool isLoading = true;
  bool paymentRequired = false;
  Map<String, dynamic>? selectedReservation;
  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> documentTypes = [];
  String amount = "";
  double expectedAmount = 0;
  double remainingAmount = 0;
  bool showInsufficientMessage = false;
  bool isAmountSufficient = false;
  String fetchedName = "";
  String requestLetterFileType = "";
  String paymentFileType = "";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final propertiesData = await ApiService().fetchPropertiesData();
      final reservationData = await ApiService().fetchReservationTypes();
      final banksData = await ApiService().fetchBanks();
      final documentTypesData = await ApiService().fetchDocumentTypes();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? registeredSites = prefs.getStringList("registered_sites");

      fetchedName = prefs.getString("name") ?? "";

      if (registeredSites != null) {
        properties = propertiesData
            .where((prop) =>
                prop.containsKey("site") &&
                registeredSites.contains(prop["site"].toString()) &&
                prop["state"] == "available")
            .toList();
      } else {
        properties = [];
      }

      banks = banksData;

      debugPrint('banks updated: $banks');

      documentTypes = documentTypesData;
      reservationTypes = reservationData
          .where((type) => type["is_used_use"] == false)
          .toList();

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void updateAmount() async {
    if (selectedProperty != null && selectedReservationType != null) {
      int? propertyId = properties.firstWhere(
        (prop) => prop['name'] == selectedProperty,
        orElse: () => {'id': null},
      )['id'];

      int? reservationTypeId = reservationTypes.firstWhere(
        (type) => type['name'] == selectedReservationType,
        orElse: () => {'id': null},
      )['id'];

      if (propertyId != null && reservationTypeId != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? customerId = prefs.getInt("partner_id");

        if (customerId == null) {
          setState(() {
            amount = "Customer ID not found";
          });
          return;
        }

        try {
          var response = await ApiService()
              .checkAmount(customerId, reservationTypeId, propertyId);

          if (response.containsKey("data") &&
              response["data"].containsKey("expected")) {
            setState(() {
              expectedAmount =
                  double.parse(response["data"]["expected"].toString());
              remainingAmount = expectedAmount; // Set initial remaining amount
              isAmountSufficient = false; // Reset state

              amount =
                  "Insufficient Amount! Remaining Amount: ${remainingAmount.toStringAsFixed(2)}";
            });
          } else {
            setState(() {
              amount = "Failed to fetch amount";
            });
          }
        } catch (e) {
          setState(() {
            amount = "Error fetching amount";
          });
        }
      }
    }
  }

  void onReservationTypeChanged(String? value) {
    setState(() {
      selectedReservationType = value;

      selectedReservation = reservationTypes.firstWhere(
        (type) => type["name"] == value,
        orElse: () => {},
      );

      if (selectedReservation != null) {
        paymentRequired = selectedReservation!["is_payment_required"];
      } else {
        paymentRequired = false;
      }
      calculateEndDate();
    });

    updateAmount();

    debugPrint('Selected Reservation Type: $selectedReservationType');
    debugPrint('Reservation Type: ${selectedReservation?["reservation_type"]}');
    debugPrint('Payment Required: $paymentRequired');
  }

  void calculateEndDate() {
    if (selectedReservationType != null) {
      var selectedType = reservationTypes.firstWhere(
        (type) => type["name"] == selectedReservationType,
        orElse: () => {},
      );

      int duration = selectedType["duration"];
      String durationIn = selectedType["duration_in"];

      DateTime startDate = DateTime.now();
      DateTime endDate = startDate;

      if (durationIn == "days") {
        int daysAdded = 0;

        while (daysAdded < duration) {
          endDate = endDate.add(const Duration(days: 1));

          // Skip Sundays (weekday == 7)
          if (endDate.weekday != DateTime.sunday) {
            daysAdded++;
          }
        }
      } else if (durationIn == "hours") {
        endDate = startDate.add(Duration(hours: duration));
      } else {
        endDate = startDate;
      }

      setState(() {
        endDateController.text =
            "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')} "
            "${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}";
      });
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
              Navigator.pop(context);
            },
            child: const Text("OK",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void createReservation() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? partnerId = prefs.getInt("partner_id");
      int? leadId = prefs.getInt("lead_id");

      int? propertyId = properties.firstWhere(
          (prop) => prop['name'] == selectedProperty,
          orElse: () => {})['id'];
      int? reservationTypeId = reservationTypes.firstWhere(
          (type) => type['name'] == selectedReservationType,
          orElse: () => {})['id'];

      if (propertyId == null || reservationTypeId == null) {
        showErrorDialog("Invalid property or reservation type selection.");
        return;
      }

      if (paymentReceiptsBase64 == null || paymentReceiptsBase64!.isEmpty) {
        debugPrint("Error: No payment receipt data provided.");
      }

      debugPrint('banks in create reservation: $banks');

      Map<String, dynamic> reservationData = {
        "property_id": propertyId,
        "partner_id": partnerId,
        "lead_id": leadId,
        "reservation_type_id": reservationTypeId,
        "expire_date": endDateController.text,
        if (requestLetterBase64 != null) "request_letter": requestLetterBase64,
        "payment_line_ids": payments
            .map((payment) => {
                  "document_type_id": documentTypes.firstWhere(
                    (doc) => doc["name"] == payment["document_type"],
                    orElse: () => {"id": 0},
                  )["id"],
                  "bank_id": banks.firstWhere(
                      (bank) =>
                          bank["bank"].trim().toLowerCase() ==
                          payment["bank_name"]!.trim().toLowerCase(),
                      orElse: () {
                    debugPrint(
                        "No matching bank found for '${payment['bank_name']}'");
                    return {"id": 0};
                  })["id"],
                  "payment_receipt": payment["payment_receipt"],
                  "ref_number": payment['reference_number'],
                  "transaction_date": payment['date'],
                  "amount": int.parse(payment['amount']!),
                  "is_verified": false,
                })
            .toList(),
      };

      // Show loading indicator
      setState(() => isLoading = true);

      // Check before sending request
      if (paymentReceiptsBase64 != null &&
          !isValidBase64(paymentReceiptsBase64!)) {
        debugPrint("Invalid Base64 format for payment receipt!");
      }

      // Call API service
      Map<String, dynamic> response =
          await ApiService().createReservation(reservationData);

      setState(() => isLoading = false);

      if (response.containsKey("error")) {
        showErrorDialog(response["error"]);
      } else {
        showSuccessDialog("Reservation created successfully!");
      }
    }
  }

  void _viewFile(String base64Data, String fileType) async {
    if (base64Data.isEmpty) return;

    try {
      // ✅ First Base64 decode
      String firstDecodedString = utf8.decode(base64Decode(base64Data));

      // ✅ Second Base64 decode
      Uint8List decodedBytes = base64Decode(firstDecodedString);

      // Get a temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath =
          "${tempDir.path}/temp_file.$fileType"; // ✅ Correct extension

      // Write the file to the temporary location
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(decodedBytes);

      if (fileType == "jpg" || fileType == "png") {
        // ✅ Display the image in a dialog
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Uploaded File"),
            content:
                Image.memory(decodedBytes), // ✅ Image is now correctly decoded
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      } else if (fileType == "pdf") {
        // ✅ Open PDFs using an external viewer
        OpenFile.open(tempPath);
      } else {
        // Unsupported file type
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unsupported file format")),
        );
      }
    } catch (e) {
      debugPrint("Error decoding file: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error decoding file")),
      );
    }
  }

  Future<void> _pickFile(bool isPaymentReceipt) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true, // Ensures data is available
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      debugPrint("No file selected or invalid path");
      return;
    }

    try {
      File file = File(result.files.single.path!);
      List<int> fileBytes = await file.readAsBytes();

      // Extract file extension
      String? fileExtension = result.files.single.extension;

      if (fileExtension == null) {
        debugPrint("Could not determine file extension.");
        return;
      }

      // Double Base64 encoding
      String firstBase64 = base64Encode(fileBytes);
      String doubleEncodedBase64 = base64Encode(utf8.encode(firstBase64));

      setState(() {
        if (isPaymentReceipt) {
          paymentReceiptsBase64 = doubleEncodedBase64;
          paymentFileType = fileExtension;
        } else {
          requestLetterBase64 = doubleEncodedBase64;
          requestLetterFileType = fileExtension;
        }
      });

      // Ensure immediate UI update by triggering a rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });

      debugPrint("File uploaded: $fileExtension");
    } catch (e) {
      debugPrint("Error encoding file: $e");
    }
  }

  String cleanBase64(String base64String) {
    return base64String
        .replaceAll('"', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
  }

  bool isValidBase64(String str) {
    final RegExp base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return str.length % 4 == 0 && base64Regex.hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? buildSkeletonLoader()
          : buildReservationForm(),
    );
  }

  Widget buildReservationForm() {
    return Stack(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligns items to the top
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 35.0, top: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "New Reservation",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 150,
                              child: Text(
                                fetchedName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 10.0), // Moves the icons upward
                        child: Row(
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  if (remainingAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        amount,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                  _buildDropdownField(
                      "Property",
                      properties
                          .map((prop) => prop['name'].toString())
                          .toList(),
                      selectedProperty, (value) {
                    setState(() {
                      selectedProperty = value;
                      updateAmount();
                    });
                  }, width: 293),
                  const SizedBox(height: 15),
                  _buildDropdownField(
                      "Reservation Type",
                      reservationTypes
                          .map((type) => type['name'].toString())
                          .toList(),
                      selectedReservationType,
                      onReservationTypeChanged,
                      width: 293),
                  const SizedBox(height: 15),
                  _buildDisabledField("End Date:", endDateController),

                  if (selectedReservation?["reservation_type"] ==
                      "special") ...[
                    const SizedBox(height: 15),
                    // Display the Request Letter Button
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _pickFile(false), // Upload Request Letter
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff84A441),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Request Letter",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          if (requestLetterBase64 !=
                              null) // Show immediately after upload
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye,
                                  color: Color(0xff84A441)),
                              onPressed: () => _viewFile(
                                  requestLetterBase64!, requestLetterFileType),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (paymentRequired) ...[
                    const SizedBox(height: 10),
                    // Display the Add Payment Button
                    _buildButton(
                      "Add Payment",
                      const Color(0xff84A441),
                      200,
                      49,
                      () {
                        debugPrint("Add Payment Clicked");
                        showPaymentPopup(context, () {
                          setState(() {});
                        });
                      },
                    ),
                  ],
                  // Scrollable Payment List
                  if (payments.isNotEmpty)
                    SizedBox(
                      height: 150, // Adjust height as needed
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                "Bank: ${payment['bank_name']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Acct No: ${payment['account_number']}"),
                                  Text("Doc: ${payment['document_type']}"),
                                  Text("Ref: ${payment['reference_number']}"),
                                  Text("Date: ${payment['date']}"),
                                  Text(
                                    "Amount: ${payment['amount']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xff84A441)),
                                    onPressed: () {
                                      showPaymentPopup(
                                          context, () => setState(() {}),
                                          editPayment: payment, index: index);
                                    },
                                  ),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Color(0xff84A441)),
                                    onPressed: () {
                                      showDeleteConfirmation(context, index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton("Save", const Color(0xff84A441), 129, 54,
                          createReservation),
                      const SizedBox(width: 10),
                      _buildButton(
                          "Cancel",
                          const Color(0xff000000).withOpacity(0.37),
                          129,
                          54, () {
                        Navigator.pop(context);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        height: 52,
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
    return Container(
      width: 293,
      decoration: BoxDecoration(
        color: const Color(0xffD9D9D9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(4, 4),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.text.isEmpty ? label : controller.text,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
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

  void showPaymentPopup(BuildContext context, VoidCallback refreshReservations,
      {Map<String, dynamic>? editPayment, int? index}) async {
    String? selectedBank;
    String? selectedDocument;
    List<DropdownMenuItem<String>> bankItems = [];
    List<DropdownMenuItem<String>> documentTypeItems = [];
    TextEditingController referenceController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    if (editPayment != null) {
      selectedBank = banks
          .firstWhere((bank) => bank["bank"] == editPayment["bank_name"],
              orElse: () => {"id": null})["id"]
          ?.toString();

      selectedDocument = documentTypes
          .firstWhere((doc) => doc["name"] == editPayment["document_type"],
              orElse: () => {"id": null})["id"]
          ?.toString();

      referenceController.text = editPayment["reference_number"] ?? "";
      dateController.text = editPayment["date"] ?? "";
      amountController.text = editPayment["amount"] ?? "";
    }

    Map<String, String?> errorMessages = {
      "bank": null,
      "document": null,
      "reference": null,
      "date": null,
      "amount": null,
    };

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return buildSkeletonLoader();
      },
    );

    try {
      // Fetch both banks and document types
      banks = await ApiService().fetchBanks();
      documentTypes = await ApiService().fetchDocumentTypes();

      bankItems = banks.map((bank) {
        return DropdownMenuItem<String>(
          value: bank["id"].toString(),
          child: Text(bank["bank"] ?? "Unknown"),
        );
      }).toList();

      documentTypeItems = documentTypes.map((doc) {
        return DropdownMenuItem<String>(
          value: doc["id"].toString(),
          child: Text(doc["name"] ?? "Unknown"),
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching data: $e");
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading data")),
      );
      return;
    }

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    width: 353,
                    height: 825,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xffd9d9d9).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.black),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            value: selectedBank,
                            items: bankItems,
                            onChanged: (value) {
                              setState(() {
                                selectedBank = value;
                              });
                            },
                            placeholder: "Bank",
                            errorMessage: errorMessages["bank"],
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            value: selectedDocument,
                            items: documentTypeItems,
                            onChanged: (value) {
                              setState(() {
                                selectedDocument = value;
                              });
                            },
                            placeholder: "Document Type",
                            errorMessage: errorMessages["document"],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: referenceController,
                            placeholder: "Ref No",
                            errorMessage: errorMessages["reference"],
                          ),
                          const SizedBox(height: 10),
                          _buildDatePickerField(
                            context,
                            dateController,
                            errorMessage: errorMessages["date"],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: amountController,
                            placeholder: "Amount",
                            isNumeric: true,
                            errorMessage: errorMessages["amount"],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            // width: 200,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await _pickFile(
                                          true); // Upload Payment Receipt
                                      setState(
                                          () {}); // Ensure UI updates immediately
                                    },
                                    label: const Text(
                                      "Upload Payment Receipt",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff84A441),
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.upload,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        10), // Add space between button and icon
                                if (paymentReceiptsBase64 !=
                                    null) // Show immediately after upload
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye,
                                        color: Color(0xff84A441)),
                                    onPressed: () => _viewFile(
                                        paymentReceiptsBase64!,
                                        paymentFileType),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      errorMessages["bank"] =
                                          selectedBank == null
                                              ? "Please select a bank"
                                              : null;
                                      errorMessages["document"] =
                                          selectedDocument == null
                                              ? "Please select a document type"
                                              : null;
                                      errorMessages["reference"] =
                                          referenceController.text.isEmpty
                                              ? "Reference number is required"
                                              : null;
                                      errorMessages["date"] =
                                          dateController.text.isEmpty
                                              ? "Date is required"
                                              : null;
                                      errorMessages["amount"] =
                                          amountController.text.isEmpty
                                              ? "Amount is required"
                                              : null;
                                      errorMessages["receipt"] =
                                          (paymentReceiptsBase64 == null)
                                              ? "Upload a payment receipt"
                                              : null;
                                    });

                                    // If any validation fails, stop here
                                    if (errorMessages.values
                                        .any((msg) => msg != null)) {
                                      debugPrint(
                                          "Validation failed: $errorMessages");
                                      return;
                                    }

                                    double enteredAmount = double.tryParse(
                                            amountController.text) ??
                                        0.0;

                                    var bankData = banks.firstWhere(
                                      (bank) =>
                                          bank["id"].toString() == selectedBank,
                                      orElse: () => {},
                                    );
                                    String bankName =
                                        bankData["bank"] ?? "Unknown";
                                    String accountNumber =
                                        bankData["account_number"] ?? "N/A";

                                    var documentData = documentTypes.firstWhere(
                                      (doc) =>
                                          doc["id"].toString() ==
                                          selectedDocument,
                                      orElse: () => {},
                                    );
                                    String documentTypeName =
                                        documentData["name"] ?? "Unknown";

                                    Map<String, String> newPayment = {
                                      "bank_name": bankName,
                                      "account_number": accountNumber,
                                      "document_type": documentTypeName,
                                      "payment_receipt": paymentReceiptsBase64!,
                                      "reference_number":
                                          referenceController.text,
                                      "date": dateController.text,
                                      "amount": amountController.text,
                                    };

                                    setState(() {
                                      if (editPayment != null &&
                                          index != null) {
                                        payments[index] = newPayment;
                                      } else {
                                        payments.add(newPayment);
                                      }

                                      remainingAmount -= enteredAmount;
                                      amount =
                                          "Remaining Amount: ${remainingAmount.toStringAsFixed(2)}";
                                    });

                                    debugPrint("Saved Payment: $newPayment");
                                    debugPrint(
                                        "Updated Payments List: $payments");

                                    // Close the dialog AFTER ensuring the data is saved
                                    Future.delayed(
                                        const Duration(milliseconds: 300), () {
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context).pop();
                                      refreshReservations();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff84A441),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Save",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text("Cancel",
                                      style: TextStyle(
                                          color: const Color(0xff000000)
                                              .withOpacity(0.37))),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5, // Simulate 5 items
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  void showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this payment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                payments.removeAt(index);
              });
              Navigator.pop(context);
              showSuccessDialog("Payment deleted successfully!");
            },
            child:
                const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? value,
    required String placeholder,
    String? errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 293,
            height: 52,
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                hintText: placeholder,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: Colors.white,
              menuMaxHeight: 250,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String placeholder,
    required TextEditingController controller,
    bool isNumeric = false,
    String? errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) // Show error above the field
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Container(
          width: 293,
          height: 49,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: placeholder,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            ),
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
      BuildContext context, TextEditingController controller,
      {String? errorMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Container(
          width: 293,
          height: 49,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: "Transaction Date",
              suffixIcon: Icon(Icons.calendar_today),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                String formattedDate =
                    "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                controller.text = formattedDate;
              }
            },
          ),
        ),
      ],
    );
  }
}
