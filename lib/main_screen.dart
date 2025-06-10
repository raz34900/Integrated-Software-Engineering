import 'package:flutter/material.dart';
import 'expiration_alerts_screen.dart';
import 'low_stock_screen.dart';
import 'temperature_alerts_screen.dart';
import 'location_alerts_screen.dart';
import 'shelves_screen.dart';
import 'products_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class MainScreen extends StatefulWidget {
  final String? token;

  const MainScreen({super.key, this.token});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int expiredCount = 0;
  int lowStockCount = 0;
  int tempCount = 0;
  int locationCount = 0;

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
    fetchAlertCounts();
  }

  Future<void> fetchAlertCounts() async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http
          .get(
            Uri.parse('$baseUrl/ambient-intelligence/objects'),
            headers:
                widget.token != null
                    ? {'Authorization': 'Bearer ${widget.token}'}
                    : {},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final now = DateTime.now();
        if (mounted) {
          setState(() {
            expiredCount =
                data
                    .where(
                      (item) =>
                          item['type'] == 'Product' &&
                          item['objectDetails']?['expirationDate'] != null &&
                          DateTime.parse(
                            item['objectDetails']['expirationDate'],
                          ).isBefore(now),
                    )
                    .length;
            lowStockCount =
                data
                    .where(
                      (item) =>
                          item['type'] == 'Product' &&
                          (item['objectDetails']['stockLevel'] ?? 0) <= 2,
                    )
                    .length;
            tempCount =
                data.where((item) {
                  final details = item['objectDetails'] ?? {};
                  final actualTemp = details['temperature'] ?? 0;
                  final recommendedTemp =
                      details['recommendedTemperature'] ?? 5.0;
                  final lowerBound = recommendedTemp - 2;
                  final upperBound = recommendedTemp + 2;
                  return item['type'] == 'Product' &&
                      (actualTemp < lowerBound || actualTemp > upperBound);
                }).length;
            locationCount =
                data.where((item) {
                  final details = item['objectDetails'] ?? {};
                  final actualLocation = details['location'] ?? '';
                  final expectedLocation = details['expectedLocation'] ?? '';
                  return item['type'] == 'Product' &&
                      actualLocation != expectedLocation &&
                      actualLocation.isNotEmpty &&
                      expectedLocation.isNotEmpty;
                }).length;
          });
        }
      }
    } catch (e) {
      print('Error fetching alert counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Inventory Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpirationAlertsScreen(),
                    ),
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Expired Products'),
                  const SizedBox(width: 8),
                  Text(
                    '$expiredCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: expiredCount > 0 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LowStockScreen(),
                    ),
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Low Stock'),
                  const SizedBox(width: 8),
                  Text(
                    '$lowStockCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: lowStockCount > 0 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TemperatureAlertsScreen(),
                    ),
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Wrong Temperature'),
                  const SizedBox(width: 8),
                  Text(
                    '$tempCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tempCount > 0 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationAlertsScreen(),
                    ),
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Wrong Location'),
                  const SizedBox(width: 8),
                  Text(
                    '$locationCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: locationCount > 0 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Shelves & Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShelvesScreen(),
                    ),
                  ),
              child: const Text('Shelves'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductsScreen(),
                    ),
                  ),
              child: const Text('Products'),
            ),
          ],
        ),
      ),
    );
  }
}
