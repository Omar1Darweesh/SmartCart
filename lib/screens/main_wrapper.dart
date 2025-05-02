import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'scan_screen.dart' as scan;
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _cart = [];

  void _updateCart(List<Map<String, dynamic>> updatedCart) {
    setState(() {
      _cart = updatedCart;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen(); // ✅ Welcome
      case 1:
        return CartScreen(cart: _cart, updateCart: _updateCart); // ✅ cart
      case 2:
        return scan.ScanScreen(
          cart: _cart,
          updateCart: _updateCart,
        ); // ✅ scan (imported with prefix)
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(child: _buildCurrentScreen()),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0 ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => _onTabTapped(0),
              ),
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: _currentIndex == 1 ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => _onTabTapped(1),
              ),
              const SizedBox(width: 40), // مساحة زر النص
              IconButton(
                icon: Icon(
                  Icons.camera_alt_outlined,
                  color: _currentIndex == 2 ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => _onTabTapped(2),
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _currentIndex == 3 ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => _onTabTapped(3),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onTabTapped(2),
        backgroundColor: Colors.black,
        elevation: 4,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
