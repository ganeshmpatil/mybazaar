import 'package:flutter/material.dart';

enum AppLanguage { en, mr }

class AppStrings {
  static final AppStrings _instance = AppStrings._();
  factory AppStrings() => _instance;
  AppStrings._();

  AppLanguage _language = AppLanguage.mr;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    _language = lang;
  }

  String get(String key) {
    final map = _language == AppLanguage.mr ? _mr : _en;
    return map[key] ?? _en[key] ?? key;
  }

  static const _en = {
    // App
    'app_name': 'Gharpoch Kirana',
    'delivering_near': 'Delivering near you',

    // Auth
    'welcome_to': 'Welcome to',
    'enter_mobile': 'Enter your mobile number to get started',
    'mobile_number': 'Mobile Number',
    'continue_btn': 'Continue',
    'otp_verify_hint': "We'll send a 4-digit OTP to verify",
    'enter_valid_mobile': 'Enter a valid 10-digit mobile number',
    'otp_send_failed': 'Failed to send OTP. Please try again.',
    'enter_otp': 'Enter OTP',
    'otp_sent_to': 'OTP sent to',
    'verify': 'Verify',
    'resend_otp': 'Resend OTP',
    'didnt_receive': "Didn't receive OTP?",

    // Home
    'search_hint': 'Search groceries, fruits, oil...',
    'no_products': 'No products found',
    'clear_all': 'Clear all',
    'all': 'All',

    // Product
    'in_stock': 'In Stock',
    'out_of_stock': 'Out of Stock',
    'add': 'Add',
    'add_to_cart': 'Add to Cart',
    'added_to_cart': 'Added to Cart!',
    'product_details': 'Product Details',
    'select_quantity': 'Select Quantity',
    'quantity': 'Quantity',
    'description': 'Description',
    'cash_on_delivery': 'Cash on Delivery',
    'same_day_delivery': 'Same Day Delivery',

    // Cart
    'cart': 'Cart',
    'cart_empty': 'Your cart is empty',
    'cart_empty_sub': 'Add items to get started',
    'start_shopping': 'Start Shopping',
    'checkout': 'Checkout',
    'remove': 'Remove',

    // Checkout
    'delivery_address': 'Delivery Address',
    'no_address': 'No address added',
    'add_address_hint': 'Add your delivery address',
    'add_new_address': 'Add New Address',
    'full_address': 'Full address',
    'city': 'City',
    'pincode': 'Pincode',
    'cancel': 'Cancel',
    'save': 'Save',
    'delivery_slot': 'Delivery Slot',
    'morning': 'Morning',
    'afternoon': 'Afternoon',
    'evening': 'Evening',
    'night': 'Night',
    'delivery_notes': 'Delivery Notes (Optional)',
    'delivery_notes_hint': 'E.g. Ring the bell twice',
    'payment': 'Payment',
    'pay_when_receive': 'Pay when you receive',
    'order_summary': 'Order Summary',
    'subtotal': 'Subtotal',
    'delivery': 'Delivery',
    'free': 'FREE',
    'gst': 'GST',
    'included': 'Included',
    'total': 'Total',
    'place_order': 'Place Order',

    // Orders
    'my_orders': 'My Orders',
    'no_orders': 'No orders yet',
    'no_orders_sub': 'Your orders will appear here',
    'order_placed': 'Order Placed',
    'confirmed': 'Confirmed',
    'packed': 'Packed',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
    'cancel_order': 'Cancel Order',

    // Order Success
    'order_success': 'Order Placed!',
    'order_success_sub': 'Your order has been placed successfully',
    'order_number': 'Order Number',
    'view_orders': 'View My Orders',
    'continue_shopping': 'Continue Shopping',

    // Profile
    'profile': 'Profile',
    'edit_profile': 'Edit Profile',
    'name': 'Name',
    'email': 'Email',
    'logout': 'Logout',
    'update': 'Update',
    'language': 'Language',

    // Bottom nav
    'nav_home': 'Home',
    'nav_orders': 'Orders',
    'nav_cart': 'Cart',
    'nav_profile': 'Profile',
  };

  static const _mr = {
    // App
    'app_name': 'घरपोच किराणा',
    'delivering_near': 'तुमच्या जवळ डिलिव्हरी',

    // Auth
    'welcome_to': 'स्वागत आहे',
    'enter_mobile': 'सुरू करण्यासाठी मोबाइल नंबर टाका',
    'mobile_number': 'मोबाइल नंबर',
    'continue_btn': 'पुढे चला',
    'otp_verify_hint': 'आम्ही 4 अंकी OTP पाठवू',
    'enter_valid_mobile': 'वैध 10 अंकी मोबाइल नंबर टाका',
    'otp_send_failed': 'OTP पाठवता आला नाही. पुन्हा प्रयत्न करा.',
    'enter_otp': 'OTP टाका',
    'otp_sent_to': 'OTP पाठवला',
    'verify': 'पडताळणी करा',
    'resend_otp': 'OTP पुन्हा पाठवा',
    'didnt_receive': 'OTP आला नाही?',

    // Home
    'search_hint': 'किराणा, फळे, तेल शोधा...',
    'no_products': 'कोणतेही उत्पादन सापडले नाही',
    'clear_all': 'सर्व साफ करा',
    'all': 'सर्व',

    // Product
    'in_stock': 'उपलब्ध',
    'out_of_stock': 'उपलब्ध नाही',
    'add': 'खरेदी करा',
    'add_to_cart': 'कार्टमध्ये खरेदी करा',
    'added_to_cart': 'कार्टमध्ये जोडले!',
    'product_details': 'उत्पादन तपशील',
    'select_quantity': 'प्रमाण निवडा',
    'quantity': 'प्रमाण',
    'description': 'वर्णन',
    'cash_on_delivery': 'कॅश ऑन डिलिव्हरी',
    'same_day_delivery': 'त्याच दिवशी डिलिव्हरी',

    // Cart
    'cart': 'कार्ट',
    'cart_empty': 'तुमचे कार्ट रिकामे आहे',
    'cart_empty_sub': 'सुरू करण्यासाठी वस्तू जोडा',
    'start_shopping': 'खरेदी सुरू करा',
    'checkout': 'चेकआउट',
    'remove': 'काढा',

    // Checkout
    'delivery_address': 'डिलिव्हरी पत्ता',
    'no_address': 'पत्ता जोडला नाही',
    'add_address_hint': 'तुमचा डिलिव्हरी पत्ता जोडा',
    'add_new_address': 'नवीन पत्ता जोडा',
    'full_address': 'पूर्ण पत्ता',
    'city': 'शहर',
    'pincode': 'पिनकोड',
    'cancel': 'रद्द करा',
    'save': 'जतन करा',
    'delivery_slot': 'डिलिव्हरी वेळ',
    'morning': 'सकाळ',
    'afternoon': 'दुपार',
    'evening': 'संध्याकाळ',
    'night': 'रात्र',
    'delivery_notes': 'डिलिव्हरी सूचना (ऐच्छिक)',
    'delivery_notes_hint': 'उदा. बेल दोनदा वाजवा',
    'payment': 'पेमेंट',
    'pay_when_receive': 'मिळाल्यावर पैसे द्या',
    'order_summary': 'ऑर्डर सारांश',
    'subtotal': 'एकूण',
    'delivery': 'डिलिव्हरी',
    'free': 'मोफत',
    'gst': 'जीएसटी',
    'included': 'समाविष्ट',
    'total': 'एकूण',
    'place_order': 'ऑर्डर द्या',

    // Orders
    'my_orders': 'माझ्या ऑर्डर',
    'no_orders': 'अजून ऑर्डर नाही',
    'no_orders_sub': 'तुमच्या ऑर्डर येथे दिसतील',
    'order_placed': 'ऑर्डर दिली',
    'confirmed': 'पुष्टी झाली',
    'packed': 'पॅक केले',
    'out_for_delivery': 'डिलिव्हरीसाठी निघाले',
    'delivered': 'पोहोचवले',
    'cancelled': 'रद्द केले',
    'cancel_order': 'ऑर्डर रद्द करा',

    // Order Success
    'order_success': 'ऑर्डर दिली!',
    'order_success_sub': 'तुमची ऑर्डर यशस्वीरित्या दिली गेली आहे',
    'order_number': 'ऑर्डर नंबर',
    'view_orders': 'माझ्या ऑर्डर पहा',
    'continue_shopping': 'खरेदी सुरू ठेवा',

    // Profile
    'profile': 'प्रोफाइल',
    'edit_profile': 'प्रोफाइल बदला',
    'name': 'नाव',
    'email': 'ईमेल',
    'logout': 'लॉगआउट',
    'update': 'अपडेट',
    'language': 'भाषा',

    // Bottom nav
    'nav_home': 'होम',
    'nav_orders': 'ऑर्डर',
    'nav_cart': 'कार्ट',
    'nav_profile': 'प्रोफाइल',
  };
}

// Global shortcut
String tr(String key) => AppStrings().get(key);

// Language provider for state management
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.mr;

  AppLanguage get language => _language;
  bool get isMarathi => _language == AppLanguage.mr;

  void toggle() {
    _language = _language == AppLanguage.en ? AppLanguage.mr : AppLanguage.en;
    AppStrings().setLanguage(_language);
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    AppStrings().setLanguage(lang);
    notifyListeners();
  }
}
