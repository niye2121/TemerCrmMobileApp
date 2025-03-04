import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temer/screens/properties_screen.dart';
import 'pipeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "";
  int selectedIndex = -1; // Track selected index

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('user_name') ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> gridItems = [
      {"icon": Icons.account_circle, "label": "My Pipeline", "screen": const PipelineScreen()},
      {"icon": Icons.apartment, "label": "Properties", "screen": const PropertiesScreen()},
      {"icon": Icons.insert_drive_file, "label": "Reservations", "screen": null},
      {"icon": Icons.checklist_sharp, "label": "My Activities", "screen": null},
      {"icon": Icons.notifications, "label": "Updates", "screen": null},
    ];

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 150,
                decoration: const BoxDecoration(color: Colors.white),
                child: Stack(
                  children: [
                    Positioned(
                      left: -100,
                      top: -60,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xff84A441).withOpacity(0.38),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Welcome Back!",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            username,
                            style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: 60,
                      right: 16,
                      child: Icon(Icons.logout, color: Color(0xff84A441), size: 30),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 171 / 173,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      return _buildGridItem(
                        gridItems[index]["icon"],
                        gridItems[index]["label"],
                        gridItems[index]["screen"],
                        index,
                      );
                    },
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    "Powered by Ahadubit Technologies",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, Widget? screen, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 171,
        height: 173,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff84A441) : const Color(0xff84A441).withOpacity(0.29),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: isSelected ? Colors.white : const Color(0xff84A441)),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
