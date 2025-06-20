import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'topup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dobController;
  bool _editingFirst = false;
  bool _editingLast = false;
  bool _editingDob = false;

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _updateField(String field, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      field: value,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile Page"),
        backgroundColor: primaryColor,
        elevation: 5,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "❌ Failed to load user data",
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontSize: 16,
                ),
              ),
            );
          }

          final user = snapshot.data!;
          final dob = DateTime.tryParse(user['dob'] ?? '') ?? DateTime(2000);
          final age = _calculateAge(dob);

          _firstNameController = TextEditingController(
            text: user['firstName'] ?? '',
          );
          _lastNameController = TextEditingController(
            text: user['lastName'] ?? '',
          );
          _dobController = TextEditingController(
            text: DateFormat('yyyy-MM-dd').format(dob),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: primaryColor.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        "User Info",
                        style: textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 40, thickness: 2),
                    _buildEditableField(
                      context,
                      "👤 First Name",
                      _firstNameController,
                      _editingFirst,
                      () {
                        setState(() => _editingFirst = !_editingFirst);
                        if (!_editingFirst) {
                          _updateField('firstName', _firstNameController.text);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildEditableField(
                      context,
                      "👤 Last Name",
                      _lastNameController,
                      _editingLast,
                      () {
                        setState(() => _editingLast = !_editingLast);
                        if (!_editingLast) {
                          _updateField('lastName', _lastNameController.text);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(context, "📧 Email", user['email']),
                    const SizedBox(height: 24),
                    _buildEditableField(
                      context,
                      "🎂 Date of Birth",
                      _dobController,
                      _editingDob,
                      () async {
                        if (!_editingDob) {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dob,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            _dobController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked);
                            await _updateField('dob', _dobController.text);
                          }
                        }
                        setState(() => _editingDob = !_editingDob);
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(context, "🔢 Age", "$age years"),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      context,
                      "💰 Wallet",
                      "${user['wallet'] ?? 0} EGP",
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TopUpScreen(),
                            ),
                          );
                          setState(() {}); // ⬅️ عشان يحصل reload بعد الشحن
                        },
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        label: const Text("Top Up Wallet"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryColor,
            fontSize: 18,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(
    BuildContext context,
    String label,
    TextEditingController controller,
    bool isEditing,
    VoidCallback onIconPressed,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child:
              isEditing
                  ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(color: theme.primaryColor),
                      border: const OutlineInputBorder(),
                    ),
                  )
                  : _buildInfoRow(context, label, controller.text),
        ),
        IconButton(
          icon: Icon(
            isEditing ? Icons.check : Icons.edit,
            color: theme.primaryColor,
          ),
          onPressed: onIconPressed,
        ),
      ],
    );
  }
}
