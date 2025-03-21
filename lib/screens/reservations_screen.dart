import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';

class ReservationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? reservations;

  const ReservationsScreen({super.key, this.reservations});

  @override
  // ignore: library_private_types_in_public_api
  _ReservationsScreenState createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredReservations = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  String selectedFilter = '';
  String selectedGroupBy = '';

  @override
  void initState() {
    super.initState();
    if (widget.reservations != null) {
      data = widget.reservations!;
      filteredReservations = data;
      isLoading = false;
    } else {
      fetchReservationData();
    }
  }

  Future<void> fetchReservationData() async {
    try {
      List<Map<String, dynamic>> fetchedData =
          await ApiService().fetchReservationData();
      setState(() {
        data = fetchedData;
        filteredReservations = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data: $e";
        isLoading = false;
      });
    }
  }

  void filterReservation() {
    setState(() {
      filteredReservations = data.where((reservation) {
        bool matchesSearch = reservation.values
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());

        bool matchesFilter =
            selectedFilter.isEmpty || reservation["status"] == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  String formatStatus(String status) {
    return status
        .split('_') // Split by underscore
        .map((word) =>
            word[0].toUpperCase() +
            word.substring(1).toLowerCase()) // Capitalize each word
        .join(' '); // Join them back with a space
  }

  void groupByReservation(String key) {
    setState(() {
      selectedGroupBy = key;
      if (key.isNotEmpty) {
        filteredReservations.sort((a, b) {
          return (a[key] ?? '').toString().compareTo((b[key] ?? '').toString());
        });
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return const Color(0xff000000).withOpacity(0.29);
      case 'reserved':
        return const Color(0xff617C28).withOpacity(0.42);
      case 'pending_sales':
        return const Color(0xff617C28).withOpacity(0.42);
      case 'draft':
        return const Color(0xff000000).withOpacity(0.28);
      case 'expired':
        return const Color(0xffFF3131).withOpacity(0.4);
      case 'canceled':
        return const Color(0xffFF3131).withOpacity(0.3);
      default:
        return Colors.black.withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 70),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    const Text(
                      "Reservations",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Text(errorMessage,
                                  style: const TextStyle(color: Colors.red)))
                          : selectedGroupBy.isNotEmpty
                              ? _buildGroupedView()
                              : ListView.builder(
                                  itemCount: filteredReservations.length,
                                  itemBuilder: (context, index) {
                                    return _buildReservationCard(
                                        filteredReservations[index]);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 5),
    height: 120, // Adjusted height for better spacing
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
        // First Row: Property
        Row(
          children: [
            const Text(
              "Property: ",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                reservation["property"]?["name"] ?? "N/A",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Second Row: Customer and Type
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Customer
            Row(
              children: [
                const Text(
                  "Customer: ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  reservation["customer"]?["name"] ?? "N/A",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            // Type
            Row(
              children: [
                const Text(
                  "Type: ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  reservation["reservation_type"]?["name"] ?? "N/A",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Third Row: Status and End Date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reservation["status"]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    formatStatus(reservation["status"]),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Text(
                  "End Date: ",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  reservation["expire_date"] ?? "N/A",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


  Widget _buildGroupedView() {
    if (selectedGroupBy.isEmpty) {
      return ListView.builder(
        itemCount: filteredReservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(filteredReservations[index]);
        },
      );
    } else {
      Map<String, List<Map<String, dynamic>>> groupedData = {};

      for (var reservation in filteredReservations) {
        String key;

        if (selectedGroupBy.toLowerCase() == "status") {
          debugPrint('reservation by status');
          key = reservation["status"] ?? "Unknown";
        } else if (selectedGroupBy.toLowerCase() == "type") {
          debugPrint('reservation by type');
          key = reservation["reservation_type"]["name"] ?? "Unknown";
        } else {
          key = "Unknown"; // Default case
        }

        groupedData.putIfAbsent(key, () => []).add(reservation);
      }

      return ListView(
        children: groupedData.entries.map((entry) {
          String groupName = entry.key;
          List<Map<String, dynamic>> reservations = entry.value;
          int totalReservations = reservations.length;

          return _buildGroupCard(
            groupName,
            totalReservations,
            reservations,
            groupedData: groupedData,
          );
        }).toList(),
      );
    }
  }

  Widget _buildGroupCard(String group, int totalReservations,
      List<Map<String, dynamic>> reservations,
      {required Map<String, List<Map<String, dynamic>>> groupedData}) {
    Color iconColor = _getStatusColor(group);
    IconData iconData = Icons.business_center; // Adjust icon as needed

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            filteredReservations = groupedData[group]!;
            selectedGroupBy = '';
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 115,
          child: Row(
            children: [
              /// Center the icon vertically
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, color: iconColor.withOpacity(1), size: 50),
                ],
              ),
              const SizedBox(width: 12),

              /// Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  children: [
                    Text(
                      formatStatus(group),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: iconColor.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Reservations - $totalReservations",
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
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
                          filterReservation();
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
                filterReservation();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "", child: Text("All")),
              const PopupMenuItem(value: "requested", child: Text("Requested")),
              const PopupMenuItem(value: "reserved", child: Text("Reserved")),
              const PopupMenuItem(
                  value: "pending_sales", child: Text("Pending Sales")),
              const PopupMenuItem(value: "draft", child: Text("Draft")),
              const PopupMenuItem(value: "expired", child: Text("Expired")),
              const PopupMenuItem(value: "canceled", child: Text("Canceled")),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers, color: Color(0xFF84A441)),
            onSelected: (value) {
              groupByReservation(value == "Status" ? "status" : "type");
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: "Status", child: Text("Group by Status")),
              const PopupMenuItem(value: "Type", child: Text("Group by Type")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xff84a441)),
            onPressed: () {
              setState(() {
                searchQuery = '';
                selectedFilter = '';
                selectedGroupBy = '';
                filteredReservations = List.from(data);
              });
            },
          ),
        ],
      ),
    );
  }

}
