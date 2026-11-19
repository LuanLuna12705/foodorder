class FoodItem {
  final String id;
  final String title;
  final String price;
  final String category;
  final String subtitle;
  final String description;
  final double rating;
  final String address;
  final String imagePath;
  bool isFavorite;
  int quantity;

  // Tùy biến món ăn
  String selectedSize;
  List<String> selectedToppings;
  String customNote;
  int customPrice; // Giá riêng khi đã cộng size + topping

  final List<Map<String, dynamic>> sizes;
  final List<Map<String, dynamic>> toppings;

  FoodItem({
    required this.id,
    required this.title,
    required this.price,
    this.category = 'Tất cả',
    required this.subtitle,
    this.description = '',
    this.rating = 4.5,
    required this.address,
    required this.imagePath,
    this.isFavorite = false,
    this.quantity = 1,
    this.selectedSize = '',
    List<String>? selectedToppings,
    this.customNote = '',
    int? customPrice,
    List<Map<String, dynamic>>? sizes,
    List<Map<String, dynamic>>? toppings,
  })  : selectedToppings = selectedToppings ?? [],
        sizes = sizes ?? [],
        toppings = toppings ?? [],
        customPrice = customPrice ?? 0;

  FoodItem copyWith({
    String? id,
    String? title,
    String? price,
    String? category,
    String? subtitle,
    String? description,
    double? rating,
    String? address,
    String? imagePath,
    bool? isFavorite,
    int? quantity,
    String? selectedSize,
    List<String>? selectedToppings,
    String? customNote,
    int? customPrice,
    List<Map<String, dynamic>>? sizes,
    List<Map<String, dynamic>>? toppings,
  }) {
    return FoodItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedToppings: selectedToppings ?? List.from(this.selectedToppings),
      customNote: customNote ?? this.customNote,
      customPrice: customPrice ?? this.customPrice,
      sizes: sizes ?? List.from(this.sizes),
      toppings: toppings ?? List.from(this.toppings),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'category': category,
      'subtitle': subtitle,
      'description': description,
      'rating': rating,
      'address': address,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedToppings': selectedToppings,
      'customNote': customNote,
      'customPrice': customPrice,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map, {required String docId}) {
    return FoodItem(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      title: map['title'] ?? '',
      price: map['price'] ?? '0 đ',
      category: map['category'] ?? 'Tất cả',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      address: map['address'] ?? '',
      imagePath: map['imagePath'] ?? 'assets/images/food1.jpg',
      isFavorite: map['isFavorite'] ?? false,
      quantity: map['quantity'] ?? 1,
      selectedSize: map['selectedSize'] ?? '',
      selectedToppings: List<String>.from(map['selectedToppings'] ?? []),
      customNote: map['customNote'] ?? '',
      customPrice: map['customPrice'] ?? 0,
      sizes: List<Map<String, dynamic>>.from(map['sizes'] ?? []),
      toppings: List<Map<String, dynamic>>.from(map['toppings'] ?? []),
    );
  }

  int get rawPrice {
    if (customPrice > 0) return customPrice;
    final cleaned = price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
