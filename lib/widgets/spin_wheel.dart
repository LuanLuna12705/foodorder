import 'dart:math';
import 'package:flutter/material.dart';
import 'food_item.dart';

class SpinWheelWidget extends StatefulWidget {
  final List<FoodItem> items;
  final Function(FoodItem item) onAddToCart;

  const SpinWheelWidget({
    super.key,
    required this.items,
    required this.onAddToCart,
  });

  @override
  State<SpinWheelWidget> createState() => _SpinWheelWidgetState();
}

class _SpinWheelWidgetState extends State<SpinWheelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  FoodItem? _selectedFood;
  bool _isSpinning = false;

  // Bộ lọc quay
  String _selectedCategory = 'Tất cả';
  String _selectedPriceRange = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Cơm',
    'Bún/Phở',
    'Đồ ăn nhanh',
    'Trà sữa/Đồ uống',
    'Tráng miệng',
  ];

  final List<String> _priceRanges = [
    'Tất cả',
    'Dưới 50K',
    '50K - 100K',
    'Trên 100K',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FoodItem> get _filteredItems {
    return widget.items.where((item) {
      final matchesCategory =
          _selectedCategory == 'Tất cả' || item.category == _selectedCategory;

      final price = item.rawPrice;
      bool matchesPrice = true;
      if (_selectedPriceRange == 'Dưới 50K') {
        matchesPrice = price < 50000;
      } else if (_selectedPriceRange == '50K - 100K') {
        matchesPrice = price >= 50000 && price <= 100000;
      } else if (_selectedPriceRange == 'Trên 100K') {
        matchesPrice = price > 100000;
      }

      return matchesCategory && matchesPrice;
    }).toList();
  }

  void _spin() {
    final available = _filteredItems;
    if (_isSpinning || available.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _selectedFood = null;
    });

    _controller.forward(from: 0).then((_) {
      final random = Random();
      final pickedIndex = random.nextInt(available.length);
      setState(() {
        _selectedFood = available[pickedIndex];
        _isSpinning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableItems = _filteredItems;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFFF5722),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vòng Quay May Mắn 🎰',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hãy để vòng quay ngẫu nhiên chọn món ăn hấp dẫn cho bạn!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // 1. Kết quả món quay được hiển thị ở TRÊN ĐẦU (khi đã quay)
          if (_selectedFood != null) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF5722), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎉 Gợi ý món ăn quay được 🎉',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _selectedFood!.imagePath,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: Colors.orange.shade100,
                        child: const Icon(Icons.fastfood, size: 50, color: Color(0xFFFF5722)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFood!.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFood!.price,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => widget.onAddToCart(_selectedFood!),
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: const Text('Thêm vào giỏ hàng', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 2. Vòng quay (Giữ hình xúc xắc, BỎ CHỮ QUAY NGAY)
          Center(
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 5.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.decelerate),
              ),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFFF5722),
                      Colors.orange,
                      Colors.amber,
                      Colors.deepOrangeAccent,
                      Color(0xFFFF5722),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.casino,
                        size: 64,
                        color: _isSpinning ? Colors.orange : const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nút quay
          ElevatedButton.icon(
            onPressed: (_isSpinning || availableItems.isEmpty) ? null : _spin,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              _isSpinning
                  ? 'Đang chọn món...'
                  : (availableItems.isEmpty ? 'Không có món phù hợp' : 'Bắt đầu quay'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Bộ lọc món ăn ở DƯỚI CÙNG
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: Color(0xFFFF5722), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Bộ lọc danh mục & Giá tiền',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Chọn loại đồ ăn
                    const Text('Loại đồ ăn:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF5722),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Chọn khoảng giá
                    const Text('Khoảng giá:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _priceRanges.map((price) {
                          final isSelected = _selectedPriceRange == price;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(price),
                              selected: isSelected,
                              selectedColor: Colors.amber.shade800,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPriceRange = price;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Số món phù hợp: ${availableItems.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: availableItems.isNotEmpty ? Colors.green.shade700 : Colors.red,
                          ),
                        ),
                        if (_selectedCategory != 'Tất cả' || _selectedPriceRange != 'Tất cả')
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = 'Tất cả';
                                _selectedPriceRange = 'Tất cả';
                              });
                            },
                            child: const Text(
                              'Đặt lại bộ lọc',
                              style: TextStyle(color: Color(0xFFFF5722), fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
