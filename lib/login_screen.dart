import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isLoading = false;

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  Future<void> _login() async {
    if (_systemIdController.text.isEmpty || _userEmailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter System ID and User Email';
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      final baseUrl = getBaseUrl();
      final loginUrl =
          '$baseUrl/ambient-intelligence/users/login/${_systemIdController.text}/${_userEmailController.text}';
      print('Sending request to server: $loginUrl');
      final response = await http.get(Uri.parse(loginUrl));
      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final token = responseData['token'];
        if (token != null) {
          await prefs.setString('auth_token', token);
          print('Token saved: $token');
        } else {
          print('No token found in response');
        }
        await prefs.setString('system_id', _systemIdController.text);
        await prefs.setString('user_email', _userEmailController.text);
        await prefs.setString(
          'role',
          responseData['role'] ?? 'END_USER',
        ); // שמירת תפקיד
        print('System ID saved: ${_systemIdController.text}');
        print('User Email saved: ${_userEmailController.text}');
        setState(() {
          _errorMessage = '';
        });
        print('Navigating to MainScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Login failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error during login: $e');
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addUser(
    String email,
    String username,
    String avatar,
    String role,
  ) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/ambient-intelligence/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "username": username,
          "avatar": avatar,
          "role": role,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Success'),
                content: const Text('User added successfully'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add user. Status: ${response.statusCode}'),
          ),
        );
        print('Add user response: ${response.body}');
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
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _login, child: const Text('Login')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                String selectedRole = 'END_USER';
                final emailController = TextEditingController();
                final usernameController = TextEditingController();
                final avatarController = TextEditingController();

                final result = await showDialog(
                  context: context,
                  builder:
                      (context) => StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Add New User'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                TextField(
                                  controller: usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                  ),
                                ),
                                TextField(
                                  controller: avatarController,
                                  decoration: const InputDecoration(
                                    labelText: 'Avatar',
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: selectedRole,
                                  items:
                                      ['ADMIN', 'OPERATOR', 'END_USER']
                                          .map(
                                            (role) => DropdownMenuItem(
                                              value: role,
                                              child: Text(role),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value!;
                                    });
                                  },
                                  hint: const Text('Select Role'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'email': emailController.text,
                                    'username': usernameController.text,
                                    'avatar': avatarController.text,
                                    'role': selectedRole,
                                  });
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        },
                      ),
                );
                if (result != null) {
                  _addUser(
                    result['email'],
                    result['username'],
                    result['avatar'],
                    result['role'],
                  );
                }
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}
