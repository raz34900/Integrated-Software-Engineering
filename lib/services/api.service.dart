import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../models/object_boundary.dart';

class ApiService {
  static String getBaseUrl() {
    if (Platform.isAndroid) {
      // Use emulator localhost mapping or your actual PC IP if using real device
      return 'http://10.100.102.18:8081';
      // Example for real device (replace with your actual PC IP):
      // return 'http://192.168.1.100:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  Future<List<ObjectBoundary>> getObjects() async {
    final baseUrl = getBaseUrl();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ambient-intelligence/objects?email=end@g.com'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ObjectBoundary.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load objects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching objects: $e');
    }
  }
}
