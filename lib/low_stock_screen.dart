import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_detail_screen.dart';

class LowStockScreen extends StatefulWidget {
  final String? filterAlias;
  const LowStockScreen({super.key, this.filterAlias});

  @override
  _LowStockScreenState createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  Map<String, int> lowStockCount = {};
  static int totalAlerts = 0;

  @override
  void initState() {
    super.initState();
    fetchLowStockProducts();
  }

  Future<void> fetchLowStockProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8081/ambient-intelligence/objects?email=$userEmail',
        ),
      );
      if (response.statusCode == 200) {
        final allProducts = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          //quantity <= 3
          products =
              allProducts.where((item) {
                final details =
                    item['objectDetails'] as Map<String, dynamic>? ?? {};
                final quantity = details['quantity'] as int? ?? 0;
                final matchesAlias =
                    widget.filterAlias == null ||
                    (item['alias']?.toLowerCase() ==
                        widget.filterAlias?.toLowerCase());
                return quantity <= 3 &&
                    matchesAlias &&
                    item['type'] == 'Product';
              }).toList();

          lowStockCount = {};
          final uniqueAliases =
              allProducts
                  .where((item) => item['type'] == 'Product')
                  .map((item) => item['alias'] as String?)
                  .toSet()
                  .whereType<String>();
          for (var alias in uniqueAliases) {
            final allInstances =
                allProducts.where((p) => p['alias'] == alias).toList();
            final totalInstances = allInstances.length;
            if (totalInstances <= 3) {
              final lowStockInstances =
                  allInstances.where((p) {
                    final details =
                        p['objectDetails'] as Map<String, dynamic>? ?? {};
                    final quantity = details['quantity'] as int? ?? 0;
                    return quantity <= 3;
                  }).toList();
              lowStockCount[alias] = lowStockInstances.length;
            }
          }
          totalAlerts = lowStockCount.length;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load: ${response.statusCode}';
          lowStockCount = {};
          totalAlerts = 0;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        lowStockCount = {};
        totalAlerts = 0;
      });
    }
  }

  void _refreshData() {
    fetchLowStockProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Low Stock Alerts (${totalAlerts})'),
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
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          if (lowStockCount.isNotEmpty)
            ...lowStockCount.entries.map((entry) {
              final alias = entry.key;
              final count = entry.value;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    alias ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Instances in low stock: $count'),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProductDetailScreen(
                                alias: alias,
                                instances:
                                    products
                                        .where((p) => p['alias'] == alias)
                                        .toList(),
                              ),
                        ),
                      ),
                ),
              );
            }),
          if (lowStockCount.isEmpty && errorMessage.isEmpty)
            const Center(child: Text('No low stock items found')),
        ],
      ),
    );
  }
}
