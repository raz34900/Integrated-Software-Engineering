import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail_screen.dart';
import 'add_object_screen.dart';
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
  String? token; // טוקן מאימות

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
    // קח טוקן מ-LoginScreen
    token = 'your_jwt_token_here'; // החלף עם הטוקן האמיתי
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final baseUrl = getBaseUrl();
      debugPrint('URL: ${baseUrl}');
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/ambient-intelligence/objects?systemID=2025b.Raz.Natanzon&email=admin11@gmail.com',
            ),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ProductsScreen - Status: ${response.statusCode}');
      debugPrint('ProductsScreen - Response: ${response.body}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            products =
                jsonDecode(
                  response.body,
                ).where((item) => item['type'] == 'Product').toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddObjectScreen()),
          );
          if (mounted) {
            fetchProducts();
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
                    getFilteredProducts().isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                          itemCount: getFilteredProducts().length,
                          itemBuilder: (context, index) {
                            final product = getFilteredProducts()[index];
                            final details = product['objectDetails'] ?? {};
                            final quantity = details['quantity'] ?? 0;
                            final isLowStock = quantity < 3;
                            return ListTile(
                              leading: const Icon(Icons.inventory_2),
                              title: Text(
                                product['alias'] ?? 'Unknown Product',
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth > 600 ? 18 : 14,
                                  color: isLowStock ? Colors.red : null,
                                ),
                              ),
                              subtitle: Text(
                                'Quantity: $quantity',
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth > 600 ? 16 : 12,
                                  color: isLowStock ? Colors.red : null,
                                ),
                              ),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProductDetailScreen(
                                            productId:
                                                product['id']['objectId'],
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
