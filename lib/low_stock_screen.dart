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
  Map<String, int> lowStockCount = {};
  String errorMessage = '';
  static int totalAlerts = 0;

  @override
  void initState() {
    super.initState();
    fetchLowStockViaCommand();
  }

  Future<void> fetchLowStockViaCommand() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';
    final systemId = prefs.getString('system_id') ?? '';

    final commandPayload = {
      "id": {
        "systemID": systemId,
        "commandId": "checkLowStock-${DateTime.now().millisecondsSinceEpoch}"
      },
      "command": "check_low_stock",
      "targetObject": {
        "id": {"systemID": "dummy", "objectId": "dummy0"}
      },
      "invokedBy": {
        "userId": {"systemID": systemId, "email": "end@test.com"}
      },
      "invocationTimestamp": DateTime.now().toUtc().toIso8601String(),
      "commandAttributes": {"threshold": 3}
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/ambient-intelligence/commands'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(commandPayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final updatedMap = <String, int>{};
        for (final item in data) {
          final alias = item['alias'];
          final count = item['count'];
          if (alias != null && count != null) {
            updatedMap[alias] = count;
          }
        }

        setState(() {
          lowStockCount = updatedMap;
          totalAlerts = updatedMap.length;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch low stock: ${response.statusCode}';
          totalAlerts = 0;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching low stock: $e';
        totalAlerts = 0;
      });
    }
  }

  void _refreshData() {
    fetchLowStockViaCommand();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Low Stock Alerts ($totalAlerts)'),
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
          if (lowStockCount.isNotEmpty)
            Expanded(
              child: ListView(
                children: lowStockCount.entries.map((entry) {
                  final alias = entry.key;
                  final count = entry.value;

                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      alias,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Instances in low stock: $count'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            alias: alias,
                            // You may want to dynamically fetch instances for this alias
                            instances: [],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          if (lowStockCount.isEmpty && errorMessage.isEmpty)
            const Center(child: Text('No low stock items found')),
        ],
      ),
    );
  }
}
