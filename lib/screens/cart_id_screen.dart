import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_wrapper.dart';

class CartIdScreen extends StatefulWidget {
  final String userName;
  final List<Map<String, dynamic>> cart;

  const CartIdScreen({super.key, required this.userName, required this.cart});

  @override
  State<CartIdScreen> createState() => _CartIdScreenState();
}

class _CartIdScreenState extends State<CartIdScreen> {
  final TextEditingController _cartIdController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verifyCartAndProceed() async {
    final cartId = _cartIdController.text.trim();
    if (cartId.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('carts').doc(cartId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        if (!mounted) return;
        setState(() {
          _error = "❌ Cart ID not found.";
          _loading = false;
        });
        return;
      }

      final data = snapshot.data();
      final isAvailable = data?['isAvailable'] ?? false;

      if (!isAvailable) {
        if (!mounted) return;
        setState(() {
          _error = "🚫 This cart is already in use.";
          _loading = false;
        });
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();

      // ✅ تحديث cart بدون history
      await docRef.update({
        'userId': currentUser.uid,
        'userName': widget.userName,
        'assignedAt': now.toIso8601String(),
        'isAvailable': false,
      });

      // ✅ تخزين cartId مؤقتًا
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentCartId', cartId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "⚠️ Something went wrong. Please try again.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cart Verification")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "👋 Hello, ${widget.userName}!",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cartIdController,
              decoration: const InputDecoration(
                labelText: "Enter Cart ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _verifyCartAndProceed,
                  child: const Text("Continue"),
                ),
          ],
        ),
      ),
    );
  }
}
