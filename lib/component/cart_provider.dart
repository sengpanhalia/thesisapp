import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/util/api_config.dart';

class CartProvider extends ChangeNotifier {
  AuthProvider _authProvider;

  CartProvider(this._authProvider);

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  Set<int> _selectedItemIds = {};
  int? _loadedUserId;
  bool _selectionInitialized = false;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  Set<int> get selectedItemIds => _selectedItemIds;
  int get cartBadgeCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + itemQuantity(item));

  CartProvider.initialize(this._authProvider) {
    fetchCart();
  }

  AuthProvider get authProvider => _authProvider;

  void bindAuth(AuthProvider authProvider) {
    final previousUserId = _loadedUserId;
    final nextUserId = authProvider.user?.student_id;
    _authProvider = authProvider;

    if (nextUserId == null) {
      if (_cartItems.isNotEmpty ||
          _selectedItemIds.isNotEmpty ||
          previousUserId != null) {
        _loadedUserId = null;
        _cartItems = [];
        _selectedItemIds = {};
        _selectionInitialized = false;
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (previousUserId != nextUserId) {
      _loadedUserId = nextUserId as int?;
      _selectionInitialized = false;
      fetchCart();
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int itemStockQuantity(Map<String, dynamic> item) {
    return _parseInt(item['stock_quantity']);
  }

  int itemQuantity(Map<String, dynamic> item) {
    return _parseInt(item['quantity']);
  }

  bool isItemPurchasable(Map<String, dynamic> item) {
    final stock = itemStockQuantity(item);
    final quantity = itemQuantity(item);
    return stock > 0 && quantity > 0 && quantity <= stock;
  }

  String? stockIssueForItem(Map<String, dynamic> item) {
    final stock = itemStockQuantity(item);
    final quantity = itemQuantity(item);
    if (stock <= 0) {
      return 'Out of stock';
    }
    if (quantity > stock) {
      return 'Only $stock left in stock';
    }
    return null;
  }

  Set<int> _selectableItemIds() {
    return _cartItems
        .where(isItemPurchasable)
        .map((e) => _parseInt(e['cart_id']))
        .where((id) => id > 0)
        .toSet();
  }

  Future<void> fetchCart() async {
    final user = authProvider.user;
    if (user == null) {
      if (_cartItems.isNotEmpty ||
          _selectedItemIds.isNotEmpty ||
          _loadedUserId != null) {
        _loadedUserId = null;
        _cartItems = [];
        _selectedItemIds = {};
        _selectionInitialized = false;
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    final previousSelectableIds = _selectableItemIds();
    final previousSelectedIds = Set<int>.from(_selectedItemIds);
    final hadSelectAll =
        _selectionInitialized &&
        previousSelectableIds.isNotEmpty &&
        previousSelectedIds.length == previousSelectableIds.length &&
        previousSelectedIds.containsAll(previousSelectableIds);

    _loadedUserId = int.tryParse(user.student_id) ?? null;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_cart.php?user_id=${user.student_id}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _cartItems = List<Map<String, dynamic>>.from(data['items']);
          final selectableIds = _selectableItemIds();
          if (!_selectionInitialized || hadSelectAll) {
            _selectedItemIds = selectableIds;
          } else {
            _selectedItemIds = previousSelectedIds.intersection(selectableIds);
          }
          _selectionInitialized = true;
        }
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get total {
    double t = 0.0;
    for (var item in _cartItems) {
      if (_selectedItemIds.contains(item['cart_id'])) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final discount = int.tryParse(item['discount']?.toString() ?? '0') ?? 0;
        final discountedPrice = discount > 0
            ? price * (1 - discount / 100)
            : price;
        t += discountedPrice * (item['quantity'] ?? 1);
      }
    }
    return t;
  }

  bool get allSelected {
    final selectable = _selectableItemIds();
    return selectable.isNotEmpty &&
        _selectedItemIds.length == selectable.length;
  }

  void toggleSelectAll(bool select) {
    if (select) {
      _selectedItemIds = _selectableItemIds();
    } else {
      _selectedItemIds.clear();
    }
    _selectionInitialized = true;
    notifyListeners();
  }

  void toggleItem(int cartId, bool selected) {
    Map<String, dynamic>? item;
    for (final entry in _cartItems) {
      if (entry['cart_id'] == cartId) {
        item = entry;
        break;
      }
    }
    if (item == null || !isItemPurchasable(item)) {
      return;
    }
    if (selected) {
      _selectedItemIds.add(cartId);
    } else {
      _selectedItemIds.remove(cartId);
    }
    _selectionInitialized = true;
    notifyListeners();
  }

  Future<void> updateQuantity(int cartId, int change) async {
    final user = authProvider.user;
    if (user == null) return;

    // Update locally first for better UX
    final itemIndex = _cartItems.indexWhere(
      (item) => item['cart_id'] == cartId,
    );
    if (itemIndex != -1) {
      final currentQuantity = itemQuantity(_cartItems[itemIndex]);
      final stockQuantity = itemStockQuantity(_cartItems[itemIndex]);
      final newQuantity = currentQuantity + change;
      if (change > 0 && stockQuantity <= 0) {
        Fluttertoast.showToast(msg: 'This product is out of stock');
        return;
      }
      if (change > 0 && stockQuantity > 0 && newQuantity > stockQuantity) {
        Fluttertoast.showToast(
          msg: 'Only $stockQuantity item(s) available in stock',
        );
        return;
      }
      if (newQuantity > 0) {
        _cartItems[itemIndex]['quantity'] = newQuantity;
        if (!isItemPurchasable(_cartItems[itemIndex])) {
          _selectedItemIds.remove(cartId);
        }
        _selectionInitialized = true;
        notifyListeners();
      }
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/update_cart_quantity.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.student_id,
          'cart_id': cartId,
          'change': change,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != 'success') {
          Fluttertoast.showToast(msg: data['message'] ?? 'Update failed');
          // Revert on error
          fetchCart();
        }
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      Fluttertoast.showToast(msg: 'Failed to update quantity');
      // Revert on error
      fetchCart();
    }
  }

  Future<void> removeItem(int cartId) async {
    final user = authProvider.user;
    if (user == null) return;

    // Remove locally first for better UX
    _cartItems.removeWhere((item) => item['cart_id'] == cartId);
    _selectedItemIds.remove(cartId);
    _selectionInitialized = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/remove_from_cart.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.student_id, 'cart_id': cartId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != 'success') {
          // Revert on error
          fetchCart();
        }
      }
    } catch (e) {
      debugPrint('Error removing item: $e');
      // Revert on error
      fetchCart();
    }
  }

  List<Map<String, dynamic>> get selectedItems {
    return _cartItems
        .where((item) => _selectedItemIds.contains(item['cart_id']))
        .toList();
  }

  void removeCheckedOutItems(Iterable<dynamic> cartIds) {
    final ids = cartIds.map(_parseInt).where((id) => id > 0).toSet();
    if (ids.isEmpty) return;

    _cartItems.removeWhere((item) => ids.contains(_parseInt(item['cart_id'])));
    _selectedItemIds.removeWhere((id) => ids.contains(id));
    _selectionInitialized = true;
    notifyListeners();
  }

  Future<void> clearCart() async {
    final user = authProvider.user;
    if (user == null) return;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clear_cart.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.student_id}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _cartItems = [];
          _selectedItemIds.clear();
          _selectionInitialized = false;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }
}
