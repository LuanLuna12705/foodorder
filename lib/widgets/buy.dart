import 'package:flutter/material.dart';
import 'food_item.dart';

class BuyWidget extends StatefulWidget {
  final List<FoodItem> cartItems;
  final Function(int index) onRemoveItem;
  final Function(int index, int newQuantity) onUpdateQuantity;
  final Function({
    required String address,
    required String paymentMethod,
    required int shippingFee,
    required int discount,
    required String voucherCode,
    required int totalPrice,
  }) onCheckoutWithDetails;

  const BuyWidget({
    super.key,
    required this.cartItems,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onCheckoutWithDetails,
  });

  @override
  State<BuyWidget> createState() => _BuyWidgetState();
}

class _BuyWidgetState extends State<BuyWidget> {
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(text: '123 Đường Cầu Giấy, Phường Dịch Vọng, Hà Nội');

  String _appliedVoucher = '';
  int _discountAmount = 0;
  final int _shippingFee = 15000;
  String _selectedPaymentMethod = 'Tiền mặt khi nhận hàng (COD)';

  @override
  void dispose() {
    _voucherController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int get _subtotal {
    int total = 0;
    for (var item in widget.cartItems) {
      total += item.rawPrice * item.quantity;
    }
    return total;
  }

  int get _grandTotal {
    final sub = _subtotal;
    if (sub == 0) return 0;
    final total = sub + _shippingFee - _discountAmount;
    return total > 0 ? total : 0;
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code == 'HELLOFood') {
      setState(() {
        _appliedVoucher = code;
        _discountAmount = 20000;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Áp dụng mã HELLOFood thành công! Giảm 20.000 đ'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (code == 'FREESHIP') {
      setState(() {
        _appliedVoucher = code;
        _discountAmount = _shippingFee;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Áp dụng mã FREESHIP thành công! Miễn phí vận chuyển'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã giảm giá không hợp lệ (Thử mã: HELLOFood hoặc FREESHIP)'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showCheckoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xác Nhận Đặt Hàng 🚴',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Địa chỉ giao hàng
                  const Text(
                    'Địa chỉ giao hàng:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF5722)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phương thức thanh toán
                  const Text(
                    'Phương thức thanh toán:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: [
                      RadioListTile<String>(
                        value: 'Tiền mặt khi nhận hàng (COD)',
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color(0xFFFF5722),
                        title: const Text('💵 Tiền mặt khi nhận hàng (COD)'),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedPaymentMethod = val!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        value: 'Ví điện tử MoMo (Mô phỏng)',
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color(0xFFFF5722),
                        title: const Text('📱 Ví điện tử MoMo'),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedPaymentMethod = val!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        value: 'Thẻ ATM / Ngân hàng (Mô phỏng)',
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color(0xFFFF5722),
                        title: const Text('💳 Thẻ ATM / Thẻ ghi nợ'),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedPaymentMethod = val!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total & Confirm button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16)),
                      Text(
                        _formatCurrency(_grandTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCheckoutWithDetails(
                          address: _addressController.text.trim(),
                          paymentMethod: _selectedPaymentMethod,
                          shippingFee: _shippingFee,
                          discount: _discountAmount,
                          voucherCode: _appliedVoucher,
                          totalPrice: _grandTotal,
                        );
                      },
                      child: const Text(
                        'XÁC NHẬN ĐẶT ĐƠN HÀNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Giỏ Hàng Của Bạn 🛒',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: widget.cartItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Giỏ hàng của bạn đang trống',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                item.imagePath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.orange.shade100,
                                  child: const Icon(Icons.fastfood, color: Color(0xFFFF5722)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.selectedSize.isNotEmpty)
                                    Text(
                                      'Size: ${item.selectedSize}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  if (item.selectedToppings.isNotEmpty)
                                    Text(
                                      'Topping: ${item.selectedToppings.join(', ')}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  if (item.customNote.isNotEmpty)
                                    Text(
                                      'Ghi chú: ${item.customNote}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(item.rawPrice),
                                    style: const TextStyle(
                                      color: Color(0xFFFF5722),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => widget.onUpdateQuantity(index, item.quantity - 1),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.remove, size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => widget.onUpdateQuantity(index, item.quantity + 1),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.add, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => widget.onRemoveItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (widget.cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Voucher input field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          decoration: InputDecoration(
                            hintText: 'Nhập mã giảm giá (Voucher)...',
                            prefixIcon: const Icon(Icons.card_giftcard, color: Color(0xFFFF5722)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _applyVoucher,
                        child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Details Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tạm tính:', style: TextStyle(color: Colors.grey)),
                      Text(_formatCurrency(_subtotal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phí giao hàng:', style: TextStyle(color: Colors.grey)),
                      Text(_formatCurrency(_shippingFee)),
                    ],
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Giảm giá ($_appliedVoucher):', style: const TextStyle(color: Colors.green)),
                        Text('-${_formatCurrency(_discountAmount)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatCurrency(_grandTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _showCheckoutDialog,
                      child: const Text(
                        'TIẾN HÀNH ĐẶT HÀNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
