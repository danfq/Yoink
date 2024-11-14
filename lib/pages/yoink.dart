import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:yoink/util/widgets/main.dart';

class Yoink extends StatefulWidget {
  const Yoink({super.key});

  @override
  State<Yoink> createState() => _YoinkState();
}

class _YoinkState extends State<Yoink> {
  ///Drawer Controller
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      controller: _drawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueGrey, Colors.blueGrey.withOpacity(0.2)],
          ),
        ),
      ),
      drawer: SafeArea(
        child: Column(
          children: [
            //Header
            Center(
              child: Image.asset("assets/img/logo.png", height: 120.0),
            ),

            //Find Videos
            MainWidgets.menuItem(
              icon: Ionicons.ios_search_outline,
              title: "Find Videos",
              onTap: () {},
            ),

            //Downloads
            MainWidgets.menuItem(
              icon: Ionicons.ios_list_outline,
              title: "Downloads",
              onTap: () {},
            ),

            //Spacer
            const Spacer(),

            //Footer
          ],
        ),
      ),
      child: Placeholder(),
    );
  }
}
