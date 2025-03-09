import 'package:flutter/material.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/screens/new_pipeline_screen.dart';
import 'package:temer/screens/pipeline_detail_screen.dart';
import 'package:temer/services/api_service.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PipelineScreenState createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> filteredPipelines = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  String selectedFilter = '';
  String selectedGroupBy = '';

  @override
  void initState() {
    super.initState();
    fetchPipelineData();
  }

  Future<void> fetchPipelineData() async {
    try {
      List<Map<String, dynamic>> fetchedData =
          await ApiService().fetchPipelineData();
      setState(() {
        data = fetchedData;
        filteredPipelines = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data: $e";
        isLoading = false;
      });
    }
  }

  void filterPipeline() {
    setState(() {
      filteredPipelines = data.where((data) {
        bool matchesSearch = data.values
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());

        bool matchesFilter =
            selectedFilter.isEmpty || data["stage"]["name"] == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void groupByPipeline(String key) {
    setState(() {
      selectedGroupBy = key;
    });
  }

  Color _getStageColor(String status) {
    switch (status) {
      case 'Reservation':
        return const Color(0xff84A441);
      case 'Follow Up':
        return const Color(0xffE29609).withOpacity(0.66);
      case 'Prospect':
        return const Color(0xffA15E1A).withOpacity(0.66);
      case 'Expired':
        return const Color(0xffFF3131).withOpacity(0.28);
      case 'Sold':
        return Colors.black;
      default:
        return Colors.black;
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
                      "My Pipeline",
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
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            } catch (e) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: Colors.green, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NewPipelineScreen()),
                        );
                      },
                    ),
                  ],
                ),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF84A441),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _tableHeaderText("Opportunity"),
                          _tableHeaderText("Customer Name"),
                          _tableHeaderText("Stage"),
                        ],
                      ),
                    ),
                  ],
                ),
                
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
                                  itemCount: filteredPipelines.length,
                                  itemBuilder: (context, index) {
                                    return _buildPipelineCard(
                                        filteredPipelines[index]);
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

  Widget _buildPipelineCard(Map<String, dynamic> pipeline) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PipelineDetailScreen(pipelineId: pipeline["id"].toString()),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height:60, // Increased height for better layout
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                pipeline["name"] ?? "N/A",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Expanded(
              child: Text(
                pipeline["customer"] ?? "N/A",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              child: Text(
                pipeline["stage"]["name"] ?? "N/A",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStageColor(pipeline["stage"]["name"] ?? ""),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedView() {
    if (selectedGroupBy.isEmpty) {
      return ListView.builder(
        itemCount: filteredPipelines.length,
        itemBuilder: (context, index) {
          return _buildPipelineCard(filteredPipelines[index]);
        },
      );
    } else {
      Map<String, List<Map<String, dynamic>>> groupedData = {};

      for (var pipeline in filteredPipelines) {
        // String key = pipeline[selectedGroupBy]?.toString() ?? "Unknown";
        String key = pipeline[selectedGroupBy]?['name']?.toString() ?? "Unknown";

        groupedData.putIfAbsent(key, () => []).add(pipeline);
      }

      return ListView(
        children: groupedData.entries.map((entry) {
          String groupName = entry.key;
          List<Map<String, dynamic>> pipelines = entry.value;
          int totalPipelines = pipelines.length;

          return _buildGroupCard(groupName, totalPipelines, pipelines,
              groupedData: groupedData);
        }).toList(),
      );
    }
  }

  Widget _buildGroupCard(
    String group, int totalPipelines, List<Map<String, dynamic>> pipelines,
    {required Map<String, List<Map<String, dynamic>>> groupedData}) {
  Color iconColor = _getStageColor(group);
  IconData iconData = Icons.business_center; // Adjust icon as needed

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 2,
    child: InkWell(
      onTap: () {
        setState(() {
          filteredPipelines = groupedData[group]!;
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
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  Text(
                    group,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: iconColor.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total Pipelines - $totalPipelines",
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
                          filterPipeline();
                        });
                      },
                      decoration: const InputDecoration(
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
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.filter_alt,
              color: Color(0xFF84A441),
            ),
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
                filterPipeline();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "", child: Text("All")),
              const PopupMenuItem(
                  value: "Reservation", child: Text("Reservation")),
              const PopupMenuItem(value: "Follow Up", child: Text("Follow Up")),
              const PopupMenuItem(value: "Prospect", child: Text("Prospect")),
              const PopupMenuItem(value: "Sold", child: Text("Sold")),
              const PopupMenuItem(value: "Expired", child: Text("Expired")),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.layers,
              color: Color(0xFF84A441),
            ),
            onSelected: (value) {
              groupByPipeline(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: "stage", child: Text("Group by Stage")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderText(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _tableRowText(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStageColor(text), // Apply dynamic color
        ),
      ),
    );
  }
}
