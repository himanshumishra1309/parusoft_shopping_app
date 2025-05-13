import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Confirmation_Page_View.dart';

class PaymentPage extends StatefulWidget {
  final List<dynamic> items;
  final double totalAmount;
  final Map<String, dynamic> shippingInfo;

  const PaymentPage({
    Key? key,
    required this.items,
    required this.totalAmount,
    required this.shippingInfo,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Form fields
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  String _selectedPaymentMethod = 'credit_card';
  bool _isLoading = false;
  bool _saveCard = false;

  // Payment method options
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'credit_card',
      'title': 'Credit Card',
      'icon': Icons.credit_card,
      'requiresForm': true,
    },
    {
      'id': 'paypal',
      'title': 'PayPal',
      'icon': Icons.paypal,
      'requiresForm': false,
    },
    {
      'id': 'google_pay',
      'title': 'Google Pay',
      'icon': Icons.g_mobiledata,
      'requiresForm': false,
    },
    {
      'id': 'apple_pay',
      'title': 'Apple Pay',
      'icon': Icons.apple,
      'requiresForm': false,
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
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
          'Payment',
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
                  _buildProgressIndicator(3),
                  const SizedBox(height: 24),

                  Text(
                    'Payment Method',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment method selection
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
                        children: _paymentMethods.map((method) {
                          final isSelected =
                              _selectedPaymentMethod == method['id'];

                          return Column(
                            children: [
                              if (_paymentMethods.indexOf(method) > 0)
                                Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey[200]),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod = method['id'];
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
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        method['title'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Radio(
                                        value: method['id'],
                                        groupValue: _selectedPaymentMethod,
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPaymentMethod =
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

                  // Credit card form
                  AnimatedOpacity(
                    opacity:
                        _selectedPaymentMethod == 'credit_card' ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _selectedPaymentMethod != 'credit_card',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height:
                            _selectedPaymentMethod == 'credit_card' ? null : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Card Details',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Credit Card UI
                            Stack(
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context)
                                            .primaryColor
                                            .withBlue(150),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'VISA',
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        _cardNumberController.text.isEmpty
                                            ? '•••• •••• •••• ••••'
                                            : _formatCardNumber(
                                                _cardNumberController.text),
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'CARD HOLDER',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              Text(
                                                _cardHolderController
                                                        .text.isEmpty
                                                    ? 'YOUR NAME'
                                                    : _cardHolderController.text
                                                        .toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 40),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'EXPIRES',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              Text(
                                                _expiryController.text.isEmpty
                                                    ? 'MM/YY'
                                                    : _expiryController.text,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'CVV',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              Text(
                                                _cvvController.text.isEmpty
                                                    ? '•••'
                                                    : '•' *
                                                        _cvvController
                                                            .text.length,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Card input fields
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _cardNumberController,
                                    label: 'Card Number',
                                    hint: '1234 5678 9012 3456',
                                    prefixIcon: Icons.credit_card,
                                    keyboardType: TextInputType.number,
                                    formatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(16),
                                      _CardNumberFormatter(),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your card number';
                                      } else if (value
                                              .replaceAll(' ', '')
                                              .length <
                                          16) {
                                        return 'Please enter a valid card number';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _cardHolderController,
                                    label: 'Cardholder Name',
                                    hint: 'John Doe',
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the cardholder name';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),

                                  // Expiry and CVV in one row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _expiryController,
                                          label: 'Expiry Date',
                                          hint: 'MM/YY',
                                          prefixIcon:
                                              Icons.calendar_today_outlined,
                                          keyboardType: TextInputType.number,
                                          formatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                            _ExpiryDateFormatter(),
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            } else if (!_isValidExpiryDate(
                                                value)) {
                                              return 'Invalid date';
                                            }
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _cvvController,
                                          label: 'CVV',
                                          hint: '123',
                                          prefixIcon: Icons.lock_outline,
                                          keyboardType: TextInputType.number,
                                          formatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(3),
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            } else if (value.length < 3) {
                                              return 'Invalid CVV';
                                            }
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Save card for future checkbox
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _saveCard,
                                          onChanged: (value) {
                                            setState(() {
                                              _saveCard = value ?? false;
                                            });
                                            HapticFeedback.selectionClick();
                                          },
                                          activeColor:
                                              Theme.of(context).primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Save card for future payments',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Order summary
                  Text(
                    'Order Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal',
                            '\$${(widget.totalAmount - widget.shippingInfo['shippingFee']).toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Shipping',
                            '\$${widget.shippingInfo['shippingFee'].toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax',
                            '\$${(widget.totalAmount * 0.07).toStringAsFixed(2)}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildSummaryRow(
                          'Total',
                          '\$${widget.totalAmount.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Complete order button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndComplete,
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
                              'Complete Order',
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
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
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
          inputFormatters: formatters,
          onChanged: onChanged,
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

  Widget _buildSummaryRow(String title, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Theme.of(context).primaryColor : Colors.black,
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

  bool _isValidExpiryDate(String value) {
    if (value.length != 5) return false;

    final parts = value.split('/');
    if (parts.length != 2) return false;

    int month;
    int year;

    try {
      month = int.parse(parts[0]);
      year = int.parse(parts[1]);
    } catch (e) {
      return false;
    }

    // Check valid month
    if (month < 1 || month > 12) return false;

    // Check expiry date
    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;

    return (year > currentYear) ||
        (year == currentYear && month >= currentMonth);
  }

  String _formatCardNumber(String input) {
    final digitsOnly = input.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    return buffer.toString();
  }

  void _validateAndComplete() {
    // Only validate form for credit card payment
    if (_selectedPaymentMethod == 'credit_card') {
      if (_formKey.currentState!.validate()) {
        _processPayment();
      } else {
        // Show error if form is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill in all card details correctly',
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
    } else {
      // For other payment methods, just proceed
      _processPayment();
    }
  }

  void _processPayment() {
    setState(() {
      _isLoading = true;
    });

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Get payment details
        final paymentInfo = {
          'method': _selectedPaymentMethod,
          'cardDetails': _selectedPaymentMethod == 'credit_card'
              ? {
                  'cardNumber': _cardNumberController.text,
                  'cardHolder': _cardHolderController.text,
                  'expiry': _expiryController.text,
                  'saveForFuture': _saveCard,
                }
              : null,
        };

        // Navigate to confirmation page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              items: widget.items,
              totalAmount: widget.totalAmount,
              shippingInfo: widget.shippingInfo,
              paymentInfo: paymentInfo,
            ),
          ),
        );

        HapticFeedback.heavyImpact();
      }
    });
  }
}

// Custom formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text;

    if (newText.isEmpty) {
      return newValue;
    }

    final text = newText.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i != text.length - 1) {
        buffer.write('/');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
