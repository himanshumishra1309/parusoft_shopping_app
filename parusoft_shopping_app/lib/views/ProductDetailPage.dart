import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../services/product_services.dart';
import 'Cart_view.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  late PageController _imagePageController;
  int _currentImageIndex = 0;
  int _selectedQuantity = 1;
  String? _selectedColor;
  String? _selectedSize;
  bool _isExpanded = false;
  bool _isLoading = false;
  int _inCartQuantity = 0;
  String? _cartItemId;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    
    // Check if product is already in cart
    _checkCartStatus();
    
    // Initialize variant selection
    if (widget.product.variants.isNotEmpty) {
      final firstVariant = widget.product.variants.first;
      _selectedColor = firstVariant.color;
      _selectedSize = firstVariant.size;
    }
    
    // Animation for UI elements
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );
    
    _animationController.forward();
  }
  
  void _checkCartStatus() async {
    try {
      final result = await ProductServices.checkProductInCart(widget.product.id);
      if (mounted) {
        setState(() {
          _inCartQuantity = result['quantity'] ?? 0;
          _cartItemId = result['cartItemId']; // Store cart item ID for updates
        });
      }
    } catch (e) {
      print('Failed to check cart status: $e');
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _addToCart({int? quantity}) async {
  if (!widget.product.isInStock) {
    _showErrorSnackbar('Sorry, this product is out of stock');
    return;
  }

  final int qtyToAdd = quantity ?? _selectedQuantity;

  setState(() {
    _isLoading = true;
  });
  
  try {
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    final result = await ProductServices.addToCart(
      widget.product.id, 
      qtyToAdd
    );
    
    // Consider the operation successful if we get a response
    // or if success flag is explicitly true
    if (result.containsKey('success') ? result['success'] == true : true) {
      // Update cart quantity on success
      setState(() {
        _inCartQuantity += qtyToAdd;
        _cartItemId = result['cartItemId'] ?? _cartItemId; // Store the cart item ID if returned
      });
      _showSuccessSnackbar('Added to your cart');
      
      // Refresh cart status to get cartItemId if it wasn't returned
      if (_cartItemId == null) {
        _checkCartStatus();
      }
    } else {
      _showErrorSnackbar(result['message'] ?? 'Failed to add to cart');
    }
  } catch (e) {
    _showErrorSnackbar('Error adding to cart: ${e.toString().split(":").last}');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  Future<void> _updateCartItemQuantity(int newQuantity) async {
  if (newQuantity < 1) return; // Don't allow quantities less than 1
  
  if (_cartItemId == null || _cartItemId!.isEmpty) {
    // If we don't have a cart item ID, try to add to cart instead
    _addToCart(quantity: newQuantity - _inCartQuantity);
    return;
  }

  setState(() {
    _isLoading = true;
  });
  
  try {
    HapticFeedback.lightImpact();

    final result = await ProductServices.updateCartItem(_cartItemId!, newQuantity);
    
    // Consider the operation successful if we get a non-error response
    // or if success flag is explicitly true
    if (result.containsKey('success') ? result['success'] == true : true) {
      setState(() {
        _inCartQuantity = newQuantity;
      });
      _showSuccessSnackbar('Cart updated');
    } else {
      // Verify if there's an explicit error message
      if (result.containsKey('message') && result['message'] != null) {
        _showErrorSnackbar(result['message']);
      } else {
        // Still refresh cart status even if we don't know if it succeeded
        _checkCartStatus();
      }
    }
  } catch (e) {
    _showErrorSnackbar('Error updating quantity: ${e.toString().split(":").last}');
    // Refresh cart status to ensure UI is in sync with server
    _checkCartStatus();
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  Future<void> _removeFromCart() async {
    if (_cartItemId == null) {
      _showErrorSnackbar('Cannot remove: Item not found in cart');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      HapticFeedback.mediumImpact();

      final result = await ProductServices.removeCartItem(_cartItemId!);
      
      if (result['success'] == true) {
        setState(() {
          _inCartQuantity = 0;
          _cartItemId = null;
        });
        _showSuccessSnackbar('Removed from your cart');
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to remove from cart');
        // Refresh cart status to ensure UI is in sync with server
        _checkCartStatus();
      }
    } catch (e) {
      _showErrorSnackbar('Error removing from cart: ${e.toString().split(":").last}');
      // Refresh cart status to ensure UI is in sync with server
      _checkCartStatus();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: _navigateToCart,
        ),
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[400],
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
  
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartView()),
    ).then((_) => _checkCartStatus());
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

  // Get image widget with proper error handling
  Widget _getProductImage(String imageUrl, int index) {
    final validUrl = _validateImageUrl(imageUrl);
    
    if (validUrl == null) {
      // Use local asset instead
      return Image.asset(
        'assets/images/${index % 2 == 0 ? "product-1.jpg" : "product-2.jpg"}',
        fit: BoxFit.contain,
      );
    }
    
    return CachedNetworkImage(
      imageUrl: validUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) {
        print("Image error: $error for URL: $url");
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSizes = widget.product.variants
        .where((v) => v.color == _selectedColor && v.stock > 0)
        .map((v) => v.size)
        .toSet()
        .toList();
    
    // Check if the currently selected size is still available with the new color
    if (_selectedSize != null && !availableSizes.contains(_selectedSize)) {
      _selectedSize = availableSizes.isNotEmpty ? availableSizes[0] : null;
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.45,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  pinned: true,
                  stretch: true,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  actions: [
                    // Cart icon with badge
                    GestureDetector(
                      onTap: _navigateToCart,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (_inCartQuantity > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    _inCartQuantity.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        // Image Carousel
                        PageView.builder(
                          controller: _imagePageController,
                          itemCount: widget.product.images.isEmpty ? 1 : widget.product.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Container(
                              color: Colors.grey[50],
                              child: Hero(
                                tag: 'product_image_${widget.product.id}',
                                child: widget.product.images.isNotEmpty
                                  ? _getProductImage(widget.product.images[index], index)
                                  : Center(
                                      child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey[400]),
                                    ),
                              ),
                            );
                          },
                        ),
                        // Gradient overlay at bottom of image for better text contrast
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Product Details
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(_animation),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image indicator dots
                          if (widget.product.images.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.product.images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentImageIndex == index ? 18 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: _currentImageIndex == index
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.product.category,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),
                                
                                // Product name
                                Text(
                                  widget.product.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Ratings and Stock status
                                Row(
                                  children: [
                                    // Star ratings
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.product.rating.toStringAsFixed(1),
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${widget.product.reviews.length} reviews)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Stock status
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: widget.product.isInStock ? Colors.green[50] : Colors.red[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.product.isInStock ? 'In Stock' : 'Out of Stock',
                                        style: GoogleFonts.poppins(
                                          color: widget.product.isInStock ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                
                                // Price
                                Row(
                                  children: [
                                    Text(
                                      '\$${widget.product.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    if (widget.product.popularity > 80)
                                      Container(
                                        margin: const EdgeInsets.only(left: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[400],
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          'Best Seller',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    
                                    // Show in cart badge if product is in cart
                                    if (_inCartQuantity > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[600],
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.shopping_cart,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'In Cart',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                const Divider(height: 1),
                                const SizedBox(height: 24),
                                
                                // Description Section
                                Text(
                                  'Description',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Description text with expand/collapse functionality
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  child: AnimatedCrossFade(
                                    firstChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.product.description,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Read more',
                                            style: GoogleFonts.poppins(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    secondChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.product.description,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Read less',
                                            style: GoogleFonts.poppins(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    crossFadeState: _isExpanded 
                                      ? CrossFadeState.showSecond 
                                      : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 300),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                const Divider(height: 1),
                                const SizedBox(height: 24),
                                
                                // Color Options Section
                                if (widget.product.variants.isNotEmpty) ...[
                                  Text(
                                    'Select Color',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: widget.product.availableColors.map((color) {
                                        final isSelected = _selectedColor == color;
                                        final hasStock = widget.product.variants
                                          .any((v) => v.color == color && v.stock > 0);
                                        
                                        return GestureDetector(
                                          onTap: hasStock ? () {
                                            setState(() {
                                              _selectedColor = color;
                                            });
                                            HapticFeedback.lightImpact();
                                          } : null,
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected 
                                                    ? Theme.of(context).primaryColor 
                                                    : Colors.grey[300]!,
                                                  width: 1.5,
                                                ),
                                                boxShadow: isSelected ? [
                                                  BoxShadow(
                                                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ] : null,
                                              ),
                                              child: Text(
                                                color,
                                                style: GoogleFonts.poppins(
                                                  color: isSelected ? Colors.white : (hasStock ? Colors.black : Colors.grey),
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                  decoration: !hasStock ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Size Options Section
                                  if (availableSizes.isNotEmpty) ...[
                                    Text(
                                      'Select Size',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: availableSizes.map((size) {
                                          final isSelected = _selectedSize == size;
                                          
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedSize = size;
                                              });
                                              HapticFeedback.lightImpact();
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 12),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 50,
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected 
                                                      ? Theme.of(context).primaryColor 
                                                      : Colors.grey[300]!,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: isSelected ? [
                                                    BoxShadow(
                                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Text(
                                                  size,
                                                  style: GoogleFonts.poppins(
                                                    color: isSelected ? Colors.white : Colors.black,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  
                                  const Divider(height: 1),
                                  const SizedBox(height: 24),
                                ],
                                
                                // Only show quantity selector if item is not in cart
                                if (_inCartQuantity == 0) ...[
                                  // Quantity Selection Section
                                  Row(
                                    children: [
                                      Text(
                                        'Quantity',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildQuantityButton(
                                              icon: Icons.remove,
                                              onTap: _selectedQuantity > 1 
                                                ? () => setState(() => _selectedQuantity--) 
                                                : null,
                                            ),
                                            Container(
                                              width: 40,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              alignment: Alignment.center,
                                              child: Text(
                                                _selectedQuantity.toString(),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            _buildQuantityButton(
                                              icon: Icons.add,
                                              onTap: () => setState(() => _selectedQuantity++),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 32),
                                ],
                                
                                // Customer Reviews Section
                                Text(
                                  'Customer Reviews',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                if (widget.product.reviews.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No reviews yet',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Be the first to review this product',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Review functionality coming soon!'),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Write a Review',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...widget.product.reviews.take(3).map((review) => _buildReviewItem(review)).toList(),
                                
                                if (widget.product.reviews.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: () {
                                          // Show all reviews
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('View all reviews functionality coming soon!'),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).primaryColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'View All ${widget.product.reviews.length} Reviews',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 100), // Space for the bottom buttons
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom Add to Cart or Quantity Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: _inCartQuantity > 0
                      ? _buildCartQuantityControls()
                      : _buildAddToCartButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Bottom controls when item is already in cart
  Widget _buildCartQuantityControls() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _isLoading ? null : () => _removeFromCart(),
                icon: Icon(
                  Icons.delete_outline,
                  color: _isLoading ? Colors.grey : Colors.red[400],
                ),
                tooltip: 'Remove from cart',
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: _isLoading || _inCartQuantity <= 1 
                      ? null 
                      : () => _updateCartItemQuantity(_inCartQuantity - 1),
                    icon: Icon(
                      Icons.remove,
                      color: _isLoading || _inCartQuantity <= 1 ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      )
                    : Text(
                        _inCartQuantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: _isLoading ? null : () => _updateCartItemQuantity(_inCartQuantity + 1),
                    icon: Icon(
                      Icons.add,
                      color: _isLoading ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: _isLoading ? null : _navigateToCart,
            icon: Icon(
              Icons.shopping_cart,
              color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
            tooltip: 'Go to cart',
          ),
        ),
      ],
    );
  }
  
  // Add to cart button when item is not in cart
  Widget _buildAddToCartButton() {
    return ElevatedButton(
      onPressed: widget.product.isInStock && !_isLoading 
        ? _addToCart 
        : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading 
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_shopping_cart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add to Cart',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : Colors.black,
        ),
      ),
    );
  }
  
  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  review.user.isNotEmpty ? review.user[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '2 days ago', // For demo - would be calculated from createdAt
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
          
          if (review.images != null && review.images!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: AssetImage('assets/${review.images![index]}'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}