import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../services/product_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import 'ProductDetailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartView extends StatefulWidget {
  const CartView({Key? key}) : super(key: key);

  @override
  _CartViewState createState() => _CartViewState();
}

class _CartViewState extends State<CartView> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _cart;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Debounce for quantity updates
  Timer? _debounceTimer;
  
  // In-memory cache of modifications waiting to be pushed to server
  final Map<String, int> _pendingQuantityUpdates = {};
  
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    
    // Try loading from cache first, then fetch from server
    _loadCartFromCache().then((_) {
      _loadCartFromServer();
    });
    
    // Initialize animation controller for slide-in effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Helper for local caching
  Future<void> _saveCartToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cart != null) {
        await prefs.setString('cart_cache', jsonEncode(_cart));
        await prefs.setInt('cart_cache_time', DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Error saving cart to cache: $e');
    }
  }

  Future<void> _loadCartFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCart = prefs.getString('cart_cache');
      final cacheTime = prefs.getInt('cart_cache_time');
      
      if (cachedCart != null && cacheTime != null) {
        // Check if cache is less than 15 minutes old
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < 15 * 60 * 1000) {
          setState(() {
            _cart = jsonDecode(cachedCart);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading cart from cache: $e');
    }
  }

  // Helper method for validating image URLs
  String? _validateImageUrl(String url) {
    // Early return for empty URLs
    if (url.isEmpty) return null;
    
    // Check if it's a Google redirect URL
    if (url.contains('google.com/url') || 
        url.contains('&url=') || 
        url.contains('?sa=i')) {
      return null;
    }
    
    // Check for malformed URLs
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }
    
    return url;
  }
  
  // Get image widget with fallback to local assets
  Widget _getProductImage(String? imageUrl, int index) {
    final validUrl = imageUrl != null ? _validateImageUrl(imageUrl) : null;
    
    if (validUrl == null) {
      // Use local asset instead
      return Image.asset(
        'assets/images/${index % 2 == 0 ? "product-1.jpg" : "product-2.jpg"}',
        fit: BoxFit.cover,
      );
    }
    
    return CachedNetworkImage(
      imageUrl: validUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
          strokeWidth: 2,
        ),
      ),
      errorWidget: (context, url, error) {
        print("Image error: $error for URL: $url");
        // Fall back to local asset on error
        return Image.asset(
          'assets/images/${index % 2 == 0 ? "product-1.jpg" : "product-2.jpg"}',
          fit: BoxFit.cover,
        );
      },
    );
  }

  Future<void> _loadCartFromServer() async {
    if (mounted) {
      setState(() {
        _isLoading = _cart == null; // Only show loading if we don't have cached data
        _isError = false;
      });
    }
    
    try {
      final cart = await ProductServices.getCart();
      
      if (mounted) {
        setState(() {
          _cart = cart;
          _isLoading = false;
          _isError = false;
        });
        
        // Update cache with fresh data
        _saveCartToCache();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_cart == null) {
            // Only show error if we don't have any cached data
            _isError = true;
            _errorMessage = 'Error loading cart: $e';
          }
        });
      }
    }
  }
  
  Future<void> _refreshCart() async {
    return _loadCartFromServer();
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            _loadCartFromServer();
          },
        ),
      ),
    );
  }
  
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateQuantity(String itemId, int quantity, {bool immediate = false}) async {
    // Update UI immediately for responsive feel
    setState(() {
      if (_cart != null && _cart!['items'] is List) {
        final items = List.from(_cart!['items']);
        final index = items.indexWhere((item) => item['_id'] == itemId);
        if (index != -1) {
          final oldQuantity = items[index]['quantity'];
          items[index]['quantity'] = quantity;
          
          // Update total price
          final price = items[index]['product']['price'];
          _cart!['totalAmount'] = (_cart!['totalAmount'] ?? 0) - (price * oldQuantity) + (price * quantity);
          
          _cart!['items'] = items;
        }
      }
    });
    
    // Add to pending updates
    _pendingQuantityUpdates[itemId] = quantity;
    
    // Cancel previous debounce if it exists
    _debounceTimer?.cancel();
    
    // Only send update to server after debounce or if immediate
    if (immediate) {
      _sendQuantityUpdate(itemId, quantity);
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _sendQuantityUpdate(itemId, quantity);
      });
    }
  }
  
  Future<void> _sendQuantityUpdate(String itemId, int quantity) async {
    try {
      await ProductServices.updateCartItem(itemId, quantity);
      // Remove from pending updates once successful
      _pendingQuantityUpdates.remove(itemId);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorSnackbar('Could not update item: $e');
      // Reload to reset UI state
      _loadCartFromServer();
    }
  }
  
  Future<void> _removeCartItem(String itemId) async {
    try {
      // Update UI immediately for better UX
      setState(() {
        if (_cart != null && _cart!['items'] is List) {
          final items = List.from(_cart!['items']);
          final index = items.indexWhere((item) => item['_id'] == itemId);
          
          if (index != -1) {
            // Calculate item price to subtract from total
            final product = items[index]['product'];
            final quantity = items[index]['quantity'];
            final itemTotal = product['price'] * quantity;
            
            // Remove item and update total
            items.removeAt(index);
            _cart!['items'] = items;
            _cart!['totalAmount'] = (_cart!['totalAmount'] ?? 0) - itemTotal;
          }
        }
      });
      
      // Update cache with the updated cart
      _saveCartToCache();
      
      // Then perform the API call
      await ProductServices.removeFromCart(itemId);
      _showSuccessSnackbar('Item removed from cart');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showErrorSnackbar('Could not remove item: $e');
      // Reload to reset UI state
      _loadCartFromServer();
    }
  }
  
  Future<void> _clearCart() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Update UI immediately
      setState(() {
        if (_cart != null) {
          _cart!['items'] = [];
          _cart!['totalAmount'] = 0;
        }
      });
      
      // Update cache
      _saveCartToCache();
      
      // Call API
      await ProductServices.clearCart();
      _showSuccessSnackbar('Cart cleared');
      HapticFeedback.heavyImpact();
    } catch (e) {
      _showErrorSnackbar('Could not clear cart: $e');
      // Reload to reset UI state
      _loadCartFromServer();
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _proceedToCheckout() async {
    // Send any pending quantity updates immediately
    for (final entry in _pendingQuantityUpdates.entries) {
      await _sendQuantityUpdate(entry.key, entry.value);
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // In a real app, this would navigate to a checkout page
      // For demo purposes, we'll just show a success message
      await Future.delayed(const Duration(seconds: 1));
      _showSuccessSnackbar('Order placed successfully!');
      
      // Clear cart locally first for instant feedback
      setState(() {
        if (_cart != null) {
          _cart!['items'] = [];
          _cart!['totalAmount'] = 0;
        }
      });
      
      // Then clear on server
      await ProductServices.clearCart();
      
      // Update cache with empty cart
      _saveCartToCache();
      
      HapticFeedback.heavyImpact();
    } catch (e) {
      _showErrorSnackbar('Error processing checkout: $e');
      _loadCartFromServer(); // Reload actual state
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Navigate to product detail page
  void _navigateToProductDetail(Map<String, dynamic> productData) {
    try {
      // Convert the map data to a Product object
      final product = Product(
        id: productData['_id'] ?? '',
        name: productData['name'] ?? '',
        description: productData['description'] ?? '',
        price: (productData['price'] ?? 0).toDouble(),
        rating: (productData['rating'] ?? 0).toDouble(),
        category: productData['category'] ?? '',
        images: List<String>.from(productData['images'] ?? []),
        popularity: (productData['popularity'] ?? 0).toDouble(),
        releaseDate: productData['createdAt'] ?? '',
        variants: [], // Add variants if available
        reviews: [], // Add reviews if available
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: product),
        ),
      ).then((_) => _loadCartFromServer()); // Reload cart when returning
    } catch (e) {
      print('Error navigating to product detail: $e');
      _showErrorSnackbar('Could not open product details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_cart != null && _cart!['items'] is List && _cart!['items'].isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[400],
              onPressed: () => _showClearCartDialog(),
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshCart,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? _buildLoadingState()
            : _isError && _cart == null
                ? _buildErrorState()
                : _cart == null || _cart!['items'] == null || _cart!['items'].isEmpty
                    ? _buildEmptyState()
                    : _buildCartContent(),
      ),
      bottomNavigationBar: _isLoading || _cart == null || _cart!['items'] == null || _cart!['items'].isEmpty
          ? null
          : _buildCheckoutSection(),
    );
  }
  
  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 70,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load cart',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCartFromServer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_animation),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Your Cart is Empty',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start shopping and add some items to your cart!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Explore Products',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCartContent() {
    final items = _cart!['items'] as List;
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemBuilder: (context, index) {
        final item = items[index];
        final product = item['product'];
        final itemId = item['_id'];
        final quantity = item['quantity'];
        final variant = item['variant'];
        
        // Calculate staggered animation delay based on index
        final animationDelay = index * 0.1;
        
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // Calculate delayed animation value
            final delayedAnimation = _animation.value - animationDelay;
            final animationValue = delayedAnimation.clamp(0.0, 1.0);
            
            return Opacity(
              opacity: animationValue,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animationValue)),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: Key(itemId),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_sweep,
                color: Colors.white,
                size: 28,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Remove Item',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to remove this item from your cart?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text(
                          'Remove',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              _removeCartItem(itemId);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _navigateToProductDetail(product),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image with fixed fallback
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[100],
                          child: product['images'] != null && product['images'].isNotEmpty
                            ? _getProductImage(product['images'][0], index)
                            : Image.asset(
                                'assets/images/${index % 2 == 0 ? "product-1.jpg" : "product-2.jpg"}',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['category'],
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['name'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Display variant info if available
                            if (variant != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        'Variant: ${variant['color']} - ${variant['size']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${(product['price'] * quantity).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildQuantityButton(
                                        icon: Icons.remove,
                                        onTap: quantity > 1 
                                          ? () => _updateQuantity(itemId, quantity - 1)
                                          : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(color: Colors.grey[300]!),
                                            right: BorderSide(color: Colors.grey[300]!),
                                          ),
                                        ),
                                        child: Text(
                                          quantity.toString(),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _buildQuantityButton(
                                        icon: Icons.add,
                                        onTap: () => _updateQuantity(itemId, quantity + 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuantityButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Colors.grey : Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildCheckoutSection() {
    final double totalAmount = _cart!['totalAmount'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Free',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      'Checkout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear Cart',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove all items from your cart?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _clearCart();
              },
            ),
          ],
        );
      },
    );
  }
}