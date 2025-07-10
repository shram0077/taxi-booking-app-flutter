import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Utils/Loadings/AppBar_loading.dart';

class HomeAppBar extends StatefulWidget {
  final String currentUserId;
  const HomeAppBar({
    super.key,
    required this.currentUserId,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: usersRef.doc(widget.currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return loadingAppBarContainer();
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 85,
            child: Center(
              child: Text(
                'Snapshot Error',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }

        // Trigger fade in animation on data load
        _fadeController.forward();

        final userModel = UserModel.fromDoc(snapshot.data!);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: AppBar(
            backgroundColor: primaryColor,
            elevation: 4,
            shadowColor: Colors.black45,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 85,
            titleSpacing: 16,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hi, ${userModel.name}",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userModel.role == 'driver'
                            ? "Find your ride and start earning!"
                            : "Let's get started! Find your ride.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // TODO: Add notification functionality here
                  },
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  tooltip: 'Notifications',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
