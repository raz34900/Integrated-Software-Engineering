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
          instances = data
              .where((item) => item['id']['objectId'] == productId)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching product details: $e');
    }
  }

  Future<void> sendPendingAction({
    required String userEmail,
    required String targetSystemId,
    required String targetObjectId,
    required BuildContext context,
  }) async {
    final url = Uri.parse(
        'http://localhost:8081/ambient-intelligence/pending-action');
    final body = {
      "userEmail": userEmail,
      "actionType": "ASSIGN_NFC_TAG",
      "targetSystemId": targetSystemId,
      "targetObjectId": targetObjectId,
    };

    print('>>> Sending PendingAction: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('>>> PendingAction POST status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PendingAction created — scan NFC now!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error creating PendingAction: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.alias != null ? 'Details for ${widget.alias}' : 'Details')),
      body: instances.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: instances.length,
              itemBuilder: (context, index) {
                final instance = instances[index];
                final objectId = instance['id']['objectId'] ?? 'Unknown ID';
                final systemId = instance['id']['systemID'] ?? 'Unknown System';

                return ListTile(
                  title: Text('Alias: ${widget.alias ?? 'Unknown'}\nObjectId: $objectId'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Assign NFC Tag',
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final userEmail = prefs.getString('user_email') ?? 'end@g.com';

                      await sendPendingAction(
                        userEmail: userEmail,
                        targetSystemId: systemId,
                        targetObjectId: objectId,
                        context: context,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
