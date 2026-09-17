import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/model/user.dart';
import 'package:thesisapp/provider/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CartProvider adds book, persists, and recovers items via fetchCart', () async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider();
    await authProvider.initialized;

    final user = User(
      name_kh: 'Test',
      name_en: 'Test',
      student_id: 'S001',
      pwd: '123',
    );
    await authProvider.login(user);

    final cartProvider = CartProvider(authProvider);
    const book = Book(
      id: 42,
      code: 'B-042',
      title: 'Flutter in Action',
      titleKh: 'សៀវភៅ Flutter',
      author: 'Author',
      publisher: 'Publisher',
      isbn: '1234567890',
      yearLevel: 'Year 1',
      unit: 'ក្បាល',
      price: 25.0,
      availableQty: 10,
      imageUrl: null,
    );

    final added = await cartProvider.addBook(book, quantity: 2);
    expect(added, isTrue);
    expect(cartProvider.cartItems.length, 1);
    expect(cartProvider.cartItems.first['cart_id'], 42);
    expect(cartProvider.selectedItemIds.contains(42), isTrue);

    // Now create a fresh CartProvider for the same user to simulate restarting or screen reload
    final freshCartProvider = CartProvider(authProvider);
    await freshCartProvider.fetchCart();

    expect(freshCartProvider.cartItems.length, 1);
    expect(freshCartProvider.cartItems.first['cart_id'], 42);
    expect(freshCartProvider.selectedItemIds.contains(42), isTrue);
    expect(freshCartProvider.total, 50.0);
  });

  test('Buy Now flow: unselects previous items, adds and selects target book, preserves on CartScreen load', () async {
    SharedPreferences.setMockInitialValues({});
    final authProvider = AuthProvider();
    await authProvider.initialized;

    final user = User(
      name_kh: 'Student',
      name_en: 'Student',
      student_id: 'S999',
      pwd: 'password',
    );
    await authProvider.login(user);

    final cart = CartProvider(authProvider);

    const oldBook = Book(
      id: 1,
      code: 'B-001',
      title: 'Old Book',
      titleKh: 'សៀវភៅចាស់',
      author: 'A',
      publisher: 'P',
      isbn: '111',
      yearLevel: 'Year 1',
      unit: 'ក្បាល',
      price: 10.0,
      availableQty: 5,
      imageUrl: null,
    );

    const newBook = Book(
      id: 2,
      code: 'B-002',
      title: 'New Book',
      titleKh: 'សៀវភៅថ្មី',
      author: 'B',
      publisher: 'P',
      isbn: '222',
      yearLevel: 'Year 2',
      unit: 'ក្បាល',
      price: 15.0,
      availableQty: 5,
      imageUrl: null,
    );

    // User already had oldBook in cart
    await cart.addBook(oldBook, quantity: 1);
    expect(cart.cartItems.length, 1);

    // User hits "Buy Now" on newBook
    cart.toggleSelectAll(false);
    final added = await cart.addBook(newBook, quantity: 2);
    expect(added, isTrue);

    // Only newBook should be selected
    expect(cart.cartItems.length, 2);
    expect(cart.selectedItemIds, {2});
    expect(cart.total, 30.0);
    expect(cart.selectedItems.length, 1);
    expect(cart.selectedItems.first['cart_id'], 2);

    // CartScreen loads and may call fetchCart
    await cart.fetchCart();
    expect(cart.cartItems.length, 2);
    expect(cart.selectedItemIds, {2});
    expect(cart.total, 30.0);
  });
}
