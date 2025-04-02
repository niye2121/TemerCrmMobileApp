import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';
import 'package:file_picker/file_picker.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  // ignore: library_private_types_in_public_api
  _ReservationDetailScreenState createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? reservation;
  bool isLoading = true;
  String errorMessage = '';
  late TabController _tabController;
  String amount = "";
  double expectedAmount = 0;
  double remainingAmount = 0;
  bool showInsufficientMessage = false;
  bool isAmountSufficient = false;
  String fetchedName = "";
  String requestLetterFileType = "";
  String paymentFileType = "";
  String? selectedProperty;
  String? selectedReservationType;
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> reservationTypes = [];
  List<Map<String, String>> payments = [];
  bool paymentRequired = false;
  Map<String, dynamic>? selectedReservation;
  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> documentTypes = [];
  String? requestLetterBase64;
  String? paymentReceiptsBase64;
  double? totalPaidAmount;
  DateTime? _selectedNewDate;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newDateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  String? _errorMessage;
  bool isDraft = false;
  bool showTransferForm = false;
  bool showExtensionForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    fetchReservationDetail().then((_) => fetchData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final propertiesData = await ApiService().fetchPropertiesData();
      final reservationData = await ApiService().fetchReservationTypes();
      final banksData = await ApiService().fetchBanks();
      final documentTypesData = await ApiService().fetchDocumentTypes();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? registeredSites = reservation?["site"]["name"];

      debugPrint("registeredSites: $registeredSites");

      fetchedName = prefs.getString("name") ?? "";

      if (registeredSites != null) {
        properties = propertiesData
            .where((prop) =>
                prop.containsKey("site") &&
                registeredSites.contains(prop["site"].toString()) &&
                prop["state"] == "available")
            .toList();
        debugPrint("Properties: $properties");
      } else {
        properties = [];
      }

      debugPrint("Properties in the fetchData: $properties");

      banks = banksData;

      debugPrint('banks updated: $banks');

      documentTypes = documentTypesData;
      reservationTypes = reservationData
          .where((type) => type["is_used_use"] == false)
          .toList();

      setState(() {});

      debugPrint('reservation types in fetchData: $reservationTypes');
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

  Future<void> fetchReservationDetail() async {
    try {
      final data =
          await ApiService().fetchReservationDetail(widget.reservationId);

      if (!mounted) return;

      if (data['data'] == null) {
        setState(() {
          errorMessage = "Failed to load reservation details.";
          isLoading = false;
        });
        return;
      }

      setState(() {
        reservation = data['data'];
        isDraft = reservation!["status"] == "draft";
        isLoading = false;

        int tabCount =
            reservation?["reservation_type"]?["name"] == "Quick Reservation" ||
                    reservation!["status"] == "draft"
                ? 1
                : 3;
        debugPrint("New tab count: $tabCount");
        debugPrint("isDraft: $isDraft");

        debugPrint("reservation site : ${reservation?["site"]["name"]}");

        // Only recreate if the length changes
        if (_tabController.length != tabCount) {
          _tabController.dispose();
          _tabController = TabController(length: tabCount, vsync: this);
          debugPrint("New TabController initialized with length: $tabCount");
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load details: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _pickFile(bool isPaymentReceipt, Function setState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true,
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

      String? fileExtension = result.files.single.extension;
      if (fileExtension == null) {
        debugPrint("Could not determine file extension.");
        return;
      }

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

  void updateReservation() async {
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

  Future<void> showCancellationDialog(BuildContext context) async {
    List<Map<String, dynamic>> cancellationReasons =
        await ApiService().fetchCancellationReasons();

    String selectedReason = cancellationReasons.isNotEmpty
        ? cancellationReasons[0]['id']?.toString() ?? ''
        : '';

    bool confirmCancel = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Cancellation Reason",
          style: TextStyle(
              color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          // Add SingleChildScrollView here
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(4, 4), // Shadow at bottom-right corner
                  blurRadius: 6, // Smooth shadow effect
                ),
              ],
            ),
            child: SizedBox(
              width: 300, // Increased width
              child: DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: cancellationReasons.map((e) {
                  return DropdownMenuItem<String>(
                    value: e['id'].toString(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['bank'] ?? ''),
                        const Divider(), // Adds a line between each option
                      ],
                    ),
                  );
                }).toList(),
                isExpanded: true,
                dropdownColor: Colors.white,
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                onChanged: (String? value) {
                  selectedReason = value ?? selectedReason;
                },
              ),
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Keep buttons in line
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff84A441),
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Yes", style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("No", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (confirmCancel) {
      setState(() => isLoading = true);
      try {
        final response = await ApiService().cancelReservation(
          reservationId: widget.reservationId,
          cancellationReasonId: int.parse(selectedReason),
        );
        if (response["status"] == 200) {
          showSuccessDialog("Successfully Cancelled.");
        } else {
          showErrorDialog("Failed to cancel reservation.");
        }
      } catch (e) {
        showErrorDialog("Error canceling reservation: $e");
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isQuickReservation =
        reservation?["reservation_type"]?["name"] == "Quick Reservation";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservation == null
              ? const Center(
                  child: Text("Failed to load reservation details.",
                      style: TextStyle(color: Colors.red)))
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 70),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Spacer(),
                              const Text(
                                "Reservation Details",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.house,
                                        color: Color(0xff84A441), size: 30),
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
                                    icon: const Icon(Icons.logout,
                                        color: Color(0xff84A441), size: 30),
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
                          const SizedBox(height: 10),
                          Container(
                            height: 25,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xff84A441).withOpacity(0.29),
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Container(
                          if (reservation != null &&
                              reservation!["status"] != "pending_sales" &&
                              reservation!["status"] != "expired" &&
                              reservation!["status"] != "canceled")
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      showCancellationDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffd9d9d9)
                                        .withOpacity(0.29),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Cancel Reservation",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),

                          // ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Column(
                              children: [
                                if (!isDraft)
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: Colors.black,
                                    indicatorColor: Colors.green,
                                    tabs: [
                                      const Tab(
                                        child: Text(
                                          "Reservation\nDetail",
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      if (!isQuickReservation &&
                                          reservation!["status"] == "reserved")
                                        const Tab(text: "Transfer"),
                                      if (!isQuickReservation &&
                                          reservation!["status"] == "reserved")
                                        const Tab(text: "Extension"),
                                    ],
                                  ),
                                Expanded(
                                  child: isDraft
                                      ? buildReservationForm()
                                      : TabBarView(
                                          controller: _tabController,
                                          children: [
                                            _buildReservationDetailTab(),
                                            if (!isQuickReservation &&
                                                reservation!["status"] ==
                                                    "reserved")
                                              _buildTransferTab(),
                                            if (!isQuickReservation &&
                                                reservation!["status"] ==
                                                    "reserved")
                                              _buildExtensionTab(),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget buildReservationForm() {
    // Fetch existing dropdown options
    List<String> propertyNames =
        properties.map((prop) => prop['name'].toString()).toList();
    List<String> reservationTypeNames =
        reservationTypes.map((type) => type['name'].toString()).toList();

    debugPrint('Properties List: $properties');
    debugPrint('Reservation Types List: $reservationTypes');

    if (reservation != null) {
      selectedProperty = reservation!["property"]["name"];
      debugPrint('Selected Property: $selectedProperty');
      debugPrint(
          'Properties List: ${properties.map((prop) => prop['name']).toList()}');

      selectedReservationType = reservation!["reservation_type"]["name"];
      debugPrint('Selected Reservation Type: $selectedReservationType');
      debugPrint(
          'Reservation Types List: ${reservationTypes.map((type) => type['name']).toList()}');

      // Append selected property to the dropdown options if not already present
      if (!propertyNames.contains(selectedProperty)) {
        propertyNames.add(selectedProperty!); // Append instead of insert
      }

      // Append selected reservation type to the dropdown options if not already present
      if (!reservationTypeNames.contains(selectedReservationType)) {
        reservationTypeNames
            .add(selectedReservationType!); // Append instead of insert
      }

      endDateController.text = reservation!["expire_date"] ?? "";
      requestLetterBase64 = reservation!["request_letter"];
      payments = (reservation!["payment_lines"] ?? [])
          .map<Map<String, String>>((payment) {
        final bankName =
            payment['bank_name'] ?? payment['bank_id']?['bank'] ?? 'Unknown';

        return {
          "bank_name": bankName.toString(),
          "account_number": (payment['account_number'] ?? '').toString(),
          "document_type":
              (payment['document_type_id']['bank'] ?? '').toString(),
          "reference_number": (payment['ref_number'] ?? '').toString(),
          "date": (payment['transaction_date'] ?? '').toString(),
          "amount": (payment['amount'] ?? '').toString(),
        };
      }).toList();
    }

    debugPrint("Remaining Amount: $remainingAmount");
    debugPrint("Amount: $amount");

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
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
                  // Use the updated propertyNames list for the dropdown
                  _buildDropdownField(
                      "Property", propertyNames, selectedProperty, (value) {
                    setState(() {
                      selectedProperty = value;
                    });
                  }, width: 293),
                  const SizedBox(height: 15),
                  // Use the updated reservationTypeNames list for the dropdown
                  _buildDropdownField("Reservation Type", reservationTypeNames,
                      selectedReservationType, onReservationTypeChanged,
                      width: 293),
                  const SizedBox(height: 15),
                  _buildDisabledField("End Date:", endDateController),
                  if (selectedReservationType == "special") ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _pickFile(false, setState);
                              },
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
                          if (requestLetterBase64 != null)
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
                  // if (paymentRequired) ...[
                  const SizedBox(height: 10),
                  _buildButton(
                    "Add Payment",
                    const Color(0xff84A441),
                    200,
                    49,
                    () {
                      showPaymentPopup(context, () {
                        setState(() {});
                      });
                    },
                  ),
                  // ],
                  if (payments.isNotEmpty)
                    SizedBox(
                      height: 150,
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
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xff84A441)),
                                    onPressed: () {
                                      showPaymentPopup(
                                          context, () => setState(() {}),
                                          editPayment: payment, index: index);
                                    },
                                  ),
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
                          updateReservation),
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

  // 🟢 Reservation Details Tab
  Widget _buildReservationDetailTab() {
    bool isQuickReservation =
        reservation!["reservation_type"]?["name"] == "Quick Reservation";
    bool isRequested = reservation!["status"] == "requested";
    bool isDraft = reservation!["status"] == "draft";
    bool isReserved = reservation!["status"] == "reserved";

    bool expectedAmount = reservation!["expected_amount"] > 0;

    bool showReserveButton = isQuickReservation && isRequested;
    bool showAddPaymentButton =
        (isDraft || isRequested || isReserved) && expectedAmount;

    debugPrint("isQuickReservation: $isQuickReservation");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("Property", reservation!["property"]?["name"]),
          _buildDetailRow("Customer", reservation!["customer"]?["name"]),
          _buildDetailRow("Status", reservation!["status"]),
          _buildDetailRow(
              "Expected Amount", reservation!["expected_amount"].toString()),
          _buildDetailRow("Expire Date", reservation!["expire_date"]),
          const SizedBox(height: 16),
          if (showReserveButton || showAddPaymentButton)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0, left: 15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (showReserveButton)
                      ElevatedButton(
                        onPressed: () async {
                          int? reservationTypeId = reservation!["id"];

                          if (reservationTypeId == null ||
                              reservationTypeId <= 0) {
                            showErrorDialog(
                                "Invalid reservation type selection. Please try again.");
                            return;
                          }

                          try {
                            setState(() => isLoading = true);

                            // Call API using reservation type ID
                            Map<String, dynamic> reservationResponse =
                                await ApiService()
                                    .reserveItem(reservationTypeId);

                            debugPrint(
                                "Reservation Response: $reservationResponse");

                            // Display the message received from the API
                            if (reservationResponse["status"] == 200) {
                              String message = reservationResponse[
                                  "massage"]; // Retrieve message
                              showSuccessDialog(
                                  message); // Display success dialog
                            } else {
                              showErrorDialog(
                                  "Reservation failed. Please try again.");
                            }
                          } catch (e) {
                            showErrorDialog("Error reserving item: $e");
                          } finally {
                            setState(() => isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff84A441),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.33),
                          ),
                        ),
                        child: const Text("Reserve",
                            style: TextStyle(color: Colors.white)),
                      ),
                    if (showReserveButton && showAddPaymentButton)
                      const SizedBox(width: 10),
                    if (showAddPaymentButton)
                      ElevatedButton(
                        onPressed: () {
                          showPaymentPopup(context, () {
                            setState(() {});
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff84A441),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.33),
                          ),
                        ),
                        child: const Text("Add Payment",
                            style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Fetched Reservation Payment Details (Non-Editable)
          _buildFetchedPaymentDetails(),
          const SizedBox(height: 16),
          // Newly Added Payment Details (Editable)
          _buildPaymentDetails(),
        ],
      ),
    );
  }

  Widget _buildFetchedPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Details:",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C4C4C),
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(reservation!["payment_lines"].length, (index) {
          var payment = reservation!["payment_lines"][index];
          return Card(
            color: Colors.white,
            elevation:
                3, // Adds subtle shadow for better focus on payment details
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: IconButton(
                icon:
                    const Icon(Icons.remove_red_eye, color: Color(0xff84A441)),
                onPressed: () {
                  _showDecodedReceipt(payment["payment_receipt"]);
                },
              ),
              title: Text("Amount: ${payment["amount"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: isDraft
                  ? Text("Date: ${payment["date"] ?? 'Not Available'}",
                      style: const TextStyle(fontSize: 14))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Bank: ${payment["bank_id"]["bank"] ?? 'Not Available'}",
                            style: const TextStyle(fontSize: 14)),
                        Text(
                            "Document Type: ${payment["document_type_id"]["bank"] ?? 'Not Available'}",
                            style: const TextStyle(fontSize: 14)),
                        Text(
                            "Reference Number: ${payment["ref_number"] ?? 'Not Available'}",
                            style: const TextStyle(fontSize: 14)),
                        Text(
                            "Date: ${payment["transaction_date"] ?? 'Not Available'}",
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    bool hasNewPayment = payments.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ...List.generate(payments.length, (index) {
            var payment = payments[index];
            return Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align icons at the top
                  children: [
                    // Icon column aligned at the top
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye,
                              color: Color(0xff84A441)),
                          onPressed: () =>
                              _showDecodedReceipt(payment["payment_receipt"]!),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Color(0xff84A441)),
                          onPressed: () {
                            showPaymentPopup(context, () => setState(() {}),
                                editPayment: payment, index: index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Color(0xff84A441)),
                          onPressed: () =>
                              showDeleteConfirmation(context, index),
                        ),
                      ],
                    ),
                    const SizedBox(
                        width: 10), // Add some space between the icons and text
                    // Expanded for the title and subtitle to take the remaining space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Amount: ${payment["amount"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "Bank: ${payment["bank_name"] ?? 'Not Available'}"),
                          Text(
                              "Doc Type: ${payment["document_type"] ?? 'Not Available'}"),
                          Text(
                              "Ref No: ${payment["reference_number"] ?? 'Not Available'}"),
                          Text("Date: ${payment["date"] ?? 'Not Available'}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (hasNewPayment)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (payments.isEmpty) {
                        showErrorDialog("No new payment to save.");
                        return;
                      }
                      try {
                        setState(() => isLoading = true);
                        List<Map<String, dynamic>> existingPayments =
                            List.from(reservation!["payment_lines"]);
                        List<Map<String, dynamic>> newPayments =
                            payments.map((payment) {
                          var docType = documentTypes.firstWhere(
                            (doc) => doc["name"] == payment["document_type"],
                            orElse: () =>
                                {"id": 0, "bank": "Unknown Document Type"},
                          );
                          var bank = banks.firstWhere(
                            (bank) =>
                                bank["bank"].trim().toLowerCase() ==
                                payment["bank_name"]!.trim().toLowerCase(),
                            orElse: () => {"id": 0, "bank": "Unknown Bank"},
                          );
                          return {
                            "document_type_id": {
                              "id": docType["id"],
                              "bank": docType["name"]
                            },
                            "bank_id": {"id": bank["id"], "bank": bank["bank"]},
                            "payment_receipt": payment["payment_receipt"],
                            "ref_number": payment['reference_number'],
                            "transaction_date": payment['date'],
                            "amount": int.parse(payment['amount']!),
                            "is_verified": false,
                          };
                        }).toList();
                        List<Map<String, dynamic>> updatedPaymentLines = [
                          ...existingPayments,
                          ...newPayments
                        ];
                        Map<String, dynamic> requestBody = {
                          "id": reservation!["id"],
                          "property_id": reservation!["property"]["id"],
                          "partner_id": reservation!["customer"]["id"],
                          "reservation_type_id":
                              reservation!["reservation_type"]["id"],
                          "expire_date": reservation!["expire_date"],
                          "payment_line_ids": updatedPaymentLines,
                        };
                        Map<String, dynamic> response =
                            await ApiService().updateReservation(requestBody);
                        if (response["status"] == 200) {
                          showSuccessDialog(
                              "Reservation updated successfully.");
                          setState(() {
                            payments.clear();
                            reservation!["payment_lines"] = updatedPaymentLines;
                          });
                        } else {
                          showErrorDialog(response["error"] ??
                              "Failed to update reservation.");
                        }
                      } catch (e) {
                        showErrorDialog("Error updating reservation: $e");
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff84A441),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.33)),
                    ),
                    child: const Text("Update",
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showSuccessDialog("Payment Cancelled!");
                      setState(() => payments.clear());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.33)),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C4C4C),
            ),
          ),
          Text(
            value ?? "N/A",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6A6A6A), // Slightly gray text for less emphasis
            ),
          ),
        ],
      ),
    );
  }

  void _showDecodedReceipt(String encodedData) async {
    try {
      // Step 1: First Decode
      String firstDecoded = utf8.decode(base64.decode(encodedData));

      // Step 2: Second Decode to get original file data
      Uint8List fileBytes = base64.decode(firstDecoded);

      // Step 3: Determine file type dynamically
      String? fileType = _detectFileType(fileBytes);

      if (fileType == "png" || fileType == "jpg" || fileType == "jpeg") {
        // Show Image Preview
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Receipt Preview"),
              content: Image.memory(fileBytes),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      } else if (fileType == "pdf") {
        // Save & Open PDF
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/receipt.pdf";
        File(filePath).writeAsBytesSync(fileBytes);

        OpenFile.open(filePath);
      } else {
        // Unknown file type
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Unsupported File"),
              content: const Text("Cannot preview this file type."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Error decoding file: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error displaying receipt: $e")),
      );
    }
  }

// 🛠 **Helper Function: Detect File Type**
  String? _detectFileType(Uint8List bytes) {
    if (bytes.length > 4) {
      // JPEG / JPG files start with FF D8 FF E0 or FF D8 FF E1
      debugPrint("Checking for JPEG/JPG...");
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        debugPrint("Detected JPEG/JPG");
        return "jpeg"; // Covers both JPG & JPEG
      }
      // PNG files start with 89 50 4E 47
      else if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        debugPrint("Detected PNG");
        return "png";
      }
      // PDF files start with 25 50 44 46
      else if (bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        debugPrint("Detected PDF");
        return "pdf";
      }
    }
    debugPrint("Unknown file format detected.");
    return null; // Unknown file format
  }

  void updateAmount() async {
    debugPrint("update Amount triggered");
    if (selectedProperty != null) {
      int? propertyId = properties.firstWhere(
        (prop) => prop['name'] == selectedProperty,
        orElse: () => {'id': null},
      )['id'];

      if (propertyId != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? customerId = prefs.getInt("partner_id");

        if (customerId == null) {
          setState(() {
            amount = "Customer ID not found";
          });
          return;
        }

        try {
          var response = await ApiService().checkAmount(
              customerId, reservation!["reservation_type"]["id"], propertyId);

          debugPrint("response in check amount: $response");

          if (response.containsKey("data") &&
              response["data"].containsKey("expected")) {
            double fetchedAmount =
                double.parse(response["data"]["expected"].toString());

            double totalPaid = reservation!["payment_lines"].fold(
                0.0, (sum, item) => sum + (item["amount"] as num).toDouble());

            setState(() {
              expectedAmount = fetchedAmount;
              totalPaidAmount = totalPaid;
              remainingAmount = expectedAmount - totalPaidAmount!;
              isAmountSufficient = remainingAmount <= 0;
              debugPrint("remaining Amount: $remainingAmount");
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

  Widget _buildTransferTab() {
    bool hasExistingTransfers = reservation?["transfers"]?.isNotEmpty ?? false;
    double totalPaid = 0.0;
    List<Map<String, dynamic>> transfers =
        List<Map<String, dynamic>>.from(reservation?["transfers"] ?? []);

    // Calculate the total paid amount for each transfer
    if (hasExistingTransfers) {
      totalPaid = transfers.fold(0.0, (sum, transfer) {
        return sum +
            (transfer["payment_lines"]
                    ?.map((p) => (p["amount"] as num).toDouble())
                    ?.fold(0.0, (prev, amount) => prev + amount) ??
                0.0);
      });
    } else {
      totalPaid = reservation!["payment_lines"]
              ?.map((p) => (p["amount"] as num).toDouble())
              ?.fold(0.0, (prev, amount) => prev + amount) ??
          0.0;
    }

    debugPrint("remaining amount in transfer tab: $remainingAmount");
    debugPrint("total paid amount in transfer tab: $totalPaid");

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showTransferForm = !showTransferForm;

                      if (showTransferForm) {
                        selectedProperty = null;
                        requestLetterBase64 = null;
                        payments.clear();
                        remainingAmount = 0.0;
                        amount = "0.0";
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff84A441),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    showTransferForm ? "Hide Form" : "Add New Transfer",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (!hasExistingTransfers || showTransferForm)
                  Column(
                    children: [
                      if (remainingAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Insufficient amount. Remaining balance: $remainingAmount",
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _buildInfoRow("Reservation",
                          reservation!["reservation_type"]?["name"] ?? "N/A"),
                      const SizedBox(height: 10),
                      _buildInfoRow("Old Property",
                          reservation!["property"]?["name"] ?? "N/A"),
                      const SizedBox(height: 10),
                      _buildDropdownField(
                        "Transfer to Property",
                        properties
                            .map((prop) => prop['name'].toString())
                            .toList(),
                        selectedProperty,
                        (value) {
                          setState(() {
                            selectedProperty = value;
                            updateAmount();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow("Total Paid", "$totalPaid"),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _pickFile(false, setState);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff84A441),
                                minimumSize: const Size(190, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Upload Request Letter",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          if (requestLetterBase64 != null)
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye,
                                  color: Color(0xff84A441)),
                              onPressed: () => _viewFile(
                                  requestLetterBase64!, requestLetterFileType),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (remainingAmount > 0)
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
                      const SizedBox(height: 10),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Acct No: ${payment['account_number']}"),
                                      Text("Doc: ${payment['document_type']}"),
                                      Text(
                                          "Ref: ${payment['reference_number']}"),
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
                                              editPayment: payment,
                                              index: index);
                                        },
                                      ),
                                      // Delete Button
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Color(0xff84A441)),
                                        onPressed: () {
                                          showDeleteConfirmation(
                                              context, index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildButton(isLoading ? "Saving..." : "Save",
                              const Color(0xff84A441), 129, 54, () async {
                            if (selectedProperty == null ||
                                requestLetterBase64 == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please complete all required fields")),
                              );
                              return;
                            }

                            // Get IDs for the old and new property
                            int oldPropertyId = reservation!["property"]["id"];
                            int newPropertyId = properties.firstWhere(
                              (prop) => prop['name'] == selectedProperty,
                              orElse: () => {"id": -1},
                            )['id'];

                            if (newPropertyId == -1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Invalid property selection")),
                              );
                              return;
                            }

                            setState(() {
                              isLoading = true;
                            });

                            final formattedPayments = payments
                                .map((payment) => {
                                      "document_type_id":
                                          documentTypes.firstWhere(
                                        (doc) =>
                                            doc["name"] ==
                                            payment["document_type"],
                                        orElse: () => {"id": 0},
                                      )["id"],
                                      "bank_id": banks.firstWhere(
                                          (bank) =>
                                              bank["bank"]
                                                  .trim()
                                                  .toLowerCase() ==
                                              payment["bank_name"]!
                                                  .trim()
                                                  .toLowerCase(), orElse: () {
                                        debugPrint(
                                            "No matching bank found for '${payment['bank_name']}'");
                                        return {"id": 0};
                                      })["id"],
                                      "payment_receipt":
                                          payment["payment_receipt"],
                                      "ref_number": payment['reference_number'],
                                      "transaction_date": payment['date'],
                                      "amount": int.parse(payment['amount']!),
                                    })
                                .toList();

                            // Call API
                            final response = await ApiService().createTransfer(
                              reservationId: reservation!["id"],
                              oldPropertyId: oldPropertyId,
                              newPropertyId: newPropertyId,
                              requestLetterBase64: requestLetterBase64!,
                              payments: formattedPayments,
                            );

                            setState(() {
                              isLoading = false;

                              if (response["result"]?["status"] == 200 ||
                                  response["result"]?["status"] == 201) {
                                showSuccessDialog(response["result"]
                                        ?["message"] ??
                                    "Success");
                              } else {
                                String errorMessage = response["result"]
                                        ?["error"] ??
                                    "Unknown error occurred";
                                showErrorDialog(errorMessage);
                              }
                            });
                          }),
                          _buildButton(
                              "Discard",
                              const Color(0xff000000).withOpacity(0.37),
                              129,
                              54, () {
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                if (hasExistingTransfers)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display each existing transfer as a card
                      ...transfers.map((transfer) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.swap_horiz,
                                        color: Color(0xff84A441)),
                                    SizedBox(width: 8),
                                    Text(
                                      "Existing Transfer",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(thickness: 1, color: Colors.grey),
                                const SizedBox(height: 8),
                                _buildDetailRow("Old Property",
                                    transfer["old_property"]["name"]),
                                _buildDetailRow("New Property",
                                    transfer["new_property"]["name"]),
                                _buildDetailRow("Status", transfer["status"]),
                                _buildDetailRow(
                                    "Total Paid", "${transfer["total_paid"]}"),
                                if (transfer["request_letter"] != null)
                                  TextButton.icon(
                                    onPressed: () =>
                                    _viewTransferRequestLetter(transfer["request_letter"]),
                                        // _viewExtensionRequestLetter(
                                        //     transfer["request_letter"]),
                                    icon: const Icon(Icons.visibility,
                                        color: Color(0xff84A441)),
                                    label: const Text(
                                        "View Transfer Request Letter",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xff84A441),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
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
              setState(() {
                fetchReservationDetail();
                fetchData();
              });
            },
            child: const Text("OK",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
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

  Widget _buildInfoRow(String label, String value, {double width = 293}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xffd9d9d9),
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black,
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
        return const Center(
          child: CircularProgressIndicator(),
        );
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
                                      await _pickFile(true,
                                          setState); // Pass setState from the StatefulBuilder
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

  Widget _buildExtensionTab() {
    DateTime oldExpireDate = DateTime.parse(reservation!["expire_date"]);
    bool hasExistingExtension = reservation?["extensions"]?.isNotEmpty ?? false;

    if (!hasExistingExtension) {
      showExtensionForm = true;
    }

    debugPrint("hasExistingExtension: $hasExistingExtension");

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showExtensionForm = !showExtensionForm;

                      if (showExtensionForm) {
                        _newDateController.clear();
                        _selectedNewDate = null;
                        _errorMessage = null;
                        _noteController.clear();
                        requestLetterBase64 = null;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff84A441),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    showExtensionForm ? "Hide Form" : "Request New Extension",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                if (showExtensionForm) ...[
                  _buildInfoRow("Old Expire Date", reservation!["expire_date"]),
                  const SizedBox(height: 10),

                  _buildExtensionDatePickerField(
                    context,
                    _newDateController,
                    errorMessage: _errorMessage,
                    oldExpireDate: oldExpireDate,
                    onDatePicked: (DateTime pickedDate) {
                      setState(() {
                        if (pickedDate.isAfter(oldExpireDate)) {
                          _selectedNewDate = pickedDate;
                          _errorMessage = null;
                        } else {
                          _errorMessage =
                              "New date must be after old expire date.";
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  /// Upload Request Letter Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _pickFile(false,
                            setState); // Pass setState from the StatefulBuilder
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff84A441),
                        minimumSize: const Size(190, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Upload request Letter",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// Remarks Text Field
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Remarks",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 50),

                  /// Save and Discard Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildButton(isLoading ? "Saving..." : "Save",
                            const Color(0xff84A441), 100, 50, () async {
                          if (_selectedNewDate == null ||
                              _selectedNewDate!.isBefore(oldExpireDate)) {
                            setState(() {
                              _errorMessage = "Please select a valid date.";
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true; // Start loading
                          });

                          var response = await ApiService().createExtension(
                            reservationId: reservation!["id"],
                            requestedDate: _selectedNewDate!,
                            oldEndDate: oldExpireDate,
                            requestLetter: requestLetterBase64!,
                            remarks: _noteController.text,
                          );

                          setState(() {
                            isLoading = false;

                            if (response["result"]?["status"] == 200 ||
                                response["result"]?["status"] == 201) {
                              showSuccessDialog(
                                  response["result"]?["message"] ?? "Success");
                            } else {
                              String errorMessage = response["result"]
                                      ?["error"] ??
                                  "Unknown error occurred";
                              showErrorDialog(errorMessage);
                            }
                          });
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildButton(
                          "Discard",
                          const Color(0xff000000).withOpacity(0.37),
                          100,
                          50,
                          () {
                            Navigator.pop(context);
                            setState(() {
                              showExtensionForm = true;
                              _newDateController.clear();
                              _selectedNewDate = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                if (hasExistingExtension) ...[
                  /// Show Existing Extensions
                  ...reservation!["extensions"].map<Widget>((extension) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.event, color: Color(0xff84A441)),
                                SizedBox(width: 8),
                                Text(
                                  "Extension Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(thickness: 1, color: Colors.grey),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                                "Old Expire Date", extension["old_end_date"]),
                            _buildDetailRow(
                                "Extension Date", extension["extension_date"]),
                            _buildDetailRow("Request Date", extension["date"]),
                            _buildDetailRow("Status", extension["status"]),
                            const SizedBox(height: 8),
                            if (extension["request_letter"] != null)
                              TextButton.icon(
                                onPressed: () {
                                  debugPrint("View Request Letter Pressed");
                                  _viewExtensionRequestLetter(
                                      extension["request_letter"]);
                                },
                                icon: const Icon(Icons.visibility,
                                    color: Color(0xff84A441)),
                                label: const Text("View Request Letter",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xff84A441),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewExtensionRequestLetter(String base64Data) async {
    debugPrint("View Request Letter Pressed");
    debugPrint("view triggered");
    debugPrint(
        "Base64 Data (First 50 chars): ${base64Data.substring(0, 50)}...");

    if (base64Data.isEmpty) {
      debugPrint("Base64 data is empty. Exiting.");
      return;
    }

    try {
      // First Decode: Base64 -> UTF-8 String (first decoding)
      String firstDecodedString = utf8.decode(base64Decode(base64Data));
      debugPrint(
          "First Decoded String (UTF-8, First 50 chars): ${firstDecodedString.substring(0, 50)}...");

      // Second Decode: Checking for any base64 structure in the decoded string
      String secondDecodedBase64String = firstDecodedString;
      if (_isBase64(secondDecodedBase64String)) {
        // If the second decoding is valid base64, decode it
        secondDecodedBase64String =
            utf8.decode(base64Decode(secondDecodedBase64String));
        debugPrint(
            "Second Decoded Base64 String (First 50 chars): ${secondDecodedBase64String.substring(0, 50)}...");
      } else {
        debugPrint("No additional base64 encoding found.");
      }

      // Third Decode: Base64 to Bytes (final decoding)
      Uint8List finalDecodedBytes = base64Decode(secondDecodedBase64String);
      debugPrint("Decoded Bytes Length: ${finalDecodedBytes.length}");

      // Detect file type
      String? fileType = _detectFileType(finalDecodedBytes);
      debugPrint("Detected file type: $fileType");

      if (fileType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unsupported or unknown file format")),
        );
        return;
      }

      // Save file to temporary storage
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/temp_file.$fileType";
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(finalDecodedBytes);

      // Handle different file types
      if (fileType == "jpg" || fileType == "jpeg" || fileType == "png") {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Uploaded File"),
            content: Image.memory(finalDecodedBytes),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      } else if (fileType == "pdf") {
        OpenFile.open(tempPath);
      }
    } catch (e) {
      debugPrint("Error decoding file: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error decoding file")),
        );
      }
    }
  }

// Utility to check if a string is base64 encoded
  bool _isBase64(String str) {
    final base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Regex.hasMatch(str);
  }

  void _viewTransferRequestLetter(String base64Data) async {
  if (base64Data.isEmpty) return;

  try {
    // Decode the first layer of base64
    String firstDecodedString = utf8.decode(base64Decode(base64Data));

    // Decode the second layer of base64 (as the base64 string might be base64 encoded again)
    Uint8List decodedBytes = base64Decode(firstDecodedString);

    // Detect file type (JPEG, PNG, PDF, etc.)
    String? fileType = _detectFileType(decodedBytes);

    if (fileType == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unsupported or unknown file format")),
      );
      return;
    }

    // Get the temporary directory path
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = "${tempDir.path}/temp_file.$fileType";

    // Create a temporary file and write the decoded bytes to it
    File tempFile = File(tempPath);
    await tempFile.writeAsBytes(decodedBytes);

    // Check if the widget is still mounted before showing the dialog
    if (!context.mounted) return;

    // Show the dialog based on the file type (JPEG/JPG, PNG, or PDF)
    if (fileType == "jpeg" || fileType == "jpg" || fileType == "png") {
      Future.delayed(const Duration(milliseconds: 100), () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Uploaded File"),
            content: Image.memory(decodedBytes),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      });
    } else if (fileType == "pdf") {
      OpenFile.open(tempPath);
    }
  } catch (e) {
    debugPrint("Error decoding file: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error decoding file")),
      );
    }
  }
}

  Widget _buildExtensionDatePickerField(
    BuildContext context,
    TextEditingController controller, {
    required DateTime oldExpireDate,
    String? errorMessage,
    required Function(DateTime) onDatePicked,
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
          width: 293,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: "Select New Expiry Date",
              suffixIcon: Icon(Icons.calendar_today, color: Colors.green),
              border: InputBorder.none,
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: oldExpireDate
                    .add(const Duration(days: 1)), // One day after old date
                firstDate: oldExpireDate
                    .add(const Duration(days: 1)), // Restrict to future
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                controller.text =
                    "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                onDatePicked(pickedDate);
              }
            },
          ),
        ),
      ],
    );
  }
}
