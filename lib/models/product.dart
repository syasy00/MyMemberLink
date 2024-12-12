import 'dart:developer';

class Product {
  String id;
  String name;
  String description;
  String imageUrl;
  double price;
  int quantity;
  String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        imageUrl: json['image_url'] ?? '',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
        category: json['category'] ?? '',
      );
    } catch (e) {
      log("Error in Product.fromJson: $e");
      throw e;
    }
  }
}
