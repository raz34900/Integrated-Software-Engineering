import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _systemIdController = TextEditingController();
  final _userEmailController = TextEditingController();
  String _errorMessage = '';

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081'; // For Android emulator
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8081'; // For desktop
    } else {
      return 'http://localhost:8081'; // Default fallback
    }
  }

  Future<void> _login() async {
    if (_systemIdController.text.isEmpty || _userEmailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter system ID and User Email';
      });
      return;
    }

    try {
      final baseUrl = getBaseUrl();
      final loginUrl =
          '$baseUrl/ambient-intelligence/users/login/${_systemIdController.text}/${_userEmailController.text}';
      print('Platform: ${Platform.operatingSystem}, Base URL: $baseUrl');
      print('Sending request to server: $loginUrl');
      print(
        'systemId: ${_systemIdController.text}, userEmail: ${_userEmailController.text}',
      );

      final response = await http.get(Uri.parse(loginUrl));

      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? ''; // הנחה שיש שדה 'token' בתגובה
        if (token.isEmpty) {
          print('Warning: No token found in response');
        }
        setState(() {
          _errorMessage = '';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(token: token)),
        );
      } else {
        setState(() {
          _errorMessage =
              'Login failed: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      print('Error during login: $e');
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _systemIdController,
              decoration: const InputDecoration(
                labelText: 'System ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userEmailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
