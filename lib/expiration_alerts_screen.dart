import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail_screen.dart';

class ExpirationAlertsScreen extends StatefulWidget {
  const ExpirationAlertsScreen({super.key});

  @override
  _ExpirationAlertsScreenState createState() => _ExpirationAlertsScreenState();
}

class _ExpirationAlertsScreenState extends State<ExpirationAlertsScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchExpiredProducts();
  }

  Future<void> fetchExpiredProducts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/ambient-intelligence/objects'),
      );
      if (response.statusCode == 200) {
        final now = DateTime.now();
        setState(() {
          products =
              jsonDecode(response.body)
                  .where(
                    (item) =>
                        item['type'] == 'Product' &&
                        item['objectDetails']?['expirationDate'] != null &&
                        DateTime.parse(
                          item['objectDetails']['expirationDate'],
                        ).isBefore(now),
                  )
                  .toList();
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
      appBar: AppBar(title: const Text('Expired Products')),
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
                        ? const Center(child: Text('No expired products'))
                        : ListView.builder(
                          itemCount: getFilteredProducts().length,
                          itemBuilder: (context, index) {
                            final product = getFilteredProducts()[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                              title: Text(
                                product['alias'] ?? 'Unknown',
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
