import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  String searchQuery = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final systemId = prefs.getString('system_id') ?? '';
      final userEmail = prefs.getString('user_email') ?? '';
      final url = Uri.parse(
        '${getBaseUrl()}/ambient-intelligence/objects?email=$userEmail',
      );
      print('Products request URL: $url');
      final response = await http.get(
        url,
        headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
      );
      print('Products response status: ${response.statusCode}');
      print('Products response body: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          products =
              jsonDecode(
                response.body,
              ).where((item) => item['type'] == 'Product').toList();
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

  List<dynamic> getFilteredProducts() {
    return products
        .where(
          (product) =>
              product['alias']?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  void _refreshData() {
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
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
                    labelText: 'Search by Product Name',
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
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : getFilteredProducts().isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                          itemCount: getFilteredProducts().length,
                          itemBuilder: (context, index) {
                            final product = getFilteredProducts()[index];
                            final uniqueProducts =
                                getFilteredProducts()
                                    .map((p) => p['alias'])
                                    .toSet()
                                    .toList();
                            final alias = product['alias'] ?? 'Unknown Product';
                            if (uniqueProducts.indexOf(alias) != index)
                              return const SizedBox.shrink();
                            final instances =
                                getFilteredProducts()
                                    .where((p) => p['alias'] == alias)
                                    .toList();
                            return ListTile(
                              leading: const Icon(Icons.inventory_2),
                              title: Text(
                                alias,
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth > 600 ? 18 : 14,
                                ),
                              ),
                              subtitle: Text('Instances: ${instances.length}'),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProductDetailScreen(
                                            alias: alias,
                                            instances: instances,
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

class ProductDetailScreen extends StatelessWidget {
  final String alias;
  final List<dynamic> instances;

  const ProductDetailScreen({
    super.key,
    required this.alias,
    required this.instances,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details for $alias')),
      body: ListView.builder(
        itemCount: instances.length,
        itemBuilder: (context, index) {
          final instance = instances[index];
          final objectId = instance['id']['objectId'] ?? 'Unknown ID';
          return ListTile(title: Text('$alias $objectId'));
        },
      ),
    );
  }
}
