import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Payment_Page_view.dart';

class ShippingPage extends StatefulWidget {
  final List<dynamic> items;
  final double totalAmount;

  const ShippingPage({
    Key? key,
    required this.items,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _ShippingPageState createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedShippingMethod = 'standard';
  bool _isLoading = false;

  // Shipping options
  final List<Map<String, dynamic>> _shippingMethods = [
    {
      'id': 'standard',
      'title': 'Standard Shipping',
      'subtitle': '3-5 business days',
      'price': 0.0,
      'icon': Icons.local_shipping_outlined,
    },
    {
      'id': 'express',
      'title': 'Express Shipping',
      'subtitle': '1-2 business days',
      'price': 15.0,
      'icon': Icons.flight_takeoff,
    },
    {
      'id': 'sameday',
      'title': 'Same Day Delivery',
      'subtitle': 'Within 24 hours',
      'price': 25.0,
      'icon': Icons.directions_run,
    },
  ];

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

    // Pre-populate with saved data if available
    _loadSavedShippingInfo();

    _animationController.forward();
  }

  Future<void> _loadSavedShippingInfo() async {
    // In a real app, you would load saved shipping info from storage
    // For demo purposes, we'll use hardcoded sample data
    setState(() {
      _nameController.text = 'John Doe';
      _addressController.text = '123 Main Street';
      _cityController.text = 'New York';
      _stateController.text = 'NY';
      _zipCodeController.text = '10001';
      _phoneController.text = '(555) 123-4567';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Shipping Information',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkout progress indicator
                  _buildProgressIndicator(2),
                  const SizedBox(height: 24),

                  Text(
                    'Shipping Address',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shipping address form
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _addressController,
                            label: 'Street Address',
                            hint: 'Enter your street address',
                            prefixIcon: Icons.home_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // City and State in one row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: _cityController,
                                  label: 'City',
                                  hint: 'Enter city',
                                  prefixIcon: Icons.location_city,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _stateController,
                                  label: 'State',
                                  hint: 'Enter state',
                                  prefixIcon: Icons.map_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ZIP Code and Phone in one row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _zipCodeController,
                                  label: 'ZIP Code',
                                  hint: 'Enter ZIP code',
                                  prefixIcon: Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  hint: 'Enter phone',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Shipping method selection
                  Text(
                    'Shipping Method',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: _shippingMethods.map((method) {
                          final isSelected =
                              _selectedShippingMethod == method['id'];

                          return Column(
                            children: [
                              if (_shippingMethods.indexOf(method) > 0)
                                Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey[200]),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedShippingMethod = method['id'];
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1)
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          method['icon'],
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method['title'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              method['subtitle'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        method['price'] > 0
                                            ? '\$${method['price'].toStringAsFixed(2)}'
                                            : 'Free',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: method['price'] == 0
                                              ? Colors.green[600]
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Radio(
                                        value: method['id'],
                                        groupValue: _selectedShippingMethod,
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedShippingMethod =
                                                value.toString();
                                          });
                                          HapticFeedback.selectionClick();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue to payment button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue to Payment',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[600], size: 22),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
            decoration: BoxDecoration(
              color: index < currentStep
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      // Get shipping fee based on selected method
      final selectedMethod = _shippingMethods
          .firstWhere((method) => method['id'] == _selectedShippingMethod);
      final shippingFee = selectedMethod['price'] as double;

      // Calculate new total with shipping
      final newTotal = widget.totalAmount + shippingFee;

      // Collect shipping info
      final shippingInfo = {
        'name': _nameController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'phone': _phoneController.text,
        'shippingMethod': selectedMethod['title'],
        'shippingFee': shippingFee,
      };

      // Navigate to payment page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            items: widget.items,
            totalAmount: newTotal,
            shippingInfo: shippingInfo,
          ),
        ),
      );
    } else {
      // Scroll to the first error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }
}
