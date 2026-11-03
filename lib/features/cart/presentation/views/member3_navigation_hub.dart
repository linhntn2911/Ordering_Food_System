import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../address/presentation/views/address_list_screen.dart';
import '../../../checkout/presentation/views/checkout_screen.dart';
import '../../../order_history/presentation/views/order_history_view.dart';
import 'cart_screen.dart';

/// Navigation Hub for Member 3 independent testing (Cart -> Checkout -> Address)
class Member3NavigationHub extends StatefulWidget {
  const Member3NavigationHub({super.key});

  @override
  State<Member3NavigationHub> createState() => _Member3NavigationHubState();
}

class _Member3NavigationHubState extends State<Member3NavigationHub> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CartScreen(onNavigateToCheckout: () => setState(() => _currentIndex = 1)),
      CheckoutScreen(
        onBackPressed: () => setState(() => _currentIndex = 0),
        onOrderSuccess: () => setState(() => _currentIndex = 3),
      ),
      const AddressListScreen(),
      const OrderHistoryView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primaryEnd,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surface,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment_rounded),
            label: 'Thanh toán',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on_rounded),
            label: 'Sổ địa chỉ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Đơn hàng',
          ),
        ],
      ),
    );
  }
}
