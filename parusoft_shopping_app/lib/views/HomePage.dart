import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parusoft_shopping_app/constants/routes.dart';
import 'package:parusoft_shopping_app/views/ProductDetailPage.dart';
import 'package:parusoft_shopping_app/views/Cart_view.dart';
import '../models/product.dart';
import '../services/product_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'dart:math';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool _isGridView = true;
  String _searchQuery = '';
  String _sortBy = 'Newest';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  bool _isLoading = true;
  bool _isSearching = false;
  List<Product> _products = [];
  bool _isCartLoading = false; // Added for cart loading state
  
  // Cart items
  Map<String, int> _cartItems = {};
  double _cartTotal = 0.0;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageLimit = 10;
  
  // Price range
  late RangeValues _currentPriceRange;
  late RangeValues _priceRange;
  double _minPrice = 0;
  double _maxPrice = 1000;
  
  // Rating filter
  double _minRating = 0;
  
  // Search timer for debouncing
  Timer? _searchDebounce;
  
  // Animation controllers
  late TextEditingController _searchController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
void initState() {
  super.initState(); // Keep only one call to super.initState()
  _searchController = TextEditingController(); // Initialize _searchController

   // Add this listener to ensure text field and state stay in sync
  _searchController.addListener(() {
    if (_searchController.text != _searchQuery) {
      _handleSearch(_searchController.text);
    }
  });
  
  // Initialize safe values for price ranges
  _currentPriceRange = RangeValues(_minPrice, _maxPrice);
  _priceRange = RangeValues(_minPrice, _maxPrice);
  
  _loadProducts(isFirstLoad: true);
  _loadCartItems();
  
  // Initialize animations
  _filterAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  
  _filterAnimation = CurvedAnimation(
    parent: _filterAnimationController,
    curve: Curves.easeInOut,
  );
}

  @override
  void dispose() {
  _searchController.dispose();
    _searchDebounce?.cancel();
    _filterAnimationController.dispose();
    super.dispose();
  }

  // Load cart items from service
  Future<void> _loadCartItems() async {
    try {
      final cartData = await ProductServices.getCart();
      final cartItems = cartData['items'] as List? ?? [];
      final totalAmount = cartData['totalAmount'] ?? 0.0;
      
      Map<String, int> newCartItems = {};
      for (var item in cartItems) {
        try {
          if (item['product'] != null) {
            final productId = item['product']['_id'] as String? ?? '';
            final quantity = item['quantity'] as int? ?? 0;
            if (productId.isNotEmpty) {
              newCartItems[productId] = quantity;
            }
          }
        } catch (e) {
          print('Error processing cart item: $e');
          // Skip this item and continue
        }
      }
      
      if (mounted) {
        setState(() {
          _cartItems = newCartItems;
          _cartTotal = totalAmount is int ? totalAmount.toDouble() : (totalAmount as double? ?? 0.0);
        });
      }
      print('Cart loaded: ${_cartItems.length} items, total: \$${_cartTotal.toStringAsFixed(2)}');
    } catch (e) {
      print('Error loading cart items: $e');
      // Don't update state on error - keep existing cart
    }
  }
  
  // Update the _addToCart method for better error handling
  Future<void> _addToCart(Product product) async {
  try {
    print('Attempting to add product to cart: ${product.id}');
    
    // Optimistic UI update first
    setState(() {
      _cartItems[product.id.toString()] = (_cartItems[product.id.toString()] ?? 0) + 1;
      _cartTotal += product.price;
    });
    
    HapticFeedback.mediumImpact();
    
    // Use a key to avoid duplicate SnackBars
    final snackBarKey = GlobalKey<ScaffoldMessengerState>();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: snackBarKey,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('${product.name} added to cart')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            _navigateToCart();
          },
        ),
      ),
    );
    
    // Try server update but don't wait for it to complete the function
    ProductServices.addToCart(product.id.toString(), 1)
      .then((response) {
        if (response['success'] == true) {
          print('Successfully added product to cart on server');
        } else {
          print('Server returned error: ${response['message']}');
        }
      })
      .catchError((e) => print('Server update failed, but UI already updated: $e'));
    
  } catch (e) {
    print('Failed to add to cart: $e');
    // Only revert UI if something went wrong locally
    setState(() {
      // Fixed null safety issue
      _cartItems[product.id.toString()] = (_cartItems[product.id.toString()] ?? 1) - 1;
      if ((_cartItems[product.id.toString()] ?? 0) <= 0) {
        _cartItems.remove(product.id.toString());
      }
      _cartTotal -= product.price;
    });
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to add to cart: ${e.toString().split(":").last}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}

  // Similarly update _removeFromCart
    Future<void> _removeFromCart(Product product) async {
    if (_cartItems[product.id.toString()] == null || _cartItems[product.id.toString()] == 0) {
      return;
    }
    
    try {
      // Optimistic UI update
      setState(() {
        _cartItems[product.id.toString()] = (_cartItems[product.id.toString()] ?? 0) - 1;
        if ((_cartItems[product.id.toString()] ?? 0) <= 0) {  // Fix here: added null check
          _cartItems.remove(product.id.toString());
        }
        _cartTotal -= product.price;
      });
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
      
      // Update server in background
      ProductServices.removeFromCart(product.id.toString())
        .then((response) {
          if (response['success'] == true) {
            print('Successfully removed product from cart on server');
          } else {
            print('Server returned error: ${response['message']}');
          }
        })
        .catchError((e) => print('Server update failed, but UI already updated: $e'));
      
    } catch (e) {
      print('Failed to remove from cart: $e');
      // Only revert UI if something went wrong locally
      setState(() {
        _cartItems[product.id.toString()] = (_cartItems[product.id.toString()] ?? 0) + 1;
        _cartTotal += product.price;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from cart: ${e.toString().split(":").last}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // Image URL validation helper with asset fallbacks
  String? _validateImageUrl(String url, int index) {
    // Early return for empty URLs
    if (url.isEmpty) return null;
    
    // Check if it's a Google redirect URL
    if (url.contains('google.com/url') || 
        url.contains('&url=') || 
        url.contains('?sa=i')) {
      return null; // Return null to trigger asset fallback
    }
    
    // Check for malformed URLs
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null; // Return null to trigger asset fallback
    }
    
    return url;
  }
  
  // Get image widget with proper fallbacks
  Widget _getProductImage(Product product, int index) {
    final imageUrl = product.images.isNotEmpty ? _validateImageUrl(product.images[0], index) : null;
    
    if (imageUrl == null) {
      // Use asset image as fallback
      return Image.asset(
        'assets/images/${index % 2 == 0 ? "product-1.jpg" : "product-2.jpg"}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If even asset fails, show placeholder
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_rounded,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  'No Image',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
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
        return Image.asset(
          'assets/images/${index % 2 == 0 ? "product-1.jpg" : "product-2.jpg"}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No Image',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadProducts({bool isFirstLoad = false, bool isSearch = false}) async {
  if (!mounted) return;
  
  try {
    // Set loading state
    setState(() {
      _isLoading = true;
      
      // Always reset to page 1 for searches and first loads
      if (isFirstLoad || isSearch) {
        _currentPage = 1;
      }
    });

    
    // Create a map of all parameters for better logging
    final requestParams = {
      'category': _selectedCategory == 'All' ? null : _selectedCategory,
      'page': _currentPage,
      'limit': _pageLimit,
      'minPrice': _minPrice != _priceRange.start ? _priceRange.start : null,
      'maxPrice': _maxPrice != _priceRange.end ? _priceRange.end : null,
      'minRating': _minRating > 0 ? _minRating : null,
      'sortBy': _getSortByParameter(),
      'sortOrder': _getSortOrderParameter(),
      'search': _searchQuery.isNotEmpty ? _searchQuery : null,
    };

    
    print("🔍 Executing search with query: '${_searchQuery.isNotEmpty ? _searchQuery : "empty"}'");
    
    // Print consistent debug info with search highlighted
    print("🌐 API Request Parameters:");
    requestParams.forEach((key, value) {
      if (key == 'search' && value != null) {
        print("  ⭐️ $key: '$value'");
      } else {
        print("  $key: $value");
      }
    });
    
    // Make the API call with consistent parameters
    final productsData = await ProductServices.getAllProducts(
      page: _currentPage,
      limit: _pageLimit,
      sortBy: _getSortByParameter(),
      sortOrder: _getSortOrderParameter(),
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      minPrice: _minPrice != _priceRange.start ? _priceRange.start : null,
      maxPrice: _maxPrice != _priceRange.end ? _priceRange.end : null,
      minRating: _minRating > 0 ? _minRating : null,
      search: _searchQuery.isNotEmpty ? _searchQuery : null, // Always pass search if available
    );
    print("🔍 API returned ${(productsData['products'] as List?)?.length ?? 0} products for query: '$_searchQuery'");
    
    if (!mounted) return;
    
    // Debug logs for response
    print("📥 API Response received with ${(productsData['products'] as List? ?? []).length} products");
    
    // Process the response
    final List<dynamic> productsJson = productsData['products'] ?? [];
    
    // Parse pagination data
    final pagination = productsData['pagination'];
    if (pagination != null) {
      _totalPages = pagination['totalPages'] ?? 1;
      print("📄 Total pages: $_totalPages, Current page: $_currentPage");
    }
    
    // Parse products
    final List<Product> loadedProducts = productsJson
        .where((json) => json != null)
        .map<Product>((json) {
          try {
            return Product.fromJson(json);
          } catch (e) {
            print("⚠️ Error parsing product: $e");
            // Skip invalid products
            return Product(
              id: 'error',
              name: 'Error loading product',
              description: '',
              price: 0,
              rating: 0,
              category: 'Error',
              images: [],
              popularity: 0,
              releaseDate: '',
              variants: [],
              reviews: [],
            );
          }
        })
        .where((product) => product.id != 'error')
        .toList();
    
    if (!mounted) return;
    
    setState(() {
      // Replace products instead of adding to them
      _products = loadedProducts;
      _isLoading = false;
      _isSearching = false;
      
      // Extract unique categories on first load
      if (isFirstLoad) {
        final Set<String> categorySet = {
          'All',
          ..._products.map((product) => product.category).toSet()
        };
        _categories = categorySet.toList();
        
        // Set min and max price from all products on first load
        if (_products.isNotEmpty) {
          double minFound = _products.fold(double.infinity, 
            (prev, product) => product.price < prev ? product.price : prev);
          _minPrice = minFound == double.infinity ? 0 : minFound;
          
          double maxFound = _products.fold(0.0, 
            (prev, product) => product.price > prev ? product.price : prev);
          _maxPrice = maxFound <= _minPrice ? _minPrice + 1000 : maxFound;
            
          // Initialize price range on first load with safe values
          _priceRange = RangeValues(_minPrice, _maxPrice);
          _currentPriceRange = RangeValues(_minPrice, _maxPrice);
        }
      }
      
      // Display search result info
      if (isSearch) {
        print("🔍 Search results for '$_searchQuery': ${_products.length} products found");
      }
    });
  } catch (e) {
    print("❌ Error loading products: $e");
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSearching = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _loadProducts(isFirstLoad: isFirstLoad, isSearch: isSearch),
          ),
        ),
      );
    }
  }
}
  Future<void> _refreshProducts() async {
    setState(() {
      _currentPage = 1;
      // Clear search when refreshing
      _searchQuery = '';
    });
    await _loadProducts(isFirstLoad: true);
    await _loadCartItems();
  }

  String _getSortByParameter() {
    switch (_sortBy) {
      case 'Price: High-Low':
        return 'price';
      case 'Price: Low-High':
        return 'price';
      case 'Rating':
        return 'rating';
      case 'Popularity':
        return 'popularity';
      case 'Newest':
      default:
        return 'createdAt';
    }
  }

  String _getSortOrderParameter() {
    if (_sortBy == 'Price: Low-High') {
      return 'asc';
    }
    return 'desc';
  }
  
  // Add this getter method to filter products locally if server doesn't do it
List<Product> get filteredProducts {
  if (_searchQuery.isEmpty) {
    return _products;
  }
  
  // Add local filtering
  final searchLower = _searchQuery.toLowerCase();
  return _products.where((product) {
    return product.name.toLowerCase().contains(searchLower) ||
           product.description.toLowerCase().contains(searchLower) ||
           product.category.toLowerCase().contains(searchLower);
  }).toList();
}

  int get cartItemCount {
    return _cartItems.values.fold(0, (prev, qty) => prev + qty);
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  // Updated with loading state
  Future<void> _navigateToCart() async {
    setState(() {
      _isCartLoading = true;
    });
    
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartView()),
      );
      await _loadCartItems();
    } catch (e) {
      print('Error navigating to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open cart: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCartLoading = false;
        });
      }
    }
  }

  void _openFilters() {
    // Ensure price ranges are valid before opening filter sheet
    setState(() {
      if (_priceRange.start < _minPrice) {
        _priceRange = RangeValues(_minPrice, _priceRange.end);
      }
      if (_priceRange.end > _maxPrice) {
        _priceRange = RangeValues(_priceRange.start, _maxPrice);
      }
      if (_priceRange.start > _priceRange.end) {
        _priceRange = RangeValues(_minPrice, _maxPrice);
      }
      
      _currentPriceRange = RangeValues(
        max(_minPrice, min(_priceRange.start, _maxPrice)),
        min(_maxPrice, max(_priceRange.end, _minPrice))
      );
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }

  Widget _buildFilterSheet() {
    // Ensure price ranges are valid before initializing temp values
    double safeMinPrice = _minPrice;
    double safeMaxPrice = _maxPrice;
    
    // Sanity check for min/max prices to avoid RangeSlider errors
    if (safeMinPrice >= safeMaxPrice) {
      safeMaxPrice = safeMinPrice + 100;
    }
    
    // Create a safe initial price range that's guaranteed valid
    RangeValues tempPriceRange = RangeValues(
      max(safeMinPrice, min(_currentPriceRange.start, safeMaxPrice - 1)),
      min(safeMaxPrice, max(_currentPriceRange.end, safeMinPrice + 1))
    );
    
    String tempCategory = _selectedCategory;
    double tempRating = _minRating;
    
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 1,
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Products',
                      style: GoogleFonts.poppins(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories', 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, 
                          fontSize: 18
                        )
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: _categories.map((category) => 
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ChoiceChip(
                              label: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: tempCategory == category ? Colors.white : Colors.black87,
                                )
                              ),
                              selected: tempCategory == category,
                              selectedColor: Theme.of(context).primaryColor,
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              elevation: tempCategory == category ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              onSelected: (selected) {
                                setModalState(() {
                                  tempCategory = selected ? category : tempCategory;
                                });
                                HapticFeedback.lightImpact();
                              },
                            ),
                          )
                        ).toList(),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Price Range', 
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, 
                              fontSize: 18
                            )
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '\$${tempPriceRange.start.toStringAsFixed(0)} - \$${tempPriceRange.end.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                          overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
                        child: RangeSlider(
                          values: tempPriceRange,
                          min: safeMinPrice,
                          max: safeMaxPrice,
                          divisions: max(((safeMaxPrice - safeMinPrice) / 5).floor(), 1),
                          labels: RangeLabels(
                            '\$${tempPriceRange.start.round()}',
                            '\$${tempPriceRange.end.round()}',
                          ),
                          onChanged: (RangeValues values) {
                            // Ensure values are within bounds and start <= end
                            setModalState(() {
                              // Make sure start is never greater than end - 1 to avoid assertion
                              if (values.start >= values.end) {
                                tempPriceRange = RangeValues(values.start, values.start + 1);
                              } else {
                                tempPriceRange = values;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Minimum Rating', 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, 
                          fontSize: 18
                        )
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                // Toggle rating if tapping the same star
                                if (tempRating == index + 1) {
                                  tempRating = 0;
                                } else {
                                  tempRating = index + 1.0;
                                }
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: index < tempRating 
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[200],
                                shape: BoxShape.circle,
                                boxShadow: index < tempRating 
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                              ),
                              child: Icon(
                                Icons.star,
                                color: index < tempRating ? Colors.white : Colors.grey[400],
                                size: 24,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    )
                  ]
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            // Use safe values for the reset
                            tempPriceRange = RangeValues(safeMinPrice, safeMaxPrice);
                            tempRating = 0;
                            tempCategory = 'All';
                          });
                          HapticFeedback.lightImpact();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Apply filters safely
                            _priceRange = tempPriceRange;
                            _currentPriceRange = tempPriceRange;
                            _selectedCategory = tempCategory;
                            _minRating = tempRating;
                            _currentPage = 1; // Reset pagination when filters change
                          });
                          Navigator.pop(context);
                          
                          // Load products with all active filters
                          _loadProducts(isFirstLoad: true);
                          HapticFeedback.mediumImpact();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          elevation: 2,
                          shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
// Replace your _handleSearch method with this implementation
void _handleSearch(String query) {
  // Cancel any previous debounce timer
  _searchDebounce?.cancel();
  
  // Update the controller text to match the query
  if (_searchController.text != query) {
    _searchController.text = query;
  }
  
  // Set up a new timer
  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
    print("🔍 Search triggered with query: '$query'");
    
    // First set searching state
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Always reset to first page when search changes
      _isSearching = true; // Show loading indicator
    });
    
    // Then load products with the search parameter
    _loadProducts(isSearch: true);
  });
}

// Add this method to ensure your search state is consistent
void _resetSearch() {
  setState(() {
    _searchQuery = '';
    _searchController.text = '';
    _isSearching = false;
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parusoft',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Shopping Collection',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Header actions
                  Row(
                    children: [
                      // Grid/List toggle
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _toggleView,
                        tooltip: _isGridView ? 'List View' : 'Grid View',
                      ),
                      // Cart button with badge and total amount
                      Stack(
                        children: [
                          if (_isCartLoading)
                            Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.shopping_cart,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: _navigateToCart,
                              tooltip: 'Cart',
                            ),
                          if (cartItemCount > 0 && !_isCartLoading)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$cartItemCount',
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
                    ],
                  ),
                ],
              ),
            ),
            
            // Cart total indicator
            if (_cartTotal > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cart Total: \$${_cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
  controller: _searchController,
  decoration: InputDecoration(
    hintText: 'Search products...',
    hintStyle: GoogleFonts.poppins(
      color: Colors.grey[400],
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Icon(
      Icons.search_rounded,
      color: Theme.of(context).primaryColor,
    ),
    suffixIcon: _searchQuery.isNotEmpty
      ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            _handleSearch('');
          },
        )
      : (_isSearching 
          ? Container(
              width: 50,
              alignment: Alignment.center,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            )
          : IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
              onPressed: _openFilters,
            )
      ),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  ),
  style: GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
  ),
  onChanged: _handleSearch,
)
              ),
            ),
            
            // Sort and pagination info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).primaryColor,
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            items: <String>['Newest', 'Price: High-Low', 'Price: Low-High', 'Rating', 'Popularity']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortBy = newValue;
                                  _currentPage = 1; // Reset pagination when sorting changes
                                });
                                _loadProducts(isFirstLoad: true);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Pagination info display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Page $_currentPage/$_totalPages',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Active filters chips
            if (_selectedCategory != 'All' || _minRating > 0 || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      if (_searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              'Search: $_searchQuery',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[700],
                              ),
                            ),
                            backgroundColor: Colors.blue[50],
                            deleteIconColor: Colors.blue[700],
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                              _loadProducts(isFirstLoad: true);
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ),
                      if (_selectedCategory != 'All')
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              _selectedCategory,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            deleteIconColor: Theme.of(context).primaryColor,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedCategory = 'All';
                                _currentPage = 1;
                              });
                              _loadProducts(isFirstLoad: true);
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ),
                      if (_minRating > 0)
                        Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rating ≥ ',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                '$_minRating',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                            ],
                          ),
                          backgroundColor: Colors.white,
                          deleteIconColor: Theme.of(context).primaryColor,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _minRating = 0;
                              _currentPage = 1;
                            });
                            _loadProducts(isFirstLoad: true);
                            HapticFeedback.lightImpact();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
            // Products grid/list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshProducts,
                color: Theme.of(context).primaryColor,
                child: _isLoading
                  ? _buildLoadingShimmer()
                  : filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                      ? _buildProductsGrid()
                      : _buildProductsList(),
              ),
            ),
            
            // Pagination controls at the bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous page button
                  ElevatedButton(
                    onPressed: _currentPage > 1 ? () {
                      setState(() {
                        _currentPage--;
                      });
                      _loadProducts();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios, size: 14),
                        const SizedBox(width: 4),
                        Text('Previous', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  
                  // Page counter
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Next page button
                  ElevatedButton(
                    onPressed: _currentPage < _totalPages ? () {
                      setState(() {
                        _currentPage++;
                      });
                      _loadProducts();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('Next', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
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

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(20),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
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

  Widget _buildEmptyState() {
    return Center(
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
              Icons.search_off_rounded,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Products Found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _resetSearch();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
                _priceRange = RangeValues(_minPrice, _maxPrice);
                _currentPriceRange = RangeValues(_minPrice, _maxPrice);
                _minRating = 0;
                _currentPage = 1;
              });
              _loadProducts(isFirstLoad: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear All Filters',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58, // Adjusted for more height
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductGridItem(product, index);
      },
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: filteredProducts.length, // Only show current page items
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductListItem(product, index);
      },
    );
  }

  Widget _buildProductGridItem(Product product, int index) {
    // Get quantity in cart
    final inCartQty = _cartItems[product.id.toString()] ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to detail page on tapping the product card
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(product: product),
                ),
              ).then((_) => _loadCartItems());
            },
            splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
            highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with proper error handling
                Stack(
                  children: [
                    Hero(
                      tag: 'product_image_${product.id}',
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: _getProductImage(product, index),
                      ),
                    ),
                    // Show cart badge if item is in cart
                    if (inCartQty > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'In Cart: $inCartQty',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    // Stock badge
                    if (!product.isInStock)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Product info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < product.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            // Cart controls
                            inCartQty > 0 
                              ? Row(
                                  children: [
                                    // Remove button
                                    InkWell(
                                      onTap: () {
                                        _removeFromCart(product);
                                      },
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red[400],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '$inCartQty',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                                                        // Add more button
                                    InkWell(
                                      onTap: product.isInStock ? () {
                                        _addToCart(product);
                                      } : null,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: product.isInStock 
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : InkWell(
                                  onTap: product.isInStock ? () {
                                    _addToCart(product);
                                  } : null,
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: product.isInStock 
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // List view implementation for products
  Widget _buildProductListItem(Product product, int index) {
    // Get quantity in cart
    final inCartQty = _cartItems[product.id.toString()] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to detail page on tapping the product card
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(product: product),
                ),
              ).then((_) => _loadCartItems());
            },
            splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
            highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with proper error handling
                Stack(
                  children: [
                    Hero(
                      tag: 'product_image_${product.id}',
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[100],
                        child: _getProductImage(product, index),
                      ),
                    ),
                    // Show out of stock badge
                    if (!product.isInStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Product info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < product.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            // Cart controls
                            inCartQty > 0 
                              ? Row(
                                  children: [
                                    // Remove button
                                    InkWell(
                                      onTap: () {
                                        _removeFromCart(product);
                                      },
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red[400],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '$inCartQty',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Add more button
                                    InkWell(
                                      onTap: product.isInStock ? () {
                                        _addToCart(product);
                                      } : null,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: product.isInStock 
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : InkWell(
                                  onTap: product.isInStock ? () {
                                    _addToCart(product);
                                  } : null,
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: product.isInStock 
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}