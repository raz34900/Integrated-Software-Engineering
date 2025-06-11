import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AddObjectScreen extends StatefulWidget {
  const AddObjectScreen({super.key});

  @override
  _AddObjectScreenState createState() => _AddObjectScreenState();
}

class _AddObjectScreenState extends State<AddObjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String type = 'Shelf';
  String alias = '';
  String errorMessage = '';
  String? token;
  String? userEmail;
  final String systemID = '2025b.Raz.Natanzon'; // קבוע
  final Uuid _uuid = Uuid(); // ליצירת objectId אוטומטי

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
    _loadUserData();
    token = 'your_jwt_token_here'; // החלף בטוקן אמיתי אם קיים
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> addObject() async {
    if (!_formKey.currentState!.validate()) return;

    final objectId = _uuid.v4(); // יצירת objectId אוטומטי
    final object = {
      'id': {'systemID': systemID, 'objectId': objectId},
      'type': type,
      'alias': alias,
      'status': 'active',
      'active': true,
      'createdBy': {
        'userId': {
          'systemID': systemID,
          'email': userEmail ?? 'user@example.com',
        },
      },
      'creationTimestamp': DateTime.now().toIso8601String(),
      'objectDetails':
          type == 'Product'
              ? {'quantity': 1}
              : {}, // כמות ברירת מחדל 1 עבור מוצר
    };

    try {
      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/ambient-intelligence/objects'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(object),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Object added successfully')),
        );
        Navigator.pop(context); // חזרה למסך הראשי
      } else {
        setState(() {
          errorMessage =
              'Cannot add new object: ${response.statusCode} - ${response.body}';
        });
        print(
          'Failed response: ${response.statusCode} - ${response.body}',
        ); // דיבאגינג
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
      print('Exception: $e'); // דיבאגינג
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Object')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items:
                    ['Shelf', 'Product'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                onChanged: (value) => setState(() => type = value!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name (Alias)'),
                onChanged: (value) => alias = value,
                validator: (value) => value!.isEmpty ? 'Name Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: addObject,
                child: const Text('Add Object'),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
