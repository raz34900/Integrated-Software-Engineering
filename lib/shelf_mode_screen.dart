import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class ShelfModeScreen extends StatefulWidget {
  const ShelfModeScreen({super.key});

  @override
  State<ShelfModeScreen> createState() => _ShelfModeScreenState();
}

class _ShelfModeScreenState extends State<ShelfModeScreen> {
  List<dynamic> _shelves = [];
  dynamic _selectedShelf;
  bool _isLoading = false;
  String _errorMessage = '';
  String _lastScanResult = '';

  @override
  void initState() {
    super.initState();
    _fetchShelves();
  }

  String getBaseUrl() {
    return 'http://10.100.102.17:8081'; // Use your PC IP here
  }

  Future<void> _fetchShelves() async {
    print('>>> Fetching shelves...');
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final systemId = prefs.getString('system_id') ?? '';
      final userEmail = prefs.getString('user_email') ?? '';
      final url = Uri.parse(
        '${getBaseUrl()}/ambient-intelligence/objects?email=end@test.com',
      );
      print('>>> Shelves URL: $url');
      print('>>> Headers: X-System-ID: $systemId, X-User-Email: $userEmail');

      final response = await http.get(
        url,
        headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
      );

      print('>>> Shelves response status: ${response.statusCode}');
      print('>>> Shelves response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _shelves = data.where((item) => item['type'] == 'Shelf').toList();
          _errorMessage = '';
        });
        print('>>> Fetched ${_shelves.length} shelves.');
      } else {
        setState(() {
          _errorMessage = 'Failed to load shelves: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
      print('>>> Error fetching shelves: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanNfcAndSendCommand() async {
    if (_selectedShelf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shelf first')),
      );
      print('>>> Scan aborted: no shelf selected.');
      return;
    }

    // Show "Waiting for NFC tag..." message
    final waitingSnack = SnackBar(
      content: const Text('Waiting for NFC tag (1 min timeout)...'),
      duration: const Duration(minutes: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(waitingSnack);

    try {
      print('>>> Starting NFC scan...');
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 60));
      _lastScanResult = 'Tag ID: ${tag.id}';
      print('>>> NFC scan completed. Tag ID: ${tag.id}');

      // Dismiss "waiting" message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Now send Tag ID directly
      final tagId = tag.id;
      print('>>> Sending command for Tag ID: $tagId');
      await _sendCommand(tagId);

    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFC error: $e')),
      );
      print('>>> NFC scan error: $e');
    } finally {
      await FlutterNfcKit.finish();
      print('>>> NFC scan finished.');
      setState(() {}); // To refresh _lastScanResult
    }
  }

  Future<void> _sendCommand(String nfcTag) async {
    print('>>> Preparing to send command for NFC Tag: $nfcTag');
    final prefs = await SharedPreferences.getInstance();
    final systemId = prefs.getString('system_id') ?? '';
    final userEmail = prefs.getString('user_email') ?? '';
    const urlPath = '/ambient-intelligence/commands';
    final baseUrl = getBaseUrl();
    final url = Uri.parse('$baseUrl$urlPath');

    final body = {
      "id": {
        "systemID": systemId,
        "commandId": "removeProductCommand",
      },
      "command": "remove_product_from_shelf", // must match your backend @Component name
      "targetObject": {
    "id": {
      "systemID": "dummySystem",
      "objectID": "dummyObject"
    }
  },
      "invokedBy": {
        "userId": {
          "systemID": "2025b.Raz.Natanzon",
          "email": "end@test.com",
        },
      },
      "invocationTimestamp": DateTime.now().toIso8601String(),
      "commandAttributes": {
        "nfcTag": nfcTag, // sending tag.id here
      },
    };

    try {
      print('>>> Sending POST to $url');
      print('>>> Request body: $body');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-System-ID': systemId,
          'X-User-Email': userEmail,
        },
        body: jsonEncode(body),
      );

      print('>>> Command response status: ${response.statusCode}');
      print('>>> Command response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Command sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.statusCode} ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending command: $e')),
      );
      print('>>> Error sending command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shelf Mode - NFC Scan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Select Shelf:',
                        style: TextStyle(fontSize: 18),
                      ),
                      DropdownButton<dynamic>(
                        value: _selectedShelf,
                        hint: const Text('Choose Shelf'),
                        items: _shelves.map((shelf) {
                          return DropdownMenuItem<dynamic>(
                            value: shelf,
                            child: Text(shelf['alias'] ?? 'Unnamed Shelf'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedShelf = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _scanNfcAndSendCommand,
                        child: const Text('Scan NFC Tag'),
                      ),
                      const SizedBox(height: 20),
                      if (_lastScanResult.isNotEmpty)
                        Text(
                          'Last Scan: $_lastScanResult',
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
