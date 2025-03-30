import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';

class TransferRequestsScreen extends StatefulWidget {
  const TransferRequestsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TransferRequestsScreenState createState() => _TransferRequestsScreenState();
}

class _TransferRequestsScreenState extends State<TransferRequestsScreen> {
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> filteredProperties = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  String selectedFilter = '';
  String selectedGroupBy = '';

  @override
  void initState() {
    super.initState();
    fetchProperties();
  }

  Future<void> fetchProperties() async {
    try {
      List<Map<String, dynamic>> fetchedData =
          await ApiService().fetchMyTransferRequests();
      setState(() {
        properties = fetchedData.map((request) {
          return {
            "id": request["id"],
            "old_property_name": request["old_property_id"]["name"],
            "new_property_name": request["property_id"]["name"],
            "status": request["status"],
            "payment_lines": request["payment_lines"],
          };
        }).toList();
        filteredProperties = properties;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data: $e";
        isLoading = false;
      });
    }
  }

  void filterProperties() {
    setState(() {
      filteredProperties = properties.where((property) {
        bool matchesSearch = property["old_property_name"]
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            property["new_property_name"]
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            property["status"]
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        bool matchesFilter =
            selectedFilter.isEmpty || property["status"] == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void groupByProperty(String key) {
    setState(() {
      selectedGroupBy = key;
    });
  }

  String formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xff84A441).withOpacity(0.34);
      case 'reserved':
        return const Color(0xffE29609).withOpacity(0.28);
      case 'sold':
        return const Color(0xffFF0000).withOpacity(0.69);
      case 'pending':
        return const Color(0xffE29609).withOpacity(0.28);
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAEAEA),
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 70),
                // Existing Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          "My Transfer Requests",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.house,
                              color: Color(0xff84A441), size: 30),
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
                          onPressed: () async {
                            try {
                              await ApiService().logout();
                              Navigator.pushReplacement(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            } catch (e) {
                              // ignore: use_build_context_synchronously
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
                const SizedBox(height: 10),

                // Search and Filter Section
                _buildSearchAndFilter(),
                const SizedBox(height: 10),

                // Green Horizontal Bar
                Container(
                  height: 25, // Adjust height as needed
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xff84A441).withOpacity(0.29),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),

                const SizedBox(height: 10),

                // Property List
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Text(errorMessage,
                                  style: const TextStyle(color: Colors.red)))
                          : _buildGroupedView(),
                ),

                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Powered by Ahadubit Technologies",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 29,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          filterProperties();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Search",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFF84A441)),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Color(0xFF84A441)),
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
                filterProperties();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "", child: Text("All")),
              const PopupMenuItem(value: "pending", child: Text("Pending")),
              const PopupMenuItem(value: "approved", child: Text("Approved")),
              const PopupMenuItem(value: "reserved", child: Text("Reserved")),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers, color: Color(0xFF84A441)),
            onSelected: (value) {
              setState(() {
                groupByProperty(value);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: "status", child: Text("Group by Status")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF84A441)),
            onPressed: () {
              setState(() {
                searchQuery = '';
                selectedFilter = '';
                selectedGroupBy = '';
                filteredProperties = properties; // Reset filter
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedView() {
    if (selectedGroupBy.isEmpty) {
      return ListView.builder(
        itemCount: filteredProperties.length,
        itemBuilder: (context, index) {
          return _buildTransferRequestCard(filteredProperties[index]);
        },
      );
    } else {
      Map<String, List<Map<String, dynamic>>> groupedData = {};

      for (var property in filteredProperties) {
        String key =
            selectedGroupBy == "status" ? property["status"] : "Unknown";
        groupedData.putIfAbsent(key, () => []).add(property);
      }

      return ListView(
        children: groupedData.entries.map((entry) {
          String groupName = entry.key;
          List<Map<String, dynamic>> properties = entry.value;
          int totalProperties = properties.length;

          return _buildGroupCard(groupName, totalProperties, properties,
              groupedData: groupedData);
        }).toList(),
      );
    }
  }

  Map<String, bool> expandedGroups = {};

  Widget _buildGroupCard(
      String group, int totalProperties, List<Map<String, dynamic>> properties,
      {required Map<String, List<Map<String, dynamic>>> groupedData}) {
    Color iconColor = _getStatusColor(group);
    IconData iconData =
        selectedGroupBy == "status" ? Icons.business : Icons.apartment;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            filteredProperties = groupedData[group]!;
            selectedGroupBy = '';
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 115,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(iconData, color: iconColor.withOpacity(0.5), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatStatus(group),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: iconColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Transfer Requests - $totalProperties",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferRequestCard(Map<String, dynamic> request) {
    int totalPaid = request["payment_lines"].fold(0, (sum, item) {
      return sum +
          (item["amount"] is double
              ? (item["amount"] as double).toInt()
              : item["amount"]);
    });

    return GestureDetector(
      onTap: () {
        _showTransferRequestDetails(request);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status (Right Aligned)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(), // Empty space to push status right
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request["status"]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    request["status"].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Old Property
            Row(
              children: [
                const Icon(Icons.home, size: 14, color: Colors.black),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Old: ${request["old_property_name"]}",
                    style: TextStyle(
                        fontSize: 14, color: Colors.black.withOpacity(0.4)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 3: New Property
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.black),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "New: ${request["new_property_name"]}",
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 4: Total Paid Amount
            Row(
              children: [
                const Icon(Icons.attach_money, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  "Total Paid: $totalPaid",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferRequestDetails(Map<String, dynamic> request) {
    int totalPaid = request["payment_lines"].fold(0, (sum, item) {
      return sum +
          (item["amount"] is double
              ? (item["amount"] as double).toInt()
              : item["amount"]);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Status",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request["status"]),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      request["status"].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Old Property
              Text(
                "Old Property: ${request["old_property_name"]}",
                style: TextStyle(
                    fontSize: 14, color: Colors.black.withOpacity(0.4)),
              ),
              const SizedBox(height: 6),

              // New Property
              Text(
                "New Property: ${request["new_property_name"]}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 10),

              // Total Paid
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    "Total Paid: $totalPaid",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Payment Details
              const Text(
                "Payment Details:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Column(
                children:
                    List.generate(request["payment_lines"].length, (index) {
                  var payment = request["payment_lines"][index];
                  return Card(
                    color: Colors.grey[100],
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: Colors.green),
                        onPressed: () {
                          _viewFile(payment[
                              "payment_receipt"]); // Change fileType if needed
                        },
                      ),
                      title: Text("Ref: ${payment["ref_number"]}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Amount: ${payment["amount"]}"),
                          Text("Bank: ${payment["bank_id"]["bank"]}"),
                          Text(
                              "Document Type: ${payment["document_type_id"]["bank"]}"),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              // Close Button
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.33)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close",
                  style: TextStyle(color: Colors.white,),
                ),
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewFile(String base64Data) async {
    if (base64Data.isEmpty) return;

    try {
      // ✅ First Base64 decode
      String firstDecodedString = utf8.decode(base64Decode(base64Data));

      // ✅ Second Base64 decode
      Uint8List decodedBytes = base64Decode(firstDecodedString);

      // ✅ Identify file type from magic bytes
      String fileType = _detectFileType(decodedBytes);

      if (fileType == "unknown") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unsupported or unknown file format")),
        );
        return;
      }

      // Get a temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/temp_file.$fileType";

      // Write the file to a temporary location
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(decodedBytes);

      if (fileType == "jpg" || fileType == "png") {
        // ✅ Display the image in a dialog
        showDialog(
          // ignore: use_build_context_synchronously
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
      } else if (fileType == "pdf") {
        // ✅ Open PDFs using an external viewer
        OpenFile.open(tempPath);
      }
    } catch (e) {
      debugPrint("Error decoding file: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error decoding file")),
      );
    }
  }

  /// Detects the file type based on magic bytes
  String _detectFileType(Uint8List bytes) {
    if (bytes.length < 4) return "unknown"; // Ensure we have enough data

    String hex = bytes
        .sublist(0, 4)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // Known file signatures
    if (hex.startsWith("ffd8ff")) return "jpg"; // JPEG
    if (hex.startsWith("89504e47")) return "png"; // PNG
    if (hex.startsWith("25504446")) return "pdf"; // PDF

    return "unknown"; // If format is not recognized
  }
}
