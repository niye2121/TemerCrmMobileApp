import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';
// ignore: depend_on_referenced_packages
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PropertiesScreenState createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
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
          await ApiService().fetchPropertiesData();
      setState(() {
        properties = fetchedData;
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
        bool matchesSearch = property.values
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());

        bool matchesFilter = selectedFilter.isEmpty ||
            property['state'] == selectedFilter ||
            property['bedroom'].toString() == selectedFilter;

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
        .map((word) =>
            word[0].toUpperCase() +
            word.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xff84A441).withOpacity(0.34);
      case 'reserved':
        return const Color(0xffE29609).withOpacity(0.28);
      case 'sold':
        return const Color(0xffFF0000).withOpacity(0.69);
      case 'pending_sales':
        return const Color(0xffE29609).withOpacity(0.28);
      default:
        return Colors.black;
    }
  }

  Color _getPropertyTypeColor(String propertyType) {
    switch (propertyType.toLowerCase()) {
      case 'commercial':
        return const Color(0xff000000);
      case 'residential':
        return const Color(0xffA15E1A);
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
            const PopupMenuItem(value: "available", child: Text("Available")),
            const PopupMenuItem(value: "reserved", child: Text("Reserved")),
            const PopupMenuItem(value: "sold", child: Text("Sold")),
            const PopupMenuItem(value: "1", child: Text("1 Bedroom")),
            const PopupMenuItem(value: "2", child: Text("2 Bedroom")),
            const PopupMenuItem(value: "3", child: Text("3 Bedroom")),
            const PopupMenuItem(value: "4", child: Text("4 Bedroom")),
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
            const PopupMenuItem(value: "site", child: Text("Group by Site")),
            const PopupMenuItem(value: "state", child: Text("Group by Status")),
            const PopupMenuItem(value: "property_type", child: Text("Group by Type")),
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
          return _buildPropertyCard(filteredProperties[index]);
        },
      );
    } else {
      Map<String, List<Map<String, dynamic>>> groupedData = {};

      for (var property in filteredProperties) {
        String key = property[selectedGroupBy]?.toString() ?? "Unknown";
        groupedData.putIfAbsent(key, () => []).add(property);
      }

      return ListView(
        children: groupedData.entries.map((entry) {
          String groupName = entry.key;
          List<Map<String, dynamic>> properties = entry.value;
          int totalProperties = properties.length;

          return _buildGroupCard(
              groupName, totalProperties, properties,
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
                      "Total Properties - $totalProperties",
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

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 5),
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
          // Property Name and Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  property["name"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  property["property_type"],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPropertyTypeColor(property["property_type"]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _buildPropertyDetail(
                  "Gr. Area", property["gross_area"].toString()),
              const SizedBox(width: 20),
              _buildPropertyDetail("Nt. Area", property["net_area"].toString()),
              const SizedBox(width: 20),
              Row(
                children: [
                  const Icon(FontAwesomeIcons.bed,
                      size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(property["bedroom"].toString(),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black)),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  const Icon(FontAwesomeIcons.bath,
                      size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(property["bathroom"].toString(),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(property["state"]),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  formatStatus(property["state"]),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (property["reservation_end_date"] != null) ...[
                const SizedBox(width: 20),
                Text(
                  "Res. End Date: ${property["reservation_end_date"]}",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetail(String label, String value) {
    return Row(
      children: [
        Text(
          "$label ",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
