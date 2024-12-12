import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_member_link/myconfig.dart';
import '../mydrawer.dart';
import 'cart_screen.dart';
import 'package:my_member_link/models/product.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
  bool isLoading = false;
  int currentPage = 1;
  int totalPages = 1;
  int cartItemCount = 0;

  Product? selectedProductDetails; // Selected product details
  bool isProductDetailsVisible = false; // Visibility of product details overlay
  int selectedQuantity = 1; // Quantity for the selected product

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_loadProducts(), _getCartItemCount()]);
  }

  Future<String?> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<String?> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('useremail');
  }

  Future<void> _loadProducts({int page = 1, String? category}) async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
          "${MyConfig.servername}/memberlink/api/load_products.php?page=$page${category != null ? "&category=$category" : ""}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the response and the parsed data for debugging
        debugPrint("Response body: ${response.body}");
        debugPrint("Parsed data: ${data['data']}");

        if (data['status'] == 'success') {
          setState(() {
            products = (data['data'] as List)
                .map((item) {
                  try {
                    return Product.fromJson(item);
                  } catch (e) {
                    debugPrint("Error parsing product: $e");
                    return null; // If parsing fails for an item, handle it gracefully
                  }
                })
                .where((product) => product != null)
                .cast<Product>()
                .toList();
            currentPage = page;
            totalPages = data['total_pages'] ?? 1;
          });
        } else {
          _showSnackbar("Error loading products: ${data['message']}");
        }
      } else {
        _showSnackbar(
            "Failed to load products. Server error: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("An error occurred: $e");
      debugPrint("Stack trace: $stackTrace");
      _showSnackbar("An error occurred: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getCartItemCount() async {
    try {
      final username = await _getUsername();
      final useremail = await _getUserEmail();
      if (username == null || useremail == null) {
        debugPrint("User not logged in.");
        return;
      }

      final response = await http.get(Uri.parse(
          "${MyConfig.servername}/memberlink/api/get_cart_count.php?username=$username&useremail=$useremail"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            cartItemCount = data['count'] ?? 0;
          });
        } else {
          debugPrint("Error fetching cart count: ${data['message']}");
        }
      } else {
        debugPrint(
            "Failed to fetch cart count. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching cart count: $e");
    }
  }

  Future<void> _loadProductDetails(int productId) async {
    try {
      setState(() => isLoading = true);
      final response = await http.get(Uri.parse(
          "${MyConfig.servername}/memberlink/api/product_details.php?product_id=$productId"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            selectedProductDetails = Product.fromJson(
                data['data']); // Changed to use Product.fromJson
            isProductDetailsVisible = true;
          });
        } else {
          _showSnackbar("Error loading product details: ${data['message']}");
        }
      } else {
        _showSnackbar("Failed to load product details.");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _hideProductDetails() {
    setState(() {
      isProductDetailsVisible = false;
      selectedProductDetails = null;
      selectedQuantity = 1; // Reset the quantity
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Membership Products",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to the cart screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(),
                    ),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$cartItemCount",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer:
          MyDrawer(activePage: "Products"), // Proper placement of the MyDrawer
      body: Stack(
        children: [
          // Main Product List
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildProductList(),

          // Overlay for Product Details
          if (isProductDetailsVisible) _buildProductDetailsOverlay(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No Products Available",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Check back later for more exciting products!",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Go back to the previous screen
                _loadProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                "Back",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          _buildCategories(),
          _buildProductGrid(),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/product_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("NEW COLLECTIONS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("20% OFF",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final List<Map<String, String>> categories = [
      {"title": "All", "image": "assets/merch.png"},
      {"title": "Clothing", "image": "assets/clothing.png"},
      {"title": "Drinkware", "image": "assets/drinkware.png"},
      {"title": "Accessories", "image": "assets/accessories.png"},
      {"title": "Office Supplies", "image": "assets/office_supplies.png"},
      {"title": "Gift Items", "image": "assets/gift_items.png"},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Shop By Category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                return _buildCategoryItem(
                    category['title']!, category['image']!);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index]; // Access Product instance
          return GestureDetector(
            onTap: () => _loadProductDetails(int.parse(product.id)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        product.imageUrl, // Changed to product.imageUrl
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name, // Changed to product.name
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RM${product.price}", // Changed to product.price
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Page Button
          IconButton(
            icon: Icon(Icons.chevron_left,
                color: currentPage > 1 ? Colors.blue : Colors.grey),
            onPressed: currentPage > 1
                ? () => _loadProducts(page: currentPage - 1)
                : null,
          ),

          // Page Numbers
          ...List.generate(
            totalPages,
            (index) {
              final pageNumber = index + 1;
              return GestureDetector(
                onTap: () => _loadProducts(page: pageNumber),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: pageNumber == currentPage
                        ? const Color.fromARGB(255, 0, 0, 0)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pageNumber.toString(),
                    style: TextStyle(
                      color: pageNumber == currentPage
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.chevron_right,
                color: currentPage < totalPages
                    ? const Color.fromARGB(255, 0, 0, 0)
                    : Colors.grey),
            onPressed: currentPage < totalPages
                ? () => _loadProducts(page: currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        if (title == "All") {
          // Load all products
          _loadProducts();
        } else {
          // Load products filtered by the selected category
          _loadProducts(category: title.toLowerCase());
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addToCart(int productId, int quantity) async {
    try {
      final username = await _getUsername();
      final useremail = await _getUserEmail();
      if (username == null || useremail == null) {
        _showSnackbar("Please log in to add items to the cart.");
        return;
      }

      final response = await http.post(
        Uri.parse("${MyConfig.servername}/memberlink/api/add_to_cart.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "useremail": useremail,
          "product_id": productId,
          "quantity": quantity,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _showSnackbar("Added to cart successfully!");
        _getCartItemCount(); // Update cart item count dynamically
      } else {
        _showSnackbar(
            "Failed to add to cart. ${responseData['message'] ?? ''}");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    }
  }

  Widget _buildProductDetailsOverlay() {
    if (selectedProductDetails == null) return SizedBox.shrink();

    final product = selectedProductDetails!; 
    return GestureDetector(
      onTap: _hideProductDetails,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _hideProductDetails,
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl, 
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name, 
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Category: ${product.category}", 
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "In Stock: ${product.quantity}", 
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RM${product.price}", 
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description, 
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: selectedQuantity > 1
                            ? () => setState(() => selectedQuantity--)
                            : null,
                      ),
                      Text(
                        "$selectedQuantity",
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => selectedQuantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedProductDetails != null) {
                          int productId = int.parse(product.id);
                          addToCart(productId, selectedQuantity);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
