import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_object_screen.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  _LowStockScreenState createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<dynamic> shelves = [];
  String errorMessage = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchShelves();
  }

  Future<void> fetchShelves() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:8081/ambient-intelligence/objects'))
          .timeout(const Duration(seconds: 30)); // Use localhost for Windows
      debugPrint('Server response status: ${response.statusCode}');
      debugPrint('Server response body: ${response.body}'); // Log raw response
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            shelves = data.where((item) => item['type'] == 'Shelf').toList();
            errorMessage = '';
            debugPrint('Filtered shelves: $shelves'); // Log filtered shelves
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load: ${response.statusCode}';
            debugPrint(
              'Error: Failed to load with status ${response.statusCode}',
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          debugPrint('Exception: $e'); // Log exception
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
      appBar: AppBar(
        title: const Text('Shelves'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchShelves, // Manual refresh
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://localhost:8081/ambient-intelligence/objects/${widget.systemId}/${widget.shelfId}/children',
            ),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('Shelf products response status: ${response.statusCode}');
      debugPrint(
        'Shelf products response body: ${response.body}',
      ); // Log response
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            products = jsonDecode(response.body);
            errorMessage = '';
            debugPrint('Products on shelf: $products'); // Log products
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load: ${response.statusCode}';
            debugPrint(
              'Error: Failed to load with status ${response.statusCode}',
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          debugPrint('Exception: $e');
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
                                '${product['alias']} (${details['stockLevel']?.toString() ?? '0'})',
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
