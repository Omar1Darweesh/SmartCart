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
        return HomeScreen(cart: _cart);
      case 1:
        return CartScreen(cart: _cart, updateCart: _updateCart);
      case 2:
        return scan.ScanScreen(cart: _cart, updateCart: _updateCart);
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
                onPressed: () => _onTabTapped(1),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color:
                          _currentIndex == 1 ? Colors.blueAccent : Colors.grey,
                    ),
                    if (_cart.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${_cart.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
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
