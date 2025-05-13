import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:parusoft_shopping_app/views/Cart_view.dart';
import 'package:parusoft_shopping_app/views/HomePage.dart';
import '../services/product_services.dart';
import 'dart:math';

class ConfirmationPage extends StatefulWidget {
  final List<dynamic> items;
  final double totalAmount;
  final Map<String, dynamic> shippingInfo;
  final Map<String, dynamic> paymentInfo;

  const ConfirmationPage({
    Key? key,
    required this.items,
    required this.totalAmount,
    required this.shippingInfo,
    required this.paymentInfo,
  }) : super(key: key);

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isProcessing = true;
  bool _isSuccess = false;
  String _orderNumber = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );

    _animationController.forward();

    // Process the order
    _processOrder();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    try {
      // Simulate order processing with delay
      await Future.delayed(const Duration(seconds: 2));

      // Create a random order number
      final random = Random();
      _orderNumber =
          'ORD-${DateTime.now().year}${10000 + random.nextInt(90000)}';

      // Call the API to place the order
      final result = await ProductServices.placeOrder(
        items: widget.items,
        shippingInfo: widget.shippingInfo,
        paymentInfo: widget.paymentInfo,
        total: widget.totalAmount,
      );

      // Update state based on API response
      setState(() {
        _isProcessing = false;
        _isSuccess = result['success'] == true;
      });

      // Clear cart if order was successful
      if (_isSuccess) {
        await ProductServices.clearCart();
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      print('Order processing error: $e');
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error processing order: ${e.toString().split(':').last}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isProcessing
                ? _buildProcessingView()
                : _isSuccess
                    ? _buildSuccessView()
                    : _buildErrorView(),
          ),
        ),
      ),
    );
  }

  // Replace the Lottie animation in _buildProcessingView method with this safer implementation
Widget _buildProcessingView() {
  return FadeTransition(
    opacity: _animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_animation),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Replace problematic Lottie with a safer animation
          _buildSafeAnimation(),
          const SizedBox(height: 30),
          Text(
            'Processing Your Order',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Please wait while we process your payment and confirm your order',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ],
      ),
    ),
  );
}

// Add this new method to your _ConfirmationPageState class for safe animation loading
Widget _buildSafeAnimation() {
  try {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fallback animated widget that doesn't use external images
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor.withOpacity(0.5),
                ),
              ),
            ),
            // Pulsing circle animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Container(
                  width: 80 + (20 * value),
                  height: 80 + (20 * value),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3 * (1 - value)),
                    shape: BoxShape.circle,
                  ),
                );
              },
              onEnd: () => setState(() {}), // Restart animation
            ),
            // Shopping icon
            Icon(
              Icons.shopping_bag_outlined,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    print("Error building animation: $e");
    // Ultra-safe fallback
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}

  Widget _buildSuccessView() {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[50],
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Order Confirmed!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your order has been placed successfully',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildConfirmationCard(),
            const SizedBox(height: 40),
            // Replace the Continue Shopping button's onPressed method with this implementation
            ElevatedButton(
              onPressed: () {
                // Safer approach to return to home screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(),
                    settings: const RouteSettings(name: '/home'),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              child: Text(
                'Continue Shopping',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Show order details
                _showOrderDetails();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'View Order Details',
                style: GoogleFonts.poppins(
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Number',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _orderNumber,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _getPaymentMethodDisplay(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping To',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                child: Text(
                  _getShippingAddressShort(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(
            height: 32,
            thickness: 1,
            color: Color(0xFFEAEAEA),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${widget.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[50],
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Order Failed',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t process your order at this time',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Please check your payment details and try again. If the problem persists, contact customer support.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red[900],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to payment page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navigate to cart
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const CartView()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Return to Cart',
                style: GoogleFonts.poppins(
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Order Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID
                    Text(
                      'Order #$_orderNumber',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Placed on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Items section
                    Text(
                      'Items',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.items
                        .map((item) => _buildOrderItemRow(item))
                        .toList(),

                    const Divider(height: 32),

                    // Shipping info section
                    Text(
                      'Shipping Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Name', widget.shippingInfo['name'] ?? ''),
                    _buildInfoRow('Address', _getFullAddress()),
                    _buildInfoRow('Phone', widget.shippingInfo['phone'] ?? ''),
                    _buildInfoRow('Method',
                        widget.shippingInfo['method'] ?? 'Standard Delivery'),

                    const Divider(height: 32),

                    // Payment info section
                    Text(
                      'Payment Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Method', _getPaymentMethodDisplay()),
                    if (widget.paymentInfo['cardLast4'] != null)
                      _buildInfoRow('Card',
                          '**** **** **** ${widget.paymentInfo['cardLast4']}'),

                    const Divider(height: 32),

                    // Order summary section
                    Text(
                      'Order Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                        'Subtotal',
                        widget.totalAmount -
                            (widget.shippingInfo['fee'] ?? 0.0)),
                    _buildSummaryRow(
                        'Shipping', widget.shippingInfo['fee'] ?? 0.0),
                    _buildSummaryRow('Tax', widget.totalAmount * 0.05,
                        isSmall: true),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Total', widget.totalAmount,
                        isTotal: true),
                  ],
                ),
              ),
            ),
            // Download receipt button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt download will be available soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.download),
                label: Text(
                  'Download Receipt',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to the _ConfirmationPageState class
  Widget _getSafeImage(String? imageUrl,
      {double width = 60, double height = 60}) {
    // Return placeholder for null or empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Check if URL is valid
    bool isValidUrl =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    if (!isValidUrl) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Use ClipRRect to apply borderRadius to Image widget
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: width,
          height: height,
          // Enable image caching
          cacheWidth: (width * 2).toInt(),
          cacheHeight: (height * 2).toInt(),
          // Error builder for better error handling
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            );
          },
          // Loading placeholder
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Replace _buildOrderItemRow with this safer implementation
  Widget _buildOrderItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getSafeImage(item['image']?.toString()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown Product',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item['quantity']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build summary rows
  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 12 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isSmall ? Colors.grey[600] : Colors.black87,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 12 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to format information
  String _getPaymentMethodDisplay() {
    switch (widget.paymentInfo['method']) {
      case 'card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return widget.paymentInfo['method'] ?? 'Unknown Method';
    }
  }

  String _getShippingAddressShort() {
    final city = widget.shippingInfo['city'] ?? '';
    final state = widget.shippingInfo['state'] ?? '';
    return '$city, $state';
  }

  String _getFullAddress() {
    final address = widget.shippingInfo['address'] ?? '';
    final city = widget.shippingInfo['city'] ?? '';
    final state = widget.shippingInfo['state'] ?? '';
    final zip = widget.shippingInfo['zip'] ?? '';
    final country = widget.shippingInfo['country'] ?? '';
    return '$address, $city, $state $zip, $country';
  }
}
