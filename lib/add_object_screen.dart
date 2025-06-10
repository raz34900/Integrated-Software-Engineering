import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class AddObjectScreen extends StatefulWidget {
  const AddObjectScreen({super.key});

  @override
  _AddObjectScreenState createState() => _AddObjectScreenState();
}

class _AddObjectScreenState extends State<AddObjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String type = 'Shelf';
  String alias = '';
  String systemID = '';
  String objectId = '';
  String quantity = '';
  String errorMessage = '';
  String? token;

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
    token = 'your_jwt_token_here';
  }

  Future<void> addObject() async {
    if (!_formKey.currentState!.validate()) return;

    final object = {
      'id': {'systemID': systemID, 'objectId': objectId},
      'type': type,
      'alias': alias,
      'status': 'active',
      'active': true,
      'createdBy': {
        'userId': {'systemID': systemID, 'email': 'user@example.com'},
      },
      'creationTimestamp': DateTime.now().toIso8601String(),
      'objectDetails':
          type == 'Product'
              ? {'quantity': int.parse(quantity.isNotEmpty ? quantity : '0')}
              : {},
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

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Object added successfully')),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          errorMessage =
              'Cannot add new object: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
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
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'מזהה מערכת (System ID)',
                ),
                onChanged: (value) => systemID = value,
                validator:
                    (value) => value!.isEmpty ? 'SystemID Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Object ID(Object ID)',
                ),
                onChanged: (value) => objectId = value,
                validator:
                    (value) => value!.isEmpty ? 'ObjectID Required' : null,
              ),
              if (type == 'Product')
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Quantity (Quantity)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => quantity = value,
                  validator:
                      (value) => value!.isEmpty ? 'Quantity Required' : null,
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
