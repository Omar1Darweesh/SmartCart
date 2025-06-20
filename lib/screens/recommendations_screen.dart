import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cart;

  const RecommendationsScreen({super.key, required this.cart});

  Future<Map<String, List<Map<String, dynamic>>>>
  _fetchGroupedRecommendations() async {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final product in cart) {
      final productName = product['name'] ?? 'Unknown Product';
      final recommendedIds =
          (product['recommendations'] as List<dynamic>?)?.cast<String>() ?? [];

      final recommendedDocs = await Future.wait(
        recommendedIds.map(
          (id) =>
              FirebaseFirestore.instance.collection('products').doc(id).get(),
        ),
      );

      final recommendedProducts =
          recommendedDocs.where((d) => d.exists).map((d) => d.data()!).toList();

      grouped[productName] = recommendedProducts;
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommended for You"),
        backgroundColor: theme.primaryColor,
        elevation: 6,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchGroupedRecommendations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text("⚠️ Error loading recommendations"),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No recommendations yet."));
          }

          final groupedRecommendations = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children:
                groupedRecommendations.entries.map((entry) {
                  final baseProduct = entry.key;
                  final recs = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Based on \"$baseProduct\", we recommend:",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColorDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...recs.map(
                        (product) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: theme.primaryColor.withOpacity(0.2),
                          child: ListTile(
                            leading:
                                product['image_url'] != null
                                    ? ClipRRect(
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
                                    )
                                    : const Icon(Icons.image, size: 40),
                            title: Text(
                              product['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Price: ${product['price']} EGP",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  "Section: ${product['location'] ?? 'Unknown'}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onTap: () {
                              // لو عايز تضيف فتح تفاصيل المنتج في صفحة جديدة
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
