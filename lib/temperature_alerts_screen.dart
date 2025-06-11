import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail_screen.dart';

class TemperatureAlertsScreen extends StatefulWidget {
  const TemperatureAlertsScreen({super.key});

  @override
  _TemperatureAlertsScreenState createState() =>
      _TemperatureAlertsScreenState();
}

class _TemperatureAlertsScreenState extends State<TemperatureAlertsScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  String searchQuery = '';
  bool showAlerts = false;

  @override
  void initState() {
    super.initState();
    fetchTemperatureAlerts();
  }

  Future<void> fetchTemperatureAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/ambient-intelligence/objects'),
      );
      if (response.statusCode == 200) {
        setState(() {
          products =
              jsonDecode(response.body).where((item) {
                final details = item['objectDetails'] ?? {};
                final actualTemp = details['temperature'] ?? 0;
                final recommendedTemp =
                    details['recommendedTemperature'] ??
                    5.0; // Default to 5 if not provided
                final lowerBound = recommendedTemp - 2;
                final upperBound = recommendedTemp + 2;
                return item['type'] == 'Product' &&
                    (actualTemp < lowerBound || actualTemp > upperBound);
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
      appBar: AppBar(title: const Text('Low Temperature Alerts')),
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
                    showAlerts
                        ? getFilteredProducts().isEmpty
                            ? const Center(child: Text('No temperature alerts'))
                            : ListView.builder(
                              itemCount: getFilteredProducts().length,
                              itemBuilder: (context, index) {
                                final product = getFilteredProducts()[index];
                                final details = product['objectDetails'] ?? {};
                                final actualTemp = details['temperature'] ?? 0;
                                final recommendedTemp =
                                    details['recommendedTemperature'] ?? 5.0;
                                return ListTile(
                                  leading: const Icon(
                                    Icons.thermostat,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    product['alias'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize:
                                          constraints.maxWidth > 600 ? 18 : 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Actual: $actualTemp°C, Recommended: $recommendedTemp°C',
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
                            )
                        : const Center(child: Text('Alerts disabled')),
              ),
            ],
          );
        },
      ),
    );
  }
}
