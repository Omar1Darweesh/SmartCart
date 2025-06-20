// CartScreen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recommendations_screen.dart';
import 'PaymentMethodScreen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(List<Map<String, dynamic>>) updateCart;

  const CartScreen({super.key, required this.cart, required this.updateCart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, Map<String, dynamic>> groupedCart;
  bool _hasLastOrder = false;

  @override
  void initState() {
    super.initState();
    _groupCartItems();
    _checkLastOrderStatus();
  }

  void _groupCartItems() {
    groupedCart = {};
    for (var item in widget.cart) {
      final name = item['name'];
      if (groupedCart.containsKey(name)) {
        groupedCart[name]!['quantity'] += 1;
      } else {
        groupedCart[name] = Map<String, dynamic>.from(item);
        groupedCart[name]!['quantity'] = 1;
      }
    }
  }

  void _removeItem(String name) {
    setState(() {
      widget.cart.removeWhere((item) => item['name'] == name);
      _groupCartItems();
      widget.updateCart(widget.cart);
    });
  }

  void _updateCart(List<Map<String, dynamic>> updatedCart) {
    setState(() {
      widget.cart
        ..clear()
        ..addAll(updatedCart);
      _groupCartItems();
    });
  }

  double _calculateTotal() {
    double total = 0.0;
    groupedCart.forEach((_, item) {
      double price = double.tryParse(item['price'].toString()) ?? 0.0;
      int quantity = item['quantity'] ?? 1;
      total += price * quantity;
    });
    return total;
  }

  Future<void> _checkLastOrderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('currentCartId');
    if (cartId == null) return;

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);
    final snapshot = await cartRef.get();

    setState(() {
      _hasLastOrder = snapshot.exists && snapshot.data()?['lastOrder'] != null;
    });
  }

  Future<void> confirmCashPaymentTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('currentCartId');

    if (cartId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ No cart ID found.")));
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);
    final cartSnapshot = await cartRef.get();

    if (!cartSnapshot.exists || cartSnapshot.data()?['lastOrder'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No pending cash order found.")),
      );
      return;
    }

    await cartRef.update({'lastOrder': FieldValue.delete()});

    setState(() {
      _hasLastOrder = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Payment confirmed (Trial). You may scan again."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 6,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (groupedCart.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Your cart is empty!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_hasLastOrder)
                        ElevatedButton.icon(
                          onPressed: confirmCashPaymentTrial,
                          icon: const Icon(Icons.attach_money),
                          label: const Text("Confirm Cash Payment (Trial)"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children:
                      groupedCart.entries.map((entry) {
                        final product = entry.value;
                        final quantity = product['quantity'];
                        final price =
                            double.tryParse(product['price'].toString()) ?? 0.0;
                        final total = price * quantity;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product['image_url'],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, _, __) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                    ),
                              ),
                            ),
                            title: Text(
                              "${product['name']} (x$quantity)",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Total: ${total.toStringAsFixed(2)} EGP",
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _removeItem(product['name']),
                              tooltip: 'Remove Item',
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

            // Total + Checkout
            if (groupedCart.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${_calculateTotal().toStringAsFixed(2)} EGP",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PaymentMethodScreen(
                                totalAmount: _calculateTotal(),
                                cartItems: groupedCart.values.toList(),
                                updateCart: _updateCart,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      "Checkout",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ),
            ],

            // Confirm Payment Trial button (always shows if lastOrder exists)
            if (_hasLastOrder)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: confirmCashPaymentTrial,
                    icon: const Icon(Icons.attach_money),
                    label: const Text(
                      "Confirm Cash Payment (Trial)",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ),

            // Recommendations button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RecommendationsScreen(cart: widget.cart),
                      ),
                    );
                  },
                  icon: const Icon(Icons.recommend),
                  label: const Text(
                    "Get Recommendations",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
