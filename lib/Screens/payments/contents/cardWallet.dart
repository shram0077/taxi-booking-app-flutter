import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/payments/deposit.dart';
import 'package:taxi/Screens/payments/withdrawal.dart';
import 'package:taxi/Utils/Loadings/Cardwallet_loading.dart';
import 'package:taxi/Utils/texts.dart';

class WalletCard extends StatefulWidget {
  final bool isLoading;
  final UserModel userModel;

  const WalletCard({
    super.key,
    required this.isLoading,
    required this.userModel,
  });

  @override
  _WalletCardState createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadBalanceVisibility();
  }

  Future<void> _loadBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isBalanceVisible = prefs.getBool('isBalanceVisible') ?? true;
      });
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
      prefs.setBool('isBalanceVisible', _isBalanceVisible);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return buildLoadingCard();
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: primaryColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Constrain column size to its children
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildBalance(),
            const SizedBox(height: 25),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        robotoText("Balance", Colors.white, 22, FontWeight.bold),
        IconButton(
          onPressed: _toggleBalanceVisibility,
          icon: Icon(
            _isBalanceVisible ? EvaIcons.eyeOffOutline : EvaIcons.eyeOutline,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBalance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(EvaIcons.creditCardOutline, color: Colors.white, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            // The key is now on a Container that wraps the robotoText widget
            child: Container(
              key: ValueKey<bool>(
                  _isBalanceVisible), // Apply key to a widget that accepts it
              child: robotoText(
                _isBalanceVisible
                    ? "•••••"
                    : "${widget.userModel.walletBalance} IQD",
                Colors.white,
                26,
                FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _buildActionButton(
            icon: Icons.history,
            label: "Transactions",
            onTap: () {
              // Handle transactions tap
            },
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallActionButton(
              imagePath: "assets/images/Card_Payment.png",
              label: "Withdraw",
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    child: WithdrawalPage(),
                  ),
                );
              },
            ),
            SizedBox(width: 10),
            _buildSmallActionButton(
              imagePath: "assets/images/deposit.png",
              label: "Deposit",
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    child: DepositPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: robotoText(label, Colors.white, 14, FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton(
      {required String imagePath,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5),
          robotoText(label, Colors.white, 13, FontWeight.w800),
        ],
      ),
    );
  }
}
