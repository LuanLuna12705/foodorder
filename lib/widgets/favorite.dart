import 'package:flutter/material.dart';
import 'food_item.dart';

class FavoriteWidget extends StatelessWidget {
  final List<FoodItem> items;
  final Function(String id) onToggleFavoriteById;
  final Function(FoodItem item) onAddToCart;

  const FavoriteWidget({
    super.key,
    required this.items,
    required this.onToggleFavoriteById,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteItems = items.where((item) => item.isFavorite).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFFFF5722),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: const Text(
            'Món Ăn Yêu Thích ❤️',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: favoriteItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có món ăn nào trong danh sách yêu thích',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = favoriteItems[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Image.asset(
                            item.imagePath,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.orange.shade100,
                              child: const Icon(Icons.fastfood, color: Color(0xFFFF5722)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(
                                  item.price,
                                  style: const TextStyle(
                                    color: Color(0xFFFF5722),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () => onToggleFavoriteById(item.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFFFF5722)),
                                onPressed: () => onAddToCart(item),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
