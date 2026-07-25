// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:thesisapp/localization/app_localizations.dart';
// import 'package:thesisapp/theme_color.dart';

// class SuccessScreen extends StatefulWidget {
//   final int? orderId;
//   final int? paymentId;
//   final List<int> cartIds;
//   // final Address address;
//   final List<Map<String, dynamic>> items;
//   final double total;
//   final DateTime createdAt;

//   SuccessScreen({
//     super.key,
//     this.orderId,
//     this.paymentId,
//     this.cartIds = const [],
//     // required this.address,
//     required this.items,
//     required this.total,
//     DateTime? createdAt,
//   }) : createdAt = createdAt ?? DateTime.now();

//   @override
//   State<SuccessScreen> createState() => _SuccessScreenState();
// }

// class _SuccessScreenState extends State<SuccessScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final lang = AppLocalizations.of(context)!;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           const Spacer(),
//           // Animated success icon
//           Lottie.asset(
//             'assets/Done.json',
//             width: 200,
//             height: 200,
//             fit: BoxFit.cover,
//             repeat: true,
//             animate: true,
//           ),
//           // Container(
//           //   width: 120,
//           //   height: 120,
//           //   decoration: BoxDecoration(
//           //     color: GreenColor.withOpacity(0.12),
//           //     shape: BoxShape.circle,
//           //   ),
//           //   child: Container(
//           //     margin: const EdgeInsets.all(16),
//           //     decoration: const BoxDecoration(
//           //       color: GreenColor,
//           //       shape: BoxShape.circle,
//           //     ),
//           //     child: const Icon(
//           //       Icons.check_rounded,
//           //       color: Colors.white,
//           //       size: 52,
//           //     ),
//           //   ),
//           // ),
//           const SizedBox(height: 5),
//           Text(
//             lang.translate('payment Successful!'),
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontFamily: getFontFamilyMool1(context),
//               fontSize: 24,
//               fontWeight: FontWeight.w700,
//               color: TitleColor,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             lang.translate('thank you for your payment!'),
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontFamily: getFontFamily(context),
//               fontSize: 14,
//               color: TextColor,
//             ),
//           ),
//           const SizedBox(height: 32),
//           // Amount summary card
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       lang.translate('amount'),
//                       style: TextStyle(
//                         fontFamily: getFontFamilyMool1(context),
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: TextColor,
//                       ),
//                     ),
//                     Text(
//                       '\$${widget.total.toStringAsFixed(2)}',
//                       style: TextStyle(
//                         fontFamily: getFontFamily(context),
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: GreenColor,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 const Divider(color: StrokeSearchBar),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       lang.translate('status'),
//                       style: TextStyle(
//                         fontFamily: getFontFamilyMool1(context),
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: TextColor,
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
//                       decoration: BoxDecoration(
//                         color: GreenColor.withOpacity(0.12),
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       child: Text(
//                         lang.translate('paid'),
//                         style: TextStyle(
//                           fontFamily: getFontFamily(context),
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: GreenColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const Spacer(),
//           // Done button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _finish,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GreenColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(50),
//                 ),
//                 elevation: 0,
//               ),
//               child: const Text(
//                 'រួចរាល់',
//                 style: TextStyle(
//                   fontFamily: 'KhmerMool1',
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }
  
// }