import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'widgets/food_item.dart';
import 'widgets/home.dart';
import 'widgets/favorite.dart';
import 'widgets/buy.dart';
import 'widgets/login_screen.dart';
import 'widgets/spin_wheel.dart';
import 'widgets/order_history.dart';
import 'widgets/admin_screen.dart';

// Tài khoản email quy định quyền Admin
const String kAdminEmail = 'admin@foodorder.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainFinalApp());
}

class MainFinalApp extends StatelessWidget {
  const MainFinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hôm nay ăn gì?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5722)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5722)),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final currentUser = snapshot.data!;
            if (currentUser.email?.trim().toLowerCase() == kAdminEmail) {
              return AdminScreen(user: currentUser);
            }
            return MainFinalScreen(user: currentUser);
          }
          return const LoginRegisterScreen();
        },
      ),
    );
  }
}

class MainFinalScreen extends StatefulWidget {
  final User user;
  const MainFinalScreen({super.key, required this.user});

  @override
  State<MainFinalScreen> createState() => _MainFinalScreenState();
}

class _MainFinalScreenState extends State<MainFinalScreen> {
  int _currentIndex = 0;
  List<FoodItem> _foodItems = [];
  final List<FoodItem> _cartItems = [];
  Set<String> _favIds = {};
  StreamSubscription<QuerySnapshot>? _foodsSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _foodsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadFoodItemsFromJson();
    await _loadUserDataFromFirestore();
    await _autoSyncFoodsJsonToFirestore();
    _listenFoodsFromFirestore();
  }

  // Tự động đồng bộ thực đơn & đường dẫn ảnh mới từ assets/foods.json lên Cloud Firestore
  Future<void> _autoSyncFoodsJsonToFirestore() async {
    try {
      final jsonString = await rootBundle.loadString('assets/foods.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final foodsRef = FirebaseFirestore.instance.collection('foods');

      for (var item in jsonList) {
        final map = Map<String, dynamic>.from(item);
        final docId = (map['id'] ?? '').toString();
        if (docId.isNotEmpty) {
          await foodsRef.doc(docId).set(map, SetOptions(merge: true));
        }
      }
    } catch (_) {}
  }

  // Lắng nghe thực đơn thời gian thực từ Cloud Firestore (khi Admin thêm/sửa/xóa món)
  void _listenFoodsFromFirestore() {
    _foodsSubscription = FirebaseFirestore.instance
        .collection('foods')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final cloudFoods = snapshot.docs.map((doc) {
          final item = FoodItem.fromMap(doc.data(), docId: doc.id);
          item.isFavorite = _favIds.contains(item.id);
          return item;
        }).toList();

        setState(() {
          _foodItems = cloudFoods;
        });
      }
    });
  }

  // Nạp dữ liệu dự phòng từ file assets/foods.json
  Future<void> _loadFoodItemsFromJson() async {
    try {
      final jsonString = await rootBundle.loadString('assets/foods.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final loadedItems =
      jsonList.map((e) => FoodItem.fromMap(e, docId: e['id'] ?? '')).toList();

      if (mounted && _foodItems.isEmpty) {
        setState(() {
          _foodItems = loadedItems;
        });
      }
    } catch (_) {
      if (mounted && _foodItems.isEmpty) {
        setState(() {
          _foodItems = [
            FoodItem(
              id: '1',
              title: 'Gà rán Jollibee',
              price: '49.000 đ',
              category: 'Đồ ăn nhanh',
              subtitle: 'GÀ RÁN GIÒN CAY',
              address: '123 Cầu Giấy, Hà Nội',
              imagePath: 'assets/images/food1.jpg',
            ),
            FoodItem(
              id: '2',
              title: 'Bánh mì pate trứng',
              price: '25.000 đ',
              category: 'Đồ ăn nhanh',
              subtitle: 'BÁNH MÌ GIÒN NÓNG',
              address: '15 Hàng Bạc, Hà Nội',
              imagePath: 'assets/images/food4.png',
            ),
            FoodItem(
              id: '3',
              title: 'Trà sữa trân châu',
              price: '35.000 đ',
              category: 'Trà sữa/Đồ uống',
              subtitle: 'ĐƯỜNG ĐEN THƠM NGỌT',
              address: '88 Chùa Lạng, Hà Nội',
              imagePath: 'assets/images/food5.png',
            ),
            FoodItem(
              id: '4',
              title: 'Cơm tấm sườn nướng',
              price: '45.000 đ',
              category: 'Cơm',
              subtitle: 'SƯỜN BÌ CHẢ ĐẶC BIỆT',
              address: '102 Nguyễn Trãi, Hà Nội',
              imagePath: 'assets/images/food6.png',
            ),
            FoodItem(
              id: '5',
              title: 'Phở bò tái lăn',
              price: '48.000 đ',
              category: 'Bún/Phở',
              subtitle: 'PHỞ BÒ HÀ NỘI GIA TRUYỀN',
              address: '13 Lò Đúc, Hà Nội',
              imagePath: 'assets/images/food7.png',
            ),
          ];
        });
      }
    }
  }

  // Tải dữ liệu danh sách yêu thích và giỏ hàng theo UID tài khoản
  Future<void> _loadUserDataFromFirestore() async {
    try {
      final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(widget.user.uid);

      final favSnapshot = await userDocRef.collection('favorites').get();
      final loadedFavIds = favSnapshot.docs.map((doc) => doc.id).toSet();

      final cartSnapshot = await userDocRef.collection('cart').get();
      final loadedCartItems = <FoodItem>[];
      for (var doc in cartSnapshot.docs) {
        loadedCartItems.add(FoodItem.fromMap(doc.data(), docId: doc.id));
      }

      if (mounted) {
        setState(() {
          _favIds = loadedFavIds;
          for (var item in _foodItems) {
            item.isFavorite = _favIds.contains(item.id);
          }
          _cartItems.clear();
          _cartItems.addAll(loadedCartItems);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveFavoriteToFirestore(FoodItem item) async {
    try {
      final favDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('favorites')
          .doc(item.id);

      if (item.isFavorite) {
        _favIds.add(item.id);
        await favDocRef.set(item.toMap());
      } else {
        _favIds.remove(item.id);
        await favDocRef.delete();
      }
    } catch (_) {}
  }

  Future<void> _saveCartToFirestore() async {
    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('cart');

      final existingDocs = await cartRef.get();
      for (var doc in existingDocs.docs) {
        await doc.reference.delete();
      }

      for (var item in _cartItems) {
        await cartRef.doc(item.id).set(item.toMap());
      }
    } catch (_) {}
  }

  void _toggleFavoriteByIndex(int index) {
    setState(() {
      _foodItems[index].isFavorite = !_foodItems[index].isFavorite;
    });
    _saveFavoriteToFirestore(_foodItems[index]);
  }

  void _toggleFavoriteById(String id) {
    final itemIndex = _foodItems.indexWhere((element) => element.id == id);
    if (itemIndex >= 0) {
      setState(() {
        _foodItems[itemIndex].isFavorite = !_foodItems[itemIndex].isFavorite;
      });
      _saveFavoriteToFirestore(_foodItems[itemIndex]);
    }
  }

  void _addToCart(FoodItem item) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((element) =>
      element.id == item.id &&
          element.selectedSize == item.selectedSize &&
          element.selectedToppings.join(',') == item.selectedToppings.join(','));

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += item.quantity;
      } else {
        _cartItems.add(item);
      }
    });
    _saveCartToFirestore();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${item.title}" vào giỏ hàng!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFFF5722),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _updateCartQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
    });
    _saveCartToFirestore();
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
    _saveCartToFirestore();
  }

  Future<void> _checkoutWithDetails({
    required String address,
    required String paymentMethod,
    required int shippingFee,
    required int discount,
    required String voucherCode,
    required int totalPrice,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': widget.user.uid,
        'userEmail': widget.user.email,
        'items': _cartItems.map((e) => e.toMap()).toList(),
        'deliveryAddress': address,
        'paymentMethod': paymentMethod,
        'shippingFee': shippingFee,
        'discount': discount,
        'voucherCode': voucherCode,
        'totalPrice': totalPrice,
        'status': 'Đang xử lý',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _cartItems.clear();
      });
      _saveCartToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thành công! Kiểm tra trạng thái trong Lịch sử đơn hàng.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _currentIndex = 4;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đặt hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeWidget(
        items: _foodItems,
        onToggleFavorite: _toggleFavoriteByIndex,
        onAddToCart: _addToCart,
        onLogout: _logout,
      ),
      FavoriteWidget(
        items: _foodItems,
        onToggleFavoriteById: _toggleFavoriteById,
        onAddToCart: _addToCart,
      ),
      SpinWheelWidget(
        items: _foodItems,
        onAddToCart: _addToCart,
      ),
      BuyWidget(
        cartItems: _cartItems,
        onRemoveItem: _removeFromCart,
        onUpdateQuantity: _updateCartQuantity,
        onCheckoutWithDetails: _checkoutWithDetails,
      ),
      OrderHistoryWidget(
        user: widget.user,
      ),
    ];

    int totalCartCount = 0;
    for (var item in _cartItems) {
      totalCartCount += item.quantity;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.casino_outlined),
            activeIcon: Icon(Icons.casino),
            label: 'Vòng quay',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: totalCartCount > 0,
              label: Text('$totalCartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: totalCartCount > 0,
              label: Text('$totalCartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Giỏ hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Đơn hàng',
          ),
        ],
      ),
    );
  }
}