import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedMethod;

  final List<Map<String, String>> _methods = [
    {
      "name": "Mastercard",
      "icon": "assets/icons/mastercard.png",
    },
    {
      "name": "FastPay",
      "icon": "assets/icons/fastpay.png",
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Deposit",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Amount Section ---
            Text(
              "Enter Amount",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "e.g. 10,000 IQD",
                prefixIcon: const Icon(Icons.monetization_on_outlined,
                    color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.green.shade400, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- Payment Method Section ---
            Text(
              "Choose Payment Method",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            ..._methods.map((method) => _buildPaymentOption(method)),
            const SizedBox(height: 40),

            // --- Deposit Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMethod == null
                    ? null
                    : () {
                        // UI-only placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green.shade600,
                            content: Text(
                              "Proceeding with $_selectedMethod",
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.green.withOpacity(0.4),
                ),
                child: Text(
                  "Deposit Now",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                .animate(target: _selectedMethod == null ? 0 : 1)
                .fade()
                .scaleXY(begin: 0.9, end: 1.0),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildPaymentOption(Map<String, String> method) {
    final isSelected = _selectedMethod == method["name"];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethod = method["name"];
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Image.asset(method["icon"]!, width: 40, height: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  method["name"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green, size: 26)
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOutBack)
              else
                const Icon(Icons.circle_outlined, color: Colors.grey, size: 26),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, duration: 500.ms),
    );
  }
}
