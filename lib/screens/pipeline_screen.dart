// import 'package:flutter/material.dart';
// import 'package:temer/screens/home_screen.dart';
// import 'package:temer/screens/login_screen.dart';
// import 'package:temer/screens/new_pipeline_screen.dart';
// import 'package:temer/services/api_service.dart';

// class PipelineScreen extends StatefulWidget {
//   const PipelineScreen({super.key});

//   @override
//   _PipelineScreenState createState() => _PipelineScreenState();
// }

// class _PipelineScreenState extends State<PipelineScreen> {
//   List<Map<String, dynamic>> data = [];
//   bool isLoading = true;
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchPipelineData();
//   }

//   Future<void> fetchPipelineData() async {
//     try {
//       List<Map<String, dynamic>> fetchedData =
//           await ApiService().fetchPipelineData();
//       setState(() {
//         data = fetchedData;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = "Failed to load data: $e";
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       body: Stack(
//         children: [
//           Positioned(
//             left: -130,
//             top: -140,
//             child: Container(
//               width: 250,
//               height: 250,
//               decoration: BoxDecoration(
//                 color: const Color(0xff84A441).withOpacity(0.38),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: Column(
//               children: [
//                 const SizedBox(height: 70),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Spacer(),
//                     const Text(
//                       "My Pipeline",
//                       style:
//                           TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const Spacer(),
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.house,
//                             color: Color(0xff84A441),
//                             size: 30,
//                           ),
//                           onPressed: () {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const HomeScreen()),
//                             );
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(
//                             Icons.logout,
//                             color: Color(0xff84A441),
//                             size: 30,
//                           ),
//                           onPressed: () {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => LoginScreen()),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 250,
//                         height: 29,
//                         padding: const EdgeInsets.symmetric(horizontal: 10),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 5,
//                               spreadRadius: 2,
//                             ),
//                           ],
//                         ),
//                         child: const Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 decoration: InputDecoration(
//                                   hintText: "Search",
//                                   border: InputBorder.none,
//                                 ),
//                               ),
//                             ),
//                             Icon(Icons.search, color: Color(0xFF84A441)),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.filter_alt,
//                             color: Color(0xff84A441)),
//                         onPressed: () {},
//                       ),
//                       IconButton(
//                         icon:
//                             const Icon(Icons.layers, color: Color(0xff84A441)),
//                         onPressed: () {},
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.add_circle,
//                           color: Colors.green, size: 30),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => NewPipelineScreen()),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//                 Stack(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 12, horizontal: 20),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF84A441),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _tableHeaderText("Opportunity"),
//                           _tableHeaderText("Customer Name"),
//                           _tableHeaderText("Stage"),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : errorMessage.isNotEmpty
//                           ? Center(
//                               child: Text(errorMessage,
//                                   style: TextStyle(color: Colors.red)))
//                           : ListView.builder(
//                               padding: const EdgeInsets.only(top: 5),
//                               itemCount: data.length,
//                               itemBuilder: (context, index) {
//                                 return Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 12, horizontal: 15),
//                                   margin:
//                                       const EdgeInsets.symmetric(vertical: 2),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(
//                                         color: Colors.green.shade300),
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       _tableRowText(
//                                           data[index]["name"] ?? "N/A"),
//                                       _tableRowText(
//                                           data[index]["customer"] ?? "N/A"),
//                                      _tableRowText(data[index]["stage"]?["name"] ?? "N/A"),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.all(10.0),
//                   child: Text(
//                     "Powered by Ahadubit Technologies",
//                     style: TextStyle(
//                         color: Colors.grey,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

// Widget _tableHeaderText(String text) {
//   return Expanded(
//     child: Text(
//       text,
//       textAlign: TextAlign.center,
//       style:
//           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//     ),
//   );
// }

// Widget _tableRowText(String text) {
//   return Expanded(
//     child: Text(
//       text,
//       textAlign: TextAlign.center,
//       style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//     ),
//   );
// }
// }

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
  bool isLoading = true;
  String errorMessage = '';

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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data: $e";
        isLoading = false;
      });
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        width: 250,
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
                      IconButton(
                        icon: const Icon(Icons.filter_alt,
                            color: Color(0xff84A441)),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.layers, color: Color(0xff84A441)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
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
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 5),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PipelineDetailScreen(
                                                pipelineId: data[index]["id"]
                                                    .toString()),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 15),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.shade300),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _tableRowText(
                                            data[index]["name"] ?? "N/A"),
                                        _tableRowText(
                                            data[index]["customer"] ?? "N/A"),
                                        _tableRowText(data[index]["stage"]
                                                ?["name"] ??
                                            "N/A"),
                                      ],
                                    ),
                                  ),
                                );
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
