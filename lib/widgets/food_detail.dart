import 'package:flutter/material.dart';
import 'food_item.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem item;
  final Function(FoodItem item) onAddToCart;

  const FoodDetailScreen({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late String _selectedSize;
  late Set<String> _selectedToppings;
  final TextEditingController _noteController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.item.sizes.isNotEmpty ? widget.item.sizes.first['name'] : '';
    _selectedToppings = {};
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _calculatedUnitPrice {
    int base = widget.item.rawPrice;

    // Cộng thêm giá size
    if (widget.item.sizes.isNotEmpty) {
      final sizeObj = widget.item.sizes.firstWhere(
        (element) => element['name'] == _selectedSize,
        orElse: () => {},
      );
      if (sizeObj.containsKey('extraPrice')) {
        base += (sizeObj['extraPrice'] as num).toInt();
      }
    }

    // Cộng thêm giá topping
    for (var topName in _selectedToppings) {
      final topObj = widget.item.toppings.firstWhere(
        (element) => element['name'] == topName,
        orElse: () => {},
      );
      if (topObj.containsKey('price')) {
        base += (topObj['price'] as num).toInt();
      }
    }

    return base;
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  void _handleAddToCart() {
    final customizedItem = widget.item.copyWith(
      quantity: _quantity,
      selectedSize: _selectedSize,
      selectedToppings: _selectedToppings.toList(),
      customNote: _noteController.text.trim(),
      customPrice: _calculatedUnitPrice,
    );

    widget.onAddToCart(customizedItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = _calculatedUnitPrice;
    final totalPrice = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.item.title, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image
                    Image.asset(
                      widget.item.imagePath,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        color: Colors.orange.shade100,
                        child: const Icon(Icons.fastfood, size: 80, color: Color(0xFFFF5722)),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.item.rating}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.item.address,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 12),

                          // Base price display
                          Text(
                            widget.item.price,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          if (widget.item.description.isNotEmpty) ...[
                            const Text(
                              'Mô tả món ăn',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.description,
                              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                            ),
                            const Divider(height: 28),
                          ],

                          // Size Selection
                          if (widget.item.sizes.isNotEmpty) ...[
                            const Text(
                              'Chọn Kích Cỡ (Size)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: widget.item.sizes.map((s) {
                                final name = s['name'] as String;
                                final extra = (s['extraPrice'] as num).toInt();
                                final isSelected = _selectedSize == name;

                                return RadioListTile<String>(
                                  value: name,
                                  groupValue: _selectedSize,
                                  activeColor: const Color(0xFFFF5722),
                                  title: Text(name),
                                  secondary: extra > 0 ? Text('+${_formatCurrency(extra)}') : const Text('+0 đ'),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedSize = val;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const Divider(height: 28),
                          ],

                          // Topping Selection
                          if (widget.item.toppings.isNotEmpty) ...[
                            const Text(
                              'Thêm Topping đi kèm',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: widget.item.toppings.map((t) {
                                final name = t['name'] as String;
                                final price = (t['price'] as num).toInt();
                                final isSelected = _selectedToppings.contains(name);

                                return CheckboxListTile(
                                  value: isSelected,
                                  activeColor: const Color(0xFFFF5722),
                                  title: Text(name),
                                  secondary: Text('+${_formatCurrency(price)}'),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedToppings.add(name);
                                      } else {
                                        _selectedToppings.remove(name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const Divider(height: 28),
                          ],

                          // Custom Note
                          const Text(
                            'Ghi chú riêng cho quán',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: Ít đường, không hành, cho thêm tương ớt...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  // Quantity controller
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF5722)),
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF5722)),
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Add to cart button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleAddToCart,
                        child: Text(
                          'Thêm • ${_formatCurrency(totalPrice)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
