import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_member_link/myconfig.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartItems = [];
  bool isLoading = false;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<Map<String, String?>> _getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      "username": prefs.getString('username'),
      "useremail": prefs.getString('useremail'),
    };
  }

  Future<void> _loadCartItems() async {
    setState(() => isLoading = true);

    try {
      final userDetails = await _getUserDetails();
      if (userDetails['username'] == null || userDetails['useremail'] == null) {
        _showSnackbar("User not logged in.");
        return;
      }

      final response = await http.get(Uri.parse(
          "${MyConfig.servername}/memberlink/api/get_cart_items.php?username=${userDetails['username']}&useremail=${userDetails['useremail']}"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            cartItems = data['data'];
            totalPrice = _calculateTotalPrice();
          });
        } else {
          _showSnackbar(data['message']);
        }
      } else {
        _showSnackbar("Failed to load cart items. Code: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackbar("Error loading cart items: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  double _calculateTotalPrice() {
    return cartItems.fold(
      0.0,
      (sum, item) {
        double price = double.tryParse(item['price'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['quantity'].toString()) ?? 0;
        return sum + (price * quantity);
      },
    );
  }

  Future<void> _updateCartItem(int productId, int quantity) async {
    try {
      final userDetails = await _getUserDetails();
      if (userDetails['username'] == null || userDetails['useremail'] == null) {
        _showSnackbar("User not logged in.");
        return;
      }

      final response = await http.post(
        Uri.parse("${MyConfig.servername}/memberlink/api/update_cart.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": userDetails['username'],
          "useremail": userDetails['useremail'],
          "product_id": productId,
          "quantity": quantity,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _showSnackbar(responseData['message']);
        _loadCartItems();
      } else {
        _showSnackbar(responseData['message']);
      }
    } catch (e) {
      _showSnackbar("Error updating cart item: $e");
    }
  }

  Future<void> _removeCartItem(int productId) async {
    try {
      final userDetails = await _getUserDetails();
      if (userDetails['username'] == null || userDetails['useremail'] == null) {
        _showSnackbar("User not logged in.");
        return;
      }

      final response = await http.post(
        Uri.parse("${MyConfig.servername}/memberlink/api/remove_cart_item.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": userDetails['username'],
          "useremail": userDetails['useremail'],
          "product_id": productId,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _showSnackbar(responseData['message']);
        _loadCartItems();
      } else {
        _showSnackbar(responseData['message']);
      }
    } catch (e) {
      _showSnackbar("Error removing cart item: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("My Bag"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(
                  child: Text(
                    "Your bag is empty.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _buildCartContent(),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              double price = double.tryParse(item['price'].toString()) ?? 0.0;
              int quantity = int.tryParse(item['quantity'].toString()) ?? 0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(item['image_url']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "RM ${price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildIconButton(Icons.remove, () {
                                if (quantity > 1) {
                                  _updateCartItem(item['product_id'], quantity - 1);
                                }
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  "$quantity",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              _buildIconButton(Icons.add, () {
                                _updateCartItem(item['product_id'], quantity + 1);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCartItem(item['product_id']),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildCartFooter(),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: Icon(icon, size: 18, color: Colors.black),
      ),
    );
  }

  Widget _buildCartFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                "RM ${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Proceed to checkout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Checkout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
