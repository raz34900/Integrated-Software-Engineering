import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; // import your login screen file here
// ignore: unused_import
import 'low_stock_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Inventory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), // start from the login screen
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _objects = [];
  String _errorMessage = '';
  String userEmail =
      'raz@gmail.com'; // TODO: Replace with actual user email**********

  @override
  void initState() {
    super.initState();
    _fetchObjects();
  }

  Future<void> _fetchObjects() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8081/ambient-intelligence/objects?email=$userEmail',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          _objects = jsonDecode(response.body);
          _errorMessage = '';
        });
      } else {
        setState(() {
          _objects = [];
          _errorMessage = 'Failed to load objects: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _objects = [];
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _refreshObjects() {
    _fetchObjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Inventory')),
      body:
          _errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _objects.isEmpty
              ? const Center(child: Text('No objects found'))
              : ListView.builder(
                itemCount: _objects.length,
                itemBuilder: (context, index) {
                  final object = _objects[index];
                  return ListTile(
                    title: Text(object['name'] ?? 'Unknown'),
                    subtitle: Text('Type: ${object['type'] ?? 'Unknown'}'),
                    trailing: Text(
                      'Stock: ${object['objectDetails']['stockLevel']?.toString() ?? '0'}',
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshObjects,
        tooltip: 'refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
