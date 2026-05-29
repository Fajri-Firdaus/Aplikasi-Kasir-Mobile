class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.stock,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? imageUrl,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
    );
  }
}
