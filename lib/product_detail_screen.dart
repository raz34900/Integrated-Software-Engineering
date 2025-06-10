import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  String errorMessage = '';
  String? token;

  @override
  void initState() {
    super.initState();
    // קח טוקן מ-LoginScreen
    token = 'your_jwt_token_here'; // החלף עם הטוקן האמיתי
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://localhost:8081/ambient-intelligence/objects/2025b.Raz.Natanzon/${widget.productId}', // הוספת systemID
            ),
            headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ProductDetailScreen - Status: ${response.statusCode}');
      debugPrint('ProductDetailScreen - Response: ${response.body}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            product = jsonDecode(response.body);
            errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Error loading product details: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            if (product == null && errorMessage.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (product != null) ...[
              Text(
                'Product Name: ${product!['alias'] ?? 'Unknown'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'objectId: ${product!['id']['objectId']}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'systemID: ${product!['id']['systemID']}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Quantity: ${product!['objectDetails']?['quantity']?.toString() ?? '0'}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Status: ${product!['status'] ?? 'Not available'}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Active: ${product!['active'] ? 'Yes' : 'No'}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Craeted By: ${product!['createdBy']?['userId']?['email'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Creation Timestamp: ${product!['creationTimestamp'] ?? 'Not available'}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
