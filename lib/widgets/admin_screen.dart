import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef DataMap = Map< String, dynamic >;

class AdminScreen extends StatefulWidget {
  final User user;

  const AdminScreen({super.key, required this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  String _selectedOrderStatus = 'Tất cả';
  bool _isImporting = false;

  final List< String > _orderStatuses = [
    'Tất cả',
    'Đang xử lý',
    'Đang giao',
    'Hoàn thành',
  ];

  final List< String > _categories = [
    'Cơm',
    'Bún/Phở',
    'Đồ ăn nhanh',
    'Trà sữa/Đồ uống',
    'Tráng miệng',
  ];

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Đang giao':
        return Colors.blue;
      case 'Đang xử lý':
      default:
        return Colors.orange;
    }
  }

  // Cập nhật trạng thái đơn hàng trên Firestore
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật đơn hàng sang trạng thái: $newStatus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật đơn hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Nạp nhanh dữ liệu mẫu từ assets/foods.json lên collection 'foods' trên Firestore
  Future<void> _importFromJsonToFirestore() async {
    setState(() => _isImporting = true);
    try {
      final jsonString = await rootBundle.loadString('assets/foods.json');
      final List< dynamic > jsonList = jsonDecode(jsonString);
      final foodsRef = FirebaseFirestore.instance.collection('foods');

      for (var item in jsonList) {
        final map = DataMap.from(item);
        final docId = (map['id'] ?? '').toString();
        if (docId.isNotEmpty) {
          await foodsRef.doc(docId).set(map);
        } else {
          await foodsRef.add(map);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đồng bộ ${jsonList.length} món từ foods.json lên Firestore!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nạp dữ liệu JSON: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // Dialog Thêm / Sửa món ăn
  void _showFoodFormDialog({String? docId, DataMap? existingData}) {
    final isEditing = docId != null;
    final titleController = TextEditingController(text: existingData?['title'] ?? '');
    final rawDigits = (existingData?['price'] ?? '').toString().replaceAll(RegExp(r'[^\d]'), '');
    final priceController = TextEditingController(text: rawDigits);
    final subtitleController = TextEditingController(text: existingData?['subtitle'] ?? '');
    final descController = TextEditingController(text: existingData?['description'] ?? '');
    final addressController = TextEditingController(
      text: existingData?['address'] ?? '123 Cầu Giấy, Hà Nội',
    );
    final imageController = TextEditingController(
      text: existingData?['imagePath'] ?? 'assets/images/food1.jpg',
    );

    String selectedCategory = existingData?['category'] ?? _categories.first;
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Ăn Mới',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên món ăn *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giá bán (VNĐ, VD: 45000) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField< String >(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả ngắn (Subtitle)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả chi tiết',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ quán',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn ảnh (assets/images/...)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: ['food1.jpg', 'food2.jpg', 'food3.jpg'].map((img) {
                        final path = 'assets/images/$img';
                        return ActionChip(
                          label: Text(img, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() => imageController.text = path);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final numericPrice =
                        int.tryParse(priceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

                    if (title.isEmpty || numericPrice <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên món và giá hợp lệ!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final formattedPrice = _formatCurrency(numericPrice);
                    final foodsRef = FirebaseFirestore.instance.collection('foods');

                    final DataMap payload = {
                      'title': title,
                      'price': formattedPrice,
                      'category': selectedCategory,
                      'subtitle': subtitleController.text.trim().isEmpty
                          ? selectedCategory.toUpperCase()
                          : subtitleController.text.trim(),
                      'description': descController.text.trim(),
                      'address': addressController.text.trim(),
                      'imagePath': imageController.text.trim().isEmpty
                          ? 'assets/images/food1.jpg'
                          : imageController.text.trim(),
                      'rating': existingData?['rating'] ?? 4.8,
                      'sizes': existingData?['sizes'] ?? [],
                      'toppings': existingData?['toppings'] ?? [],
                    };

                    Navigator.pop(ctx);

                    if (isEditing) {
                      await foodsRef.doc(docId).update(payload);
                    } else {
                      final newDoc = foodsRef.doc();
                      payload['id'] = newDoc.id;
                      await newDoc.set(payload);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing ? 'Đã cập nhật món "$title"' : 'Đã thêm món "$title"',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEditing ? 'Lưu thay đổi' : 'Thêm món',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Xác nhận xóa món ăn
  Future<void> _confirmDeleteFood(String docId, String title) async {
    final confirm = await showDialog< bool >(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa món ăn'),
        content: Text('Bạn có chắc chắn muốn xóa món "$title" khỏi thực đơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('foods').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa món "$title"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Giao diện Tab 1: Quản lý đơn hàng
  Widget _buildOrdersTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: _orderStatuses.map((status) {
              final isSelected = _selectedOrderStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF5722),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _selectedOrderStatus = status),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder< QuerySnapshot >(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi tải đơn hàng: ${snapshot.error}'));
              }

              final allDocs = snapshot.data?.docs.toList() ?? [];
              allDocs.sort((a, b) {
                final tA = (a.data() as DataMap)['createdAt'] as Timestamp?;
                final tB = (b.data() as DataMap)['createdAt'] as Timestamp?;
                if (tA == null || tB == null) return 0;
                return tB.compareTo(tA);
              });

              final filteredDocs = allDocs.where((doc) {
                if (_selectedOrderStatus == 'Tất cả') return true;
                final status = (doc.data() as DataMap)['status'] ?? 'Đang xử lý';
                return status == _selectedOrderStatus;
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có đơn hàng nào trong mục này',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as DataMap;
                  final items = List< DataMap >.from(data['items'] ?? []);
                  final status = data['status'] ?? 'Đang xử lý';
                  final userEmail = data['userEmail'] ?? 'Khách hàng';
                  final address = data['deliveryAddress'] ?? 'Chưa có địa chỉ';
                  final paymentMethod = data['paymentMethod'] ?? 'COD';
                  final totalPrice = (data['totalPrice'] as num? ?? 0).toInt();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đơn #${doc.id.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _getStatusColor(status)),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Khách: $userEmail',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const Divider(height: 18),
                          ...items.map((item) {
                            final title = item['title'] ?? '';
                            final qty = item['quantity'] ?? 1;
                            final size = item['selectedSize'] ?? '';
                            final toppings = List< String >.from(item['selectedToppings'] ?? []);
                            final note = item['customNote'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${qty}x $title',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (size.toString().isNotEmpty || toppings.isNotEmpty)
                                    Text(
                                      [
                                        if (size.toString().isNotEmpty) 'Size: $size',
                                        if (toppings.isNotEmpty) 'Topping: ${toppings.join(', ')}',
                                      ].join(' | '),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  if (note.toString().isNotEmpty)
                                    Text(
                                      'Ghi chú: $note',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 18),
                          Text('📍 Địa chỉ: $address', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('💳 Thanh toán: $paymentMethod', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng: ${_formatCurrency(totalPrice)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                              if (status == 'Đang xử lý')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _updateOrderStatus(doc.id, 'Đang giao'),
                                  icon: const Icon(Icons.delivery_dining, color: Colors.white, size: 18),
                                  label: const Text(
                                    'Duyệt & Giao hàng',
                                    style: TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                )
                              else if (status == 'Đang giao')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _updateOrderStatus(doc.id, 'Hoàn thành'),
                                  icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  label: const Text(
                                    'Hoàn thành đơn',
                                    style: TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.green, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đã giao xong',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Giao diện Tab 2: Quản lý thực đơn (CRUD)
  Widget _buildMenuTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách món trên Cloud',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              OutlinedButton.icon(
                onPressed: _isImporting ? null : _importFromJsonToFirestore,
                icon: _isImporting
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Nạp từ foods.json', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5722),
                  side: const BorderSide(color: Color(0xFFFF5722)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder< QuerySnapshot >(
            stream: FirebaseFirestore.instance.collection('foods').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi tải thực đơn: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có món ăn nào trên Cloud Firestore',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                        onPressed: _importFromJsonToFirestore,
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: const Text(
                          'Đồng bộ thực đơn từ foods.json ngay',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as DataMap;
                  final title = data['title'] ?? '';
                  final price = data['price'] ?? '0 đ';
                  final category = data['category'] ?? '';
                  final imagePath = data['imagePath'] ?? 'assets/images/food1.jpg';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          imagePath,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.orange.shade100,
                            child: const Icon(Icons.fastfood, color: Color(0xFFFF5722)),
                          ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFFFF5722),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Sửa món',
                            onPressed: () => _showFoodFormDialog(docId: doc.id, existingData: data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Xóa món',
                            onPressed: () => _confirmDeleteFood(doc.id, title),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header Admin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5722),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.admin_panel_settings, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quản Trị Hệ Thống 🛠️',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.user.email ?? 'Admin',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Đăng xuất',
                    onPressed: () async => await FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _currentIndex == 0 ? _buildOrdersTab() : _buildMenuTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF5722),
        onPressed: () => _showFoodFormDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm món', style: TextStyle(color: Colors.white)),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Quản lý Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Quản lý Thực đơn',
          ),
        ],
      ),
    );
  }
}