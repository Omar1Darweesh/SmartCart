import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(List<Map<String, dynamic>>) updateCart;

  const ScanScreen({super.key, required this.cart, required this.updateCart});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _productDetails;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _productDetails = null;
      });

      final response = await ApiService.sendImageToServer(_selectedImage!);
      if (response != null && response['yolo_prediction'] != null) {
        final productName = response['yolo_prediction'];
        final doc =
            await FirebaseFirestore.instance
                .collection('products')
                .doc(productName.toLowerCase().replaceAll(' ', '_'))
                .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              _productDetails = data;
              widget.updateCart([...widget.cart, data]);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ ${data['name']} added to cart")),
            );
          }
        } else {
          setState(() {
            _productDetails = {'error': 'Product not found'};
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _selectedImage != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const Column(
                    children: [
                      Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "No image selected",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text("Select & Send Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_productDetails != null &&
                  _productDetails!['error'] == null) ...[
                Text(
                  "✅ Detected: ${_productDetails!['name']}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "💰 Price: ${_productDetails!['price']} EGP",
                  style: const TextStyle(fontSize: 16),
                ),
              ] else if (_productDetails?['error'] != null) ...[
                Text(
                  _productDetails!['error'],
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
