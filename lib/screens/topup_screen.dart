import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;

  Future<void> _addToWallet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _amountController.text.isEmpty) return;

    setState(() => _loading = true);
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnapshot = await userDoc.get();
      final currentWallet = userSnapshot.data()?['wallet'] ?? 0;

      final addedAmount = double.tryParse(_amountController.text) ?? 0;
      final newWallet = currentWallet + addedAmount;

      await userDoc.update({'wallet': newWallet});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Wallet updated successfully! New balance: $newWallet EGP",
          ),
        ),
      );
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Payment Method")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMethod(context, Icons.account_balance_wallet, "E-Wallet"),
          _buildMethod(context, Icons.credit_card, "Bank Card"),
          _buildMethod(context, Icons.account_balance, "Bank Transfer"),
          const SizedBox(height: 30),
          const Divider(thickness: 2),
          const SizedBox(height: 16),
          const Text(
            "💰 Trial: Add to Wallet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Enter amount",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _addToWallet,
            icon: const Icon(Icons.add),
            label:
                _loading
                    ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text("Add to Wallet"),
          ),
        ],
      ),
    );
  }

  Widget _buildMethod(BuildContext context, IconData icon, String label) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(label, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$label option is coming soon...")),
          );
        },
      ),
    );
  }
}
