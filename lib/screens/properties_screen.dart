import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PropertiesScreenState createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  List<Map<String, dynamic>> properties = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchProperties();
  }

  Future<void> fetchProperties() async {
    try {
      List<Map<String, dynamic>> fetchedData =
          await ApiService().fetchPropertiesData();
      setState(() {
        properties = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data: $e";
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xff617C28);
      case 'reserved':
        return const Color(0xffE29609);
      case 'sold':
        return const Color(0xffFF3131);
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
                          "Properties",
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
                          icon: const Icon(Icons.logout,
                              color: Color(0xff84A441), size: 30),
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
                          : ListView.builder(
                              itemCount: properties.length,
                              itemBuilder: (context, index) {
                                return _buildPropertyCard(properties[index]);
                              },
                            ),
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
              child: const Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(Icons.search, color: Color(0xFF84A441)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Color(0xff84A441)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.layers, color: Color(0xff84A441)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffD9D9D9).withOpacity(0.5),
        border: Border.all(color: Colors.green.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyDetail("Name", property["name"]),
          Row(
            children: [
              Expanded(
                  child:
                      _buildPropertyDetail("Type", property["property_type"])),
              Expanded(
                  child: _buildPropertyDetail("Status", property["state"],
                      statusColor: _getStatusColor(property["state"]))),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _buildPropertyDetail(
                      "Nt. Area", property["net_area"].toString())),
              if (property["bedroom"] != null)
                Expanded(
                    child: _buildPropertyDetail(
                        "Bedrooms", property["bedroom"].toString())),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _buildPropertyDetail(
                      "Gr. Area", property["gross_area"].toString())),
              if (property["end_date"] != null)
                Expanded(
                    child:
                        _buildPropertyDetail("End Date", property["end_date"])),
            ],
          ),
          _buildPropertyDetail(
              "Reservation", property["reservation_end_date"].toString()),
        ],
      ),
    );
  }

  Widget _buildPropertyDetail(String label, String value,
      {Color? statusColor}) {
    return Container(
      color: const Color(0xffD9D9D9).withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(color: statusColor ?? Colors.black, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Widget _buildPropertyDetail(String label, String value,
  //     {Color? statusColor}) {
  //   return Container(
  //     color: const Color(0xffD9D9D9).withOpacity(0.5),
  //     padding: const EdgeInsets.symmetric(vertical: 2),
  //     child: Row(
  //       children: [
  //         Text(
  //           "$label: ",
  //           style: const TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         Text(
  //           value,
  //           style: TextStyle(color: statusColor ?? Colors.black),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
