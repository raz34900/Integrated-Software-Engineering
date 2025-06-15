import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  String errorMessage = '';
  String searchQuery = '';
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  Future<void> fetchProducts() async {
  setState(() => isLoading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final systemId = prefs.getString('system_id') ?? '';
    final userEmail = prefs.getString('user_email') ?? '';
    final url = Uri.parse(
      '${getBaseUrl()}/ambient-intelligence/objects/search/byType/Product?systemID=$systemId&email=$userEmail&size=50',
    );

    print('📥 Products request URL: $url');
    final response = await http.get(
      url,
      headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
    );
    print('📥 Products response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Total products fetched: ${data.length}');
      for (var item in data) {
        print('🔹 ${item['alias']} (ID: ${item['id']?['objectId']})');
      }

      setState(() {
        products = data;
        errorMessage = '';
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error: $e';
    });
  } finally {
    setState(() => isLoading = false);
  }
}


  Map<String, List<dynamic>> getFilteredProductsGrouped() {
    final filtered = products.where((product) {
      final alias = product['alias']?.toString().toLowerCase() ?? '';
      return alias.contains(searchQuery.toLowerCase());
    });

    final Map<String, List<dynamic>> grouped = {};
    for (var p in filtered) {
      final alias = p['alias'] ?? 'Unknown';
      grouped.putIfAbsent(alias, () => []).add(p);
    }

    return grouped;
  }

  void _refreshData() {
    setState(() {
      searchQuery = '';
      _controller.clear();
    });
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final groupedProducts = getFilteredProductsGrouped();
          final aliases = groupedProducts.keys.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'Search by Product Name',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => searchQuery = '');
                      },
                    ),
                  ),
                ),
              ),
              if (searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Filtering by: "$searchQuery"',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : aliases.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                            itemCount: aliases.length,
                            itemBuilder: (context, index) {
                              final alias = aliases[index];
                              final instances = groupedProducts[alias]!;
                              return ListTile(
                                leading: const Icon(Icons.inventory_2),
                                title: Text(
                                  alias,
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth > 600
                                        ? 18
                                        : 14,
                                  ),
                                ),
                                subtitle:
                                    Text('Instances: ${instances.length}'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      alias: alias,
                                      instances: instances,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final String alias;
  final List<dynamic> instances;

  const ProductDetailScreen({
    super.key,
    required this.alias,
    required this.instances,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final Map<String, Map<String, String>> shelfDetailsMap = {};

  @override
  void initState() {
    super.initState();
    fetchShelfDetailsForAll();
  }

  Future<void> fetchShelfDetailsForAll() async {
    for (final instance in widget.instances) {
      final objectId = instance['id']?['objectId'];
      final systemId = instance['id']?['systemID'];
      if (objectId != null && systemId != null) {
        print('🔍 Fetching parent shelf for Product: $objectId');
        final shelfInfo = await fetchParentShelf(systemId, objectId);
        print('📦 Shelf info for $objectId: $shelfInfo');
        setState(() {
          shelfDetailsMap[objectId] = shelfInfo;
        });
      }
    }
  }

  Future<Map<String, String>> fetchParentShelf(String systemId, String objectId) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';
    final baseUrl = 'http://localhost:8081';

    try {
      final url = Uri.parse('$baseUrl/ambient-intelligence/objects/$systemId/$objectId/parents?email=$userEmail');
      print('🌐 GET: $url');
      final response = await http.get(url, headers: {
        'X-System-ID': systemId,
        'X-User-Email': userEmail,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shelf = data.firstWhere(
          (item) =>
              item['type'] == 'Shelf' &&
              item['status']?.toLowerCase() == 'active' &&
              item['active'] == true,
          orElse: () => null,
        );

        if (shelf != null) {
          return {
            'shelf': shelf['alias'] ?? 'Unknown',
            'aisle': shelf['objectDetails']?['location'] ?? 'Unknown',
          };
        }
      } else {
        print('❌ Failed to fetch parent shelf: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching shelf: $e');
    }

    return {'shelf': 'Not assigned', 'aisle': 'Not assigned'};
  }

  Future<void> sendPendingAction({
    required BuildContext context,
    required String systemId,
    required String objectId,
  }) async {
    print('➡️ Assigning NFC to $objectId');
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';

    final url = Uri.parse('http://localhost:8081/ambient-intelligence/pending-action');
    final body = {
      "userEmail": userEmail,
      "actionType": "ASSIGN_NFC_TAG",
      "targetSystemId": systemId,
      "targetObjectId": objectId,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final message = (response.statusCode == 200 || response.statusCode == 204)
        ? '✅ PendingAction created — scan NFC now!'
        : '❌ Failed: ${response.statusCode}';
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

 Future<void> removeProductFromShelfById({
  required String systemId,
  required String email,
  required String objectId,
}) async {
  final url = Uri.parse('http://localhost:8081/ambient-intelligence/commands');
  final body = {
    "id": {
      "systemID": systemId,
      "commandId": "remove-${DateTime.now().millisecondsSinceEpoch}"
    },
    "command": "remove_product_by_id_from_shelf",
    "targetObject": {
      "id": {"systemID": systemId, "objectId": objectId}
    },
    "invokedBy": {
      "userId": {"systemID": systemId, "email": "end@test.com"}
    },
    "invocationTimestamp": DateTime.now().toIso8601String(),
    "commandAttributes": {
      "objectId": objectId,
      "systemID": systemId,
      "delete": false
    }
  };

  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  print('🧹 Unbind result: ${res.statusCode}');
}



  Future<void> assignToShelfDialog({
    required BuildContext context,
    required String productSystemId,
    required String productObjectId,
    required String nfcTag,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? '';
    final systemId = prefs.getString('system_id') ?? '';
    final baseUrl = 'http://localhost:8081';

    // Unbind if already assigned
    final shelfInfo = shelfDetailsMap[productObjectId];
    if (shelfInfo != null && shelfInfo['shelf'] != 'Not assigned') {
      await removeProductFromShelfById(
        systemId: systemId,
        email: userEmail,
        objectId: productObjectId,
      );
    }

    final response = await http.get(
      Uri.parse('$baseUrl/ambient-intelligence/objects/search/byType/Shelf?email=$userEmail'),
      headers: {'X-System-ID': systemId, 'X-User-Email': userEmail},
    );

    if (response.statusCode != 200) return;
    final shelves = jsonDecode(response.body);

    final selectedShelf = await showDialog<dynamic>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Shelf'),
        children: shelves.map<Widget>((shelf) {
          final alias = shelf['alias'] ?? 'Unnamed Shelf';
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, shelf),
            child: Text(alias),
          );
        }).toList(),
      ),
    );

    if (selectedShelf == null) return;

    final parentSystemId = selectedShelf['id']['systemID'];
    final parentObjectId = selectedShelf['id']['objectId'];

    final bindUrl = Uri.parse('$baseUrl/ambient-intelligence/objects/$parentSystemId/$parentObjectId/children?email=$userEmail');
    final body = {
      "childId": {"objectId": productObjectId, "systemID": productSystemId}
    };

    final bindRes = await http.put(
      bindUrl,
      headers: {
        'Content-Type': 'application/json',
        'X-System-ID': systemId,
        'X-User-Email': userEmail
      },
      body: jsonEncode(body),
    );

    if (bindRes.statusCode == 200 || bindRes.statusCode == 204) {
      final updatedShelf = await fetchParentShelf(productSystemId, productObjectId);
      setState(() {
        shelfDetailsMap[productObjectId] = updatedShelf;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details for "${widget.alias}"')),
      body: ListView.builder(
        itemCount: widget.instances.length,
        itemBuilder: (context, index) {
          final instance = widget.instances[index];
          final objectId = instance['id']?['objectId'] ?? 'Unknown ID';
          final systemId = instance['id']?['systemID'] ?? 'Unknown System';
          final objectDetails = instance['objectDetails'] ?? {};
          final nfcTag = objectDetails['nfcTag'] ?? '';
          final shelf = shelfDetailsMap[objectId]?['shelf'] ?? 'Not assigned';
          final aisle = shelfDetailsMap[objectId]?['aisle'] ?? 'Not assigned';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: $objectId'),
                        Text('NFC Tag: ${nfcTag.isEmpty ? 'Not assigned yet' : nfcTag}'),
                        Text('Location: Shelf: $shelf (Aisle: $aisle)'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.nfc),
                        tooltip: 'Assign NFC Tag',
                        onPressed: () => sendPendingAction(
                          context: context,
                          systemId: systemId,
                          objectId: objectId,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.move_to_inbox),
                        tooltip: 'Assign to Shelf',
                        onPressed: () => assignToShelfDialog(
                          context: context,
                          productSystemId: systemId,
                          productObjectId: objectId,
                          nfcTag: nfcTag,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}