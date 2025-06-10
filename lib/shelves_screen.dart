import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_object_screen.dart';
import 'dart:io' show Platform;

class ShelvesScreen extends StatefulWidget {
  const ShelvesScreen({super.key});

  @override
  _ShelvesScreenState createState() => _ShelvesScreenState();
}

class _ShelvesScreenState extends State<ShelvesScreen> {
  List<dynamic> shelves = [];
  String errorMessage = '';
  String searchQuery = '';
  String? token;

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  @override
  void initState() {
    super.initState();
    // קח טוקן מ-LoginScreen (עדכן את הלוגיקה)
    token = 'your_jwt_token_here'; // החלף עם הטוקן האמיתי
    fetchShelves();
  }

  Future<void> fetchShelves() async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http
          .get(
            Uri.parse('$baseUrl/ambient-intelligence/objects'),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ShelvesScreen - Status: ${response.statusCode}');
      debugPrint('ShelvesScreen - Response: ${response.body}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            shelves =
                jsonDecode(
                  response.body,
                ).where((item) => item['type'] == 'Shelf').toList();
            errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }
  }

  List<dynamic> getFilteredShelves() {
    return shelves
        .where(
          (shelf) =>
              shelf['alias']?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shelves')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddObjectScreen()),
          );
          if (mounted) {
            fetchShelves();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(
                    labelText: 'Search by Shelf Name',
                  ),
                ),
              ),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              Expanded(
                child:
                    getFilteredShelves().isEmpty
                        ? const Center(child: Text('No shelves found'))
                        : ListView.builder(
                          itemCount: getFilteredShelves().length,
                          itemBuilder: (context, index) {
                            final shelf = getFilteredShelves()[index];
                            return ListTile(
                              leading: const Icon(Icons.store),
                              title: Text(
                                shelf['alias'] ?? 'Unknown Shelf',
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth > 600 ? 18 : 14,
                                ),
                              ),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ShelfDetailScreen(
                                            shelfId: shelf['id']['objectId'],
                                            systemId: shelf['id']['systemID'],
                                          ),
                                    ),
                                  ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ShelfDetailScreen extends StatefulWidget {
  final String shelfId;
  final String systemId;

  const ShelfDetailScreen({
    super.key,
    required this.shelfId,
    required this.systemId,
  });

  @override
  _ShelfDetailScreenState createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  String? token;

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  @override
  void initState() {
    super.initState();
    // קח טוקן מ-LoginScreen (עדכן את הלוגיקה)
    token = 'your_jwt_token_here'; // החלף עם הטוקן האמיתי
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/ambient-intelligence/objects/${widget.systemId}/${widget.shelfId}/children',
            ),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ShelfDetailScreen - Status: ${response.statusCode}');
      debugPrint('ShelfDetailScreen - Response: ${response.body}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            products = jsonDecode(response.body);
            errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shelf Details')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              Expanded(
                child:
                    products.isEmpty
                        ? const Center(child: Text('No products on this shelf'))
                        : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final details = product['objectDetails'] ?? {};
                            return ListTile(
                              title: Text(
                                '${product['alias']} (${details['quantity']?.toString() ?? '0'})',
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth > 600 ? 18 : 14,
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
