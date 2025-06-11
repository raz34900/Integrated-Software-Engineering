import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  final String? alias;
  final List<dynamic>? instances;

  const ProductDetailScreen({
    super.key,
    this.productId,
    this.alias,
    this.instances,
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<dynamic> instances = [];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      fetchProductDetails(widget.productId!);
    } else if (widget.instances != null) {
      setState(() {
        instances = widget.instances!;
      });
    }
  }

  Future<void> fetchProductDetails(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';
    final systemId = prefs.getString('system_id') ?? '';
    final url = Uri.parse(
      'http://localhost:8081/ambient-intelligence/objects?email=$userEmail&id=$productId',
    );
    try {
      final response = await http.get(
        url,
        headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          instances =
              data
                  .where((item) => item['id']['objectId'] == productId)
                  .toList();
        });
      }
    } catch (e) {
      print('Error fetching product details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details')),
      body:
          instances.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: instances.length,
                itemBuilder: (context, index) {
                  final instance = instances[index];
                  final objectId = instance['id']['objectId'] ?? 'Unknown ID';
                  return ListTile(title: Text(objectId));
                },
              ),
    );
  }
}
