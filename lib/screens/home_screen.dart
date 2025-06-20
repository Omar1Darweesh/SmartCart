import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cart;

  const HomeScreen({super.key, required this.cart});

  Future<List<Map<String, dynamic>>> _fetchAllProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('products').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              product['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product['image_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product['image_url'],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, _, __) =>
                                  const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      "💰 Price: ${product['price']} EGP",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "📝 Description: ${product['description'] ?? 'No description'}",
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "📍 Location: ${product['location'] ?? 'Unknown'}",
                      style: const TextStyle(fontSize: 15, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "🛒 Welcome to El-Market",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 6,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.iconTheme.color),
            tooltip: 'Sign Out',
            splashRadius: 24,
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                final prefs = await SharedPreferences.getInstance();
                final cartId = prefs.getString('currentCartId');

                if (cartId != null && cartId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('carts')
                      .doc(cartId)
                      .update({
                        'isAvailable': true,
                        'userId': null,
                        'userName': null,
                        'assignedAt': null,
                      });

                  await prefs.remove('currentCartId');
                }

                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "⚠️ Error loading products",
                style: TextStyle(fontSize: 16, color: theme.colorScheme.error),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No products available",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showProductDetails(context, product),
                splashColor: theme.primaryColor.withOpacity(0.25),
                highlightColor: theme.primaryColor.withOpacity(0.1),
                child: Card(
                  elevation: 7,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  shadowColor: theme.primaryColor.withOpacity(0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: Image.network(
                            product['image_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder:
                                (context, _, __) => const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                        child: Text(
                          product['name'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Text(
                          "${product['price']} EGP",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
