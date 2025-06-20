import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodScreen extends StatelessWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) updateCart;

  const PaymentMethodScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
    required this.updateCart,
  });

  Future<void> _handleCashPayment(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('currentCartId');
    if (cartId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnapshot = await userRef.get();
    final userName = userSnapshot.data()?['firstName'] ?? 'Unknown';

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final cartSnap = await transaction.get(cartRef);
      final currentHistory =
          cartSnap.data()?['history'] as List<dynamic>? ?? [];

      final newEntry = {
        'orderId': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': uid,
        'userName': userName,
        'cartId': cartId, // ✅ ربط الطلب بالكارت
        'timestamp': Timestamp.now(),
        'items': cartItems.map((e) => Map<String, dynamic>.from(e)).toList(),
        'total': totalAmount,
        'paymentMethod': 'Cash',
        'type': 'cash',
        'isPaid': false,
      };

      // ⬅️ أضف للتاريخ بتاع الكارت
      currentHistory.add(newEntry);
      transaction.update(cartRef, {'history': currentHistory});

      // ⬅️ أضف للتاريخ بتاع المستخدم
      final userOrderRef = userRef
          .collection('history')
          .doc(newEntry['orderId']);
      transaction.set(userOrderRef, newEntry);
    });

    updateCart([]);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Cash payment recorded. Please confirm at cashier."),
      ),
    );
  }

  Future<void> _handleWalletPayment(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('currentCartId');
    if (cartId == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final userName = userSnap.data()?['firstName'] ?? 'Unknown';
    final currentBalance = userSnap.data()?['wallet'] ?? 0.0;

    if (currentBalance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Insufficient wallet balance."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final cartSnap = await transaction.get(cartRef);
      final currentHistory =
          cartSnap.data()?['history'] as List<dynamic>? ?? [];

      final newEntry = {
        'orderId': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': uid,
        'userName': userName,
        'cartId': cartId, // ✅ ربط الطلب بالكارت
        'timestamp': Timestamp.now(),
        'items': cartItems.map((e) => Map<String, dynamic>.from(e)).toList(),
        'total': totalAmount,
        'paymentMethod': 'Wallet',
        'type': 'wallet',
        'isPaid': true,
      };

      // ⬅️ أضف للتاريخ بتاع الكارت
      currentHistory.add(newEntry);
      transaction.update(cartRef, {'history': currentHistory});

      // ⬅️ خصم من المحفظة
      transaction.update(userRef, {'wallet': currentBalance - totalAmount});

      // ⬅️ أضف للتاريخ بتاع المستخدم
      final userOrderRef = userRef
          .collection('history')
          .doc(newEntry['orderId']);
      transaction.set(userOrderRef, newEntry);
    });

    updateCart([]);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Payment successful using wallet."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => _handleCashPayment(context),
              icon: const Icon(Icons.money),
              label: const Text("Pay with Cash"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _handleWalletPayment(context),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text("Pay with Wallet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🚧 Other payment methods coming soon."),
                  ),
                );
              },
              icon: const Icon(Icons.credit_card),
              label: const Text("Pay with Card"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
