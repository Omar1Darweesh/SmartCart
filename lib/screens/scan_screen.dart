// ✅ الكود المعدل: لا يتم مسح الليست إلا بعد تحليل الاتجاه (up/down)

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // Added for MediaType

class ScanScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(List<Map<String, dynamic>>) updateCart;

  const ScanScreen({super.key, required this.cart, required this.updateCart});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  Map<String, dynamic>? _productDetails;
  bool _hasUnpaidCash = false;
  String? _movementDirection;
  double? _detectionConfidence;
  int _appearances = 0;
  int _frameCount = 0; // ✅ عداد الفريمات
  final int _skipEveryNFrames = 2; // ✅ نعد كل فريمين
  DateTime? _lastProductActionTime; // ✅ وقت آخر إضافة/حذف
  final Duration _actionCooldown = Duration(
    seconds: 3,
  ); // ✅ وقت الانتظار بعد الإضافة/الحذف

  final List<Map<String, dynamic>> _detectionHistory = [];
  final List<Map<String, dynamic>> _removedEntries = [];

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(backCamera, ResolutionPreset.medium);
      await _controller!.initialize();

      if (mounted) {
        setState(() {});
        _startLiveScan();
      }
    } catch (e) {
      debugPrint('❌ Camera setup error: $e');
    }
  }

  Future<bool> _canScanProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('currentCartId');
    if (cartId == null) return false;

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);
    final snapshot = await cartRef.get();
    final data = snapshot.data();
    if (data == null) return false;

    final List<dynamic>? history = data['history'];
    if (history != null && history.isNotEmpty) {
      final last = history.last;
      if (last['type'] == 'cash' && last['isPaid'] == false) {
        setState(() {
          _hasUnpaidCash = true;
        });
        return false;
      }
    }

    setState(() {
      _hasUnpaidCash = false;
    });
    return true;
  }

  String _analyzeMovement(String product) {
    final matches =
        _detectionHistory
            .where((entry) => entry['product'] == product)
            .toList();

    if (matches.length < 4) return 'unknown';

    final lastFive = matches.sublist(matches.length - 5);
    final yValues = lastFive.map((e) => e['y'] as double).toList();

    final isDescending = List.generate(
      4,
      (i) => yValues[i] > yValues[i + 1],
    ).every((e) => e);
    final isAscending = List.generate(
      4,
      (i) => yValues[i] < yValues[i + 1],
    ).every((e) => e);

    if (isAscending) return 'down';
    if (isDescending) return 'up';

    return 'unknown';
  }

  Uint8List convertYUV420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final Uint8List yuvBytes = Uint8List(width * height * 3 ~/ 2);

    int index = 0;

    // Copy Y plane
    for (int y = 0; y < height; y++) {
      yuvBytes.setRange(
        index,
        index + width,
        image.planes[0].bytes,
        y * image.planes[0].bytesPerRow,
      );
      index += width;
    }

    // Copy interleaved VU plane (NV21 format: V then U)
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final int uIndex = y * uvRowStride + x * uvPixelStride;
        final int vIndex = y * uvRowStride + x * uvPixelStride;
        yuvBytes[index++] = image.planes[2].bytes[vIndex]; // V
        yuvBytes[index++] = image.planes[1].bytes[uIndex]; // U
      }
    }

    return yuvBytes;
  }

  void _startLiveScan() {
    if (!(_controller?.value.isInitialized ?? false)) return;

    _controller!.startImageStream((CameraImage image) async {
      print("📷 FORMAT RECEIVED: ${image.format.raw}");

      _frameCount++;

      if (_frameCount % _skipEveryNFrames != 0) return;

      if (_lastProductActionTime != null &&
          DateTime.now().difference(_lastProductActionTime!) <
              _actionCooldown) {
        debugPrint("⏸️ Waiting 3s cooldown after last action...");
        return;
      }

      if (_isDetecting) return;
      _isDetecting = true;
      debugPrint("📸 Flutter: Image frame captured. Sending to server...");

      try {
        print("🔍 Checking if allowed to scan...");
        final canScan = await _canScanProduct();
        print("✅ Can scan? $canScan");

        if (!canScan) {
          _isDetecting = false;
          return;
        }

        if (image.format.group == ImageFormatGroup.yuv420) {
          final Uint8List yuvBytes = convertYUV420toNV21(image);
          final response = await _sendImageToServer(
            yuvBytes,
            image.width,
            image.height,
          );

          print("📥 Response from server: $response");

          if (response != null &&
              response['final_decision'] != null &&
              response['bbox_y'] != null) {
            final productName = response['final_decision'];
            final double bboxY = response['bbox_y'].toDouble();
            final double confidence =
                response['yolo_accuracy']?.toDouble() ?? 0.0;

            setState(() {
              _detectionHistory.add({
                'product': productName,
                'y': bboxY,
                'time': DateTime.now(),
              });
            });

            if (_detectionHistory.length > 20) {
              _detectionHistory.removeAt(0);
            }

            final direction = _analyzeMovement(productName);
            print("📈 Movement direction: $direction");

            if (direction != 'unknown') {
              final doc =
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(productName.toLowerCase().replaceAll(' ', '_'))
                      .get();

              if (doc.exists) {
                final data = doc.data();
                if (data != null && mounted) {
                  setState(() {
                    _productDetails = data;
                    _movementDirection = direction;
                    _detectionConfidence = confidence;
                    _appearances =
                        _detectionHistory
                            .where((e) => e['product'] == productName)
                            .length;
                  });

                  if (direction == 'down') {
                    widget.updateCart([...widget.cart, data]);
                  } else if (direction == 'up') {
                    final updatedCart = [...widget.cart];
                    final index = updatedCart.lastIndexWhere(
                      (item) => item['name'] == productName,
                    );
                    if (index != -1) {
                      updatedCart.removeAt(index);
                      widget.updateCart(updatedCart);
                    }
                  }

                  _lastProductActionTime = DateTime.now();

                  _removedEntries.clear();
                  _removedEntries.addAll(_detectionHistory);
                  _detectionHistory.clear();

                  Future.delayed(const Duration(seconds: 4), () {
                    if (mounted) {
                      setState(() => _productDetails = null);
                    }
                  });
                }
              }
            }
          } else {
            debugPrint(
              "⚠️ Flutter: Server response missing final_decision or bbox_y.",
            );
          }
        } else {
          debugPrint('❌ Unsupported CameraImage format: ${image.format.raw}');
        }
      } catch (e) {
        debugPrint('❌ Flutter: Scan error: $e');
      }

      _isDetecting = false;
      debugPrint("🔄 Flutter: Detection cycle complete.");
    });
  }

  Future<Map<String, dynamic>?> _sendImageToServer(
    Uint8List imageBytes,
    int width,
    int height,
  ) async {
    try {
      final uri = Uri.parse('http://10.0.2.2:5000/detect');
      print("🌐 START REQUEST");

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'frame.yuv',
          contentType: MediaType('application', 'octet-stream'),
        ),
      );
      request.fields['width'] = width.toString();
      request.fields['height'] = height.toString();

      print("📦 Sending request...");
      final response = await request.send();

      print("📬 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        print("✅ BODY: $body");
        return jsonDecode(body);
      } else {
        print(
          "❌ ERROR: ${response.statusCode} → ${await response.stream.bytesToString()}",
        );
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
    }
    return null;
  }

  Future<void> _confirmCashPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final cartId = prefs.getString('currentCartId');
    if (cartId == null) return;

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(cartId);
    final snapshot = await cartRef.get();
    final data = snapshot.data();
    if (data == null) return;

    final List<dynamic>? history = data['history'];
    if (history != null && history.isNotEmpty) {
      final last = history.last;
      if (last['type'] == 'cash' && last['isPaid'] == false) {
        history.removeLast();
        history.add({...last, 'isPaid': true});
        await cartRef.update({'history': history});
        if (mounted) {
          setState(() => _hasUnpaidCash = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Cash payment confirmed"),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream(); // Stop the stream
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Product"),
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: "Clear Product Info",
            onPressed: () => setState(() => _productDetails = null),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_controller == null || !_controller!.value.isInitialized)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            if (_hasUnpaidCash)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: _confirmCashPayment,
                  icon: const Icon(Icons.payment),
                  label: const Text("Confirm Cash Payment (Trial)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  if (_productDetails == null)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "No product detected yet.\nPoint the camera to a product.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🛒 ${_productDetails!['name']}"),
                            const SizedBox(height: 8),
                            Text("📈 Direction: $_movementDirection"),
                            Text(
                              "🎯 Confidence: ${((_detectionConfidence ?? 0.0) * 100).toStringAsFixed(1)}%",
                            ),
                            Text("📸 Seen in $_appearances recent frames"),
                          ],
                        ),
                      ),
                    ),
                  const Divider(),
                  const Text(
                    "📋 Detection History:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _detectionHistory.length,
                      itemBuilder: (context, index) {
                        final entry = _detectionHistory[index];
                        return ListTile(
                          title: Text(
                            "${entry['product']} - Y=${entry['y'].toStringAsFixed(2)}",
                          ),
                          subtitle: Text(entry['time'].toString()),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  const Text(
                    "🧹 Recently Removed Entries:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _removedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _removedEntries[index];
                        return ListTile(
                          title: Text(
                            "${entry['product']} - Y=${entry['y'].toStringAsFixed(2)}",
                          ),
                          subtitle: Text(entry['time'].toString()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
