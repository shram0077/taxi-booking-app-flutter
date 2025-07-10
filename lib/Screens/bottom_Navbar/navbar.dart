import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/GiftPage/giftPage.dart';
import 'package:taxi/Screens/Home/home.dart';
import 'package:taxi/Screens/Profile/profile.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  late final List<Widget> _pages;

  final List<IconData> _listOfIcons = [
    CupertinoIcons.home,
    CupertinoIcons.gift,
    CupertinoIcons.person,
  ];

  @override
  void initState() {
    super.initState();
    final String currentUserId = _auth.currentUser?.uid ?? '';

    _pages = [
      HomePage(currentUserId: currentUserId),
      FavoriteScreen(currentUserId: currentUserId),
      ProfilePage(
        currentUserId: currentUserId,
        visitedUserId: currentUserId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: size.width * .155,
        decoration: BoxDecoration(
          color: greenColor2,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_listOfIcons.length, (index) {
            return InkWell(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(
                      bottom: index == _currentIndex ? 0 : size.width * .029,
                    ),
                    width: size.width * .128,
                    height: index == _currentIndex ? size.width * .014 : 0,
                    decoration: BoxDecoration(
                      color: greenColor,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      _listOfIcons[index],
                      key: ValueKey<int>(
                          _currentIndex), // Ensures the widget is seen as new
                      size: size.width * .075,
                      color:
                          index == _currentIndex ? whiteColor : Colors.white54,
                    ),
                  ),
                  SizedBox(height: size.width * .03),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
