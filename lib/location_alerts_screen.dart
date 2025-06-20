import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail_screen.dart';

class LocationAlertsScreen extends StatefulWidget {
  const LocationAlertsScreen({super.key});

  @override
  _LocationAlertsScreenState createState() => _LocationAlertsScreenState();
}

class _LocationAlertsScreenState extends State<LocationAlertsScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLocationAlerts();
  }

  Future<void> fetchLocationAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/ambient-intelligence/objects'),
      );
      if (response.statusCode == 200) {
        setState(() {
          products =
              jsonDecode(response.body).where((item) {
                final details = item['objectDetails'] ?? {};
                final actualLocation = details['location'] ?? '';
                final expectedLocation = details['expectedLocation'] ?? '';
                return item['type'] == 'Product' &&
                    actualLocation != expectedLocation &&
                    actualLocation.isNotEmpty &&
                    expectedLocation.isNotEmpty;
              }).toList();
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
      appBar: AppBar(title: const Text('Wrong Location Alerts')),
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
                        ? const Center(child: Text('No location alerts'))
                        : ListView.builder(
                          itemCount: getFilteredProducts().length,
                          itemBuilder: (context, index) {
                            final product = getFilteredProducts()[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_off,
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
