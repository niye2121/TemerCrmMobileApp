import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temer/screens/home_screen.dart';
import 'package:temer/screens/login_screen.dart';
import 'package:temer/services/api_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  _UpdatesScreenState createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  late Future<List<Map<String, dynamic>>> _futureUpdates;

  @override
  void initState() {
    super.initState();
    _futureUpdates = ApiService().fetchGeneralUpdates();
  }

  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    Duration difference = DateTime.now().difference(date);
    if (difference.inDays > 1) {
      return "${difference.inDays} days ago";
    } else if (difference.inDays == 1) {
      return "${difference.inDays} day ago";
    } else if (difference.inHours > 1) {
      return "${difference.inHours} hours ago";
    } else if (difference.inHours == 1) {
      return "${difference.inHours} hour ago";
    } else {
      return "Just now";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      const Text(
                        "Updates",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                                      builder: (context) =>
                                          const LoginScreen()),
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
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _futureUpdates,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return buildSkeletonLoader(); // Show shimmer skeleton
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text("No updates available"));
                        }

                        List<Map<String, dynamic>> messages = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDate(msg["date"]),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          msg["sender"] == "OdooBot"
                                              ? Colors.black54
                                              : Colors.orange,
                                      child: Text(
                                        msg["sender"][0].toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg["sender"],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xff84A441)
                                                  .withOpacity(0.38),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(msg["message"]),
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the shimmer skeleton loader
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
}