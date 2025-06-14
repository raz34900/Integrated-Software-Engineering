import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchShelves();
  }

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  Future<void> fetchShelves() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final systemId = prefs.getString('system_id') ?? '';
      final userEmail = prefs.getString('user_email') ?? '';
      final url = Uri.parse(
        '${getBaseUrl()}/ambient-intelligence/objects/search/byType/Shelf?systemID=$systemId&email=$userEmail',
      );
      print('Shelves request URL: $url');
      final response = await http.get(
        url,
        headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
      );
      print('Shelves response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          shelves = data;
          errorMessage = '';
        });
      } else if (response.statusCode == 403) {
        setState(() {
          errorMessage = 'Only end users can reach this';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> getFilteredShelves() {
    return shelves
        .where((shelf) =>
            shelf['alias']?.toLowerCase().contains(searchQuery.toLowerCase()) ??
            false)
        .toList();
  }

  void _refreshData() => fetchShelves();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelves'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : getFilteredShelves().isEmpty
                    ? const Center(child: Text('No shelves found'))
                    : ListView.builder(
                        itemCount: getFilteredShelves().length,
                        itemBuilder: (context, index) {
                          final shelf = getFilteredShelves()[index];
                          return ListTile(
                            leading: const Icon(Icons.store),
                            title: Text(shelf['alias'] ?? 'Unknown Shelf'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShelfDetailScreen(
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      final url = Uri.parse(
        '${getBaseUrl()}/ambient-intelligence/objects/${widget.systemId}/${widget.shelfId}/children?email=$userEmail',
      );
      print('Products request URL: $url');
      final response = await http.get(
        url,
        headers: {'X-System-ID': widget.systemId, 'X-User-Email': userEmail},
      );
      print('Products response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _refreshData() => fetchProducts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelf Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(child: Text('No products on this shelf'))
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final details = product['objectDetails'] ?? {};
                          final alias = product['alias'] ?? 'Unknown';
                          final nfcTag = details['nfcTag'] ?? 'Not assigned';
                          return ListTile(
                            leading: const Icon(Icons.inventory_2),
                            title: Text('$alias'),
                            subtitle: Text('NFC Tag: $nfcTag'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
