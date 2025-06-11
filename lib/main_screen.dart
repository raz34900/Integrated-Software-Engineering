import 'package:flutter/material.dart';
import 'expiration_alerts_screen.dart';
import 'low_stock_screen.dart';
import 'temperature_alerts_screen.dart';
import 'location_alerts_screen.dart';
import 'shelves_screen.dart';
import 'products_screen.dart';
import 'add_object_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int expiredCount = 0;
  int lowStockCount = 0;
  int tempCount = 0;
  int locationCount = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole().then((_) {
      setState(() {});
      _fetchAlertCounts();
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
      print('Loaded role: $_userRole');
    });
  }

  Future<void> _fetchAlertCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';
    final systemId = prefs.getString('system_id') ?? '';

    try {
      final url = Uri.parse(
        'http://localhost:8081/ambient-intelligence/objects?email=$userEmail',
      );
      final response = await http.get(
        url,
        headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          expiredCount = 0;
          final uniqueAliases =
              data
                  .where((item) => item['type'] == 'Product')
                  .map((item) => item['alias'] as String?)
                  .toSet()
                  .whereType<String>();
          lowStockCount = 0;
          for (var alias in uniqueAliases) {
            final allInstances =
                data.where((p) => p['alias'] == alias).toList();
            final totalInstances = allInstances.length;
            if (totalInstances <= 3) {
              final lowStockInstances =
                  allInstances.where((p) {
                    final details =
                        p['objectDetails'] as Map<String, dynamic>? ?? {};
                    final quantity = details['quantity'] as int? ?? 0;
                    return quantity <= 3;
                  }).toList();
              if (lowStockInstances.isNotEmpty) {
                lowStockCount += 1;
              }
            }
          }
          tempCount = 0;
          locationCount = 0;
        });
      } else {
        print(
          'Failed to fetch alert counts. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching alert counts: $e');
    }
  }

  void _refreshData() {
    _fetchAlertCounts();
    print('Refreshed - lowStockCount: $lowStockCount');
  }

  Future<void> _deleteUsers() async {
    bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: const Text(
                  'Are you sure you want to delete all users?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email') ?? '';
        final response = await http.delete(
          Uri.parse(
            'http://localhost:8081/ambient-intelligence/admin/users?email=$userEmail',
          ),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Users deleted successfully')),
          );
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete users. Status: ${response.statusCode}',
              ),
            ),
          );
          print('Delete users response: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteObjects() async {
    bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: const Text(
                  'Are you sure you want to delete all objects?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email') ?? '';
        final response = await http.delete(
          Uri.parse(
            'http://localhost:8081/ambient-intelligence/admin/objects?email=$userEmail',
          ),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objects deleted successfully')),
          );
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete objects. Status: ${response.statusCode}',
              ),
            ),
          );
          print('Delete objects response: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _viewUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      final systemId = prefs.getString('system_id') ?? '2025b.Raz.Natanzon';
      final response = await http.get(
        Uri.parse(
          'http://localhost:8081/ambient-intelligence/admin/users?email=$userEmail',
        ),
        headers: {'X-System-ID': systemId},
      );
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body) as List<dynamic>;
        print('Raw user details response: $users');
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('User Details'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        users.map((user) {
                          return ListTile(
                            title: Text(
                              'Username: ${user['username'] ?? 'Not available'}',
                            ),
                            subtitle: Text(
                              'Role: ${user['role'] ?? 'Not available'}',
                            ),
                          );
                        }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch user details. Status: ${response.statusCode}',
            ),
          ),
        );
        print('View user details response: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _viewCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      final systemId = prefs.getString('system_id') ?? '2025b.Raz.Natanzon';
      final url =
          'http://localhost:8081/ambient-intelligence/users/login/2025b.Raz.Natanzon/$userEmail?email=$userEmail';
      final response = await http.get(
        Uri.parse(url),
        headers: {'X-System-ID': systemId},
      );
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        print('Raw current user response: $user');
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Current User Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Username: ${user['username'] ?? 'Not available'}'),
                    Text('Role: ${user['role'] ?? 'Not available'}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch current user details. Status: ${response.statusCode}',
            ),
          ),
        );
        print('View current user response: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Inventory Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
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
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  if (_userRole != null && _userRole == 'ADMIN')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _deleteUsers,
                          child: const Text('Del Users'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _deleteObjects,
                          child: const Text('Del Obj'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _viewUserDetails,
                          child: const Text('User Det'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                        ),
                      ],
                    ),
                  if (_userRole != null && _userRole == 'OPERATOR')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddObjectScreen(),
                                ),
                              ),
                          child: const Text('Add Obj'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _viewCurrentUser,
                          child: const Text('View User'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
