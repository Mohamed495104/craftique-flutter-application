import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;

  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String phoneNumber = '';
  String houseNumber = '';
  String street = '';
  String city = '';
  String postalCode = '';
  String paymentMethod = 'Credit Card';

  String cardNumber = '';
  String expiryDate = '';
  String cvv = '';

  bool _isPlacing = false;

  bool get isCardPayment =>
      paymentMethod == 'Credit Card' || paymentMethod == 'Debit Card';

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8B4513),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8B4513)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_isPlacing) return; // guard against double taps
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isPlacing = true);
    try {
      // await ordersRef.add(orderData);

      // Clear the cart locally (and in Firebase via provider)
      if (!mounted) return;
      await context.read<CartProvider>().clearCart();

      // Navigate to your confirmation screen
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/order-confirmation',
        arguments: {
          'totalAmount': widget.totalAmount,
          'paymentMethod': paymentMethod,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong placing your order.'),
          backgroundColor: Color(0xFF8B4513),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8B4513).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFF8B4513),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '\$${widget.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Information Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8B4513).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF8B4513),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: "First Name",
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter first name'
                                          : null,
                                  onSaved: (value) => firstName = value ?? '',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: "Last Name",
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter last name'
                                          : null,
                                  onSaved: (value) => lastName = value ?? '',
                                ),
                              ),
                            ],
                          ),
                          _buildTextField(
                            label: "Phone Number",
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                value == null || value.length < 10
                                    ? 'Enter valid phone'
                                    : null,
                            onSaved: (value) => phoneNumber = value ?? '',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Delivery Address Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8B4513).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF8B4513),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  label: "House #",
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Required'
                                          : null,
                                  onSaved: (value) => houseNumber = value ?? '',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  label: "Street",
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter street name'
                                          : null,
                                  onSaved: (value) => street = value ?? '',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: "City",
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter city'
                                          : null,
                                  onSaved: (value) => city = value ?? '',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: "Postal Code",
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter postal code'
                                          : null,
                                  onSaved: (value) => postalCode = value ?? '',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8B4513).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: Color(0xFF8B4513),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: DropdownButtonFormField<String>(
                              value: paymentMethod,
                              decoration: InputDecoration(
                                labelText: "Select Payment Method",
                                labelStyle:
                                    const TextStyle(color: Color(0xFF8B4513)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(
                                      color: Color(0xFF8B4513), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              items: [
                                "Credit Card",
                                "Debit Card",
                                "PayPal",
                                "Cash on Delivery"
                              ]
                                  .map((method) => DropdownMenuItem(
                                        value: method,
                                        child: Row(
                                          children: [
                                            Icon(
                                              method == 'Credit Card' ||
                                                      method == 'Debit Card'
                                                  ? Icons.credit_card
                                                  : method == 'PayPal'
                                                      ? Icons
                                                          .account_balance_wallet
                                                      : Icons.local_shipping,
                                              color: const Color(0xFF8B4513),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(method),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() {
                                paymentMethod = value!;
                              }),
                            ),
                          ),
                          if (isCardPayment) ...[
                            _buildTextField(
                              label: "Card Number",
                              keyboardType: TextInputType.number,
                              validator: (value) => isCardPayment &&
                                      (value == null || value.length < 16)
                                  ? 'Enter valid card number'
                                  : null,
                              onSaved: (value) => cardNumber = value ?? '',
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: "Expiry (MM/YY)",
                                    validator: (value) => isCardPayment &&
                                            (value == null || value.isEmpty)
                                        ? 'Enter expiry date'
                                        : null,
                                    onSaved: (value) =>
                                        expiryDate = value ?? '',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    label: "CVV",
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    validator: (value) => isCardPayment &&
                                            (value == null || value.length < 3)
                                        ? 'Enter valid CVV'
                                        : null,
                                    onSaved: (value) => cvv = value ?? '',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button Section
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF8B4513),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${widget.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8B4513),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isPlacing ? null : _placeOrder,
                      child: Text(
                        _isPlacing ? "Placing..." : "Place Order",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
