import 'package:flutter/material.dart';
import 'package:thesisapp/theme_color.dart';

class CartSummaryCard extends StatelessWidget {
  final List<dynamic> cartItems;

  const CartSummaryCard({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    final colorText = Color(0xFFFFFFFF);
    // final bgBlue = AppColors.accentDeep;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ButtonColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          /// ===== DESCRIPTION HEADER =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
            ),
            alignment: Alignment.center,
            child: const Text(
              "Description",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// ===== TABLE HEADER =====
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text("Name", style: TextStyle(color: colorText)),
              ),
              Expanded(
                child: Text(
                  "Amount",
                  style: TextStyle(color: colorText),
                  textAlign: TextAlign.center,
                ),
              ),
              // Expanded(
              //   child: Text(
              //     "Currency",
              //     style: TextStyle(color: colorText),
              //     textAlign: TextAlign.center,
              //   ),
              // ),
              Expanded(
                child: Text(
                  "Price",
                  style: TextStyle(color: colorText),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ===== TABLE DATA =====
          Column(
            children: cartItems.map((item) {
              final double price =
                  double.tryParse(item['price'].toString()) ?? 0.0;
              // final int discount =
                  // int.tryParse(item['discount']?.toString() ?? '0') ?? 0;
              // final bool hasDiscount = discount > 0 && discount < 100;
              // final double displayPrice = hasDiscount
              //     ? price * (1 - discount / 100)
              //     : price;
              final int quantity = item['quantity'] ?? 1;
              final double totalPricePerItem = price * quantity;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['name'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    // const Expanded(
                    //   child: Text(
                    //     "\$",
                    //     textAlign: TextAlign.center,
                    //     style: TextStyle(color: Colors.white),
                    //   ),
                    // ),
                    Expanded(
                      child: Text(
                        totalPricePerItem.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
