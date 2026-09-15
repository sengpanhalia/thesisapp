import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/provider/auth_provider.dart';

/// The basket, kept on the phone.
///
/// The inventory API has no cart: `/api/v1` reserves one title at a time and
/// holds nothing between requests. So the basket is the student's own scratch
/// list, saved on the device under their student number, and checkout turns it
/// into one reservation per line. Nothing here claims stock — a book is only
/// held once `POST /orders.php` has said so.
///
/// Lines keep the shape the cart screens already read: `cart_id`, `name`,
/// `price`, `quantity`, `image`. `cart_id` is the book's own id, which is
/// unique within a basket and stable across restarts.
class CartProvider extends ChangeNotifier {
  CartProvider(this._authProvider) {
    _loadedUserId = _authProvider.user?.student_id;
    fetchCart();
  }

  CartProvider.initialize(this._authProvider) {
    fetchCart();
  }

  AuthProvider _authProvider;

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  Set<int> _selectedItemIds = {};
  String? _loadedUserId;
  bool _selectionInitialized = false;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  Set<int> get selectedItemIds => _selectedItemIds;
  int get cartBadgeCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + itemQuantity(item));

  AuthProvider get authProvider => _authProvider;

  static String _storageKey(String studentId) => 'cart_$studentId';

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
      _loadedUserId = nextUserId;
      _selectionInitialized = false;
      fetchCart();
    }
  }

  // ------------------------------------------------------------- reading --

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// How many copies the catalogue said were free when this line was added.
  /// Null means the catalogue did not say — which is not the same as none.
  int? availableQuantity(Map<String, dynamic> item) {
    final raw = item['available_qty'];
    if (raw == null) return null;
    if (raw is int) return raw;

    return int.tryParse(raw.toString());
  }

  /// Kept for the cart screen, which shows a line as unavailable when this
  /// reaches zero. A line whose availability is unknown is not treated as sold
  /// out; the server decides that when the reservation is sent.
  int itemStockQuantity(Map<String, dynamic> item) =>
      availableQuantity(item) ?? itemQuantity(item);

  int itemQuantity(Map<String, dynamic> item) => _parseInt(item['quantity']);

  double? itemPrice(Map<String, dynamic> item) {
    final raw = item['price'];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();

    return double.tryParse(raw.toString());
  }

  bool isItemPurchasable(Map<String, dynamic> item) {
    final quantity = itemQuantity(item);
    return quantity > 0;
  }

  /// A translation key naming what is wrong with the line, or null when it is
  /// fine. The final word is the server's: this only catches what the app
  /// already knows from the last catalogue read.
  String? stockIssueForItem(Map<String, dynamic> item) {
    final available = availableQuantity(item);
    if (available == null) return null;
    if (available <= 0) return 'out_of_stock';

    return available < itemQuantity(item) ? 'not_enough_stock' : null;
  }

  Set<int> _selectableItemIds() {
    return _cartItems
        .where(isItemPurchasable)
        .map((e) => _parseInt(e['cart_id']))
        .where((id) => id > 0)
        .toSet();
  }

  /// Reloads the basket from the device. Named for the screens that call it
  /// on pull-to-refresh; there is no server round trip behind it.
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

    _loadedUserId = user.student_id;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(user.student_id));

      _cartItems = _decode(raw);

      final selectableIds = _selectableItemIds();
      if (!_selectionInitialized || hadSelectAll) {
        _selectedItemIds = selectableIds;
      } else {
        _selectedItemIds = previousSelectedIds.intersection(selectableIds);
      }
      _selectionInitialized = true;
    } catch (e) {
      debugPrint('Error reading the saved cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    final user = authProvider.user;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(user.student_id),
      jsonEncode(_cartItems),
    );
  }

  // ------------------------------------------------------------- writing --

  /// Adds copies of a book, or raises the count if it is already in the
  /// basket. Never puts in more than the catalogue says are free.
  Future<bool> addBook(Book book, {int quantity = 1}) async {
    if (quantity <= 0) return false;

    final user = authProvider.user;
    if (user == null) return false;

    final index = _cartItems.indexWhere(
      (item) => _parseInt(item['cart_id']) == book.id,
    );

    if (index == -1) {
      _cartItems.add({
        'cart_id': book.id,
        'item_id': book.id,
        'code': book.code,
        'name': book.title,
        'name_kh': book.titleKh,
        'author': book.author,
        'unit': book.unit,
        'image': book.imageUrl,
        'price': book.price,
        'available_qty': book.availableQty,
        'quantity': quantity,
      });
    } else {
      final current = itemQuantity(_cartItems[index]);
      _cartItems[index]['quantity'] = current + quantity;
      // The catalogue may have moved since the line was added.
      _cartItems[index]['price'] = book.price;
      _cartItems[index]['available_qty'] = book.availableQty;
    }

    _selectedItemIds.add(book.id);
    _selectionInitialized = true;
    notifyListeners();
    await _persist();

    return true;
  }

  double get total {
    double sum = 0.0;

    for (final item in _cartItems) {
      if (!_selectedItemIds.contains(_parseInt(item['cart_id']))) continue;

      final price = itemPrice(item);
      // A line the catalogue holds no price for is left out of the sum rather
      // than counted as free; [selectionHasUnknownPrice] tells the screen so.
      if (price == null) continue;

      sum += price * itemQuantity(item);
    }

    return sum;
  }

  /// True when something in the selection has no price, so the total on screen
  /// is less than the whole basket.
  bool get selectionHasUnknownPrice {
    return _cartItems.any(
      (item) =>
          _selectedItemIds.contains(_parseInt(item['cart_id'])) &&
          itemPrice(item) == null,
    );
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
      if (_parseInt(entry['cart_id']) == cartId) {
        item = entry;
        break;
      }
    }

    if (item == null || !isItemPurchasable(item)) return;

    if (selected) {
      _selectedItemIds.add(cartId);
    } else {
      _selectedItemIds.remove(cartId);
    }

    _selectionInitialized = true;
    notifyListeners();
  }

  Future<void> updateQuantity(int cartId, int change) async {
    final index = _cartItems.indexWhere(
      (item) => _parseInt(item['cart_id']) == cartId,
    );

    if (index == -1) return;

    final current = itemQuantity(_cartItems[index]);
    var next = current + change;

    if (next <= 0) return;
    if (next == current) return;

    _cartItems[index]['quantity'] = next;

    _selectionInitialized = true;
    notifyListeners();
    await _persist();
  }

  /// Brings the basket in line with what the app is offering right now.
  /// Updates prices and stock indicators without deleting out-of-stock items.
  Future<void> syncWithCatalogue(List<Book> offered) async {
    if (_cartItems.isEmpty) return;

    final byId = {for (final book in offered) book.id: book};
    var changed = false;

    for (final item in _cartItems) {
      final id = _parseInt(item['cart_id']);
      final book = byId[id];

      if (book != null) {
        final available = book.availableQty;
        if (item['price'] != book.price || item['available_qty'] != available) {
          item['price'] = book.price;
          item['available_qty'] = available;
          changed = true;
        }
      }
    }

    if (!changed) return;

    notifyListeners();
    await _persist();
  }

  Future<void> removeItem(int cartId) async {
    _cartItems.removeWhere((item) => _parseInt(item['cart_id']) == cartId);
    _selectedItemIds.remove(cartId);
    _selectionInitialized = true;
    notifyListeners();
    await _persist();
  }

  List<Map<String, dynamic>> get selectedItems {
    return _cartItems
        .where((item) => _selectedItemIds.contains(_parseInt(item['cart_id'])))
        .toList();
  }

  void removeCheckedOutItems(Iterable<dynamic> cartIds) {
    final ids = cartIds.map(_parseInt).where((id) => id > 0).toSet();
    if (ids.isEmpty) return;

    _cartItems.removeWhere((item) => ids.contains(_parseInt(item['cart_id'])));
    _selectedItemIds.removeWhere((id) => ids.contains(id));
    _selectionInitialized = true;
    notifyListeners();
    _persist();
  }

  Future<void> clearCart() async {
    _cartItems = [];
    _selectedItemIds.clear();
    _selectionInitialized = false;
    notifyListeners();
    await _persist();
  }
}
