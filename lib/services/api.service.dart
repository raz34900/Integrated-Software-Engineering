import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/object_boundary.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8081/';

  Future<List<ObjectBoundary>> getObjects() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ambient-intelligence/objects'),
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
