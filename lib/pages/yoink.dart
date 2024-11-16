import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:yoink/pages/youtube/downloads.dart';
import 'package:yoink/pages/youtube/find.dart';
import 'package:yoink/pages/youtube/playlists.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/main.dart';

class Yoink extends StatefulWidget {
  const Yoink({super.key});

  @override
  State<Yoink> createState() => _YoinkState();
}

class _YoinkState extends State<Yoink> {
  ///Drawer Controller
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  ///Nav Index
  int _navIndex = 0;

  ///Body
  Widget _body() {
    switch (_navIndex) {
      //Find Videos
      case 0:
        return const FindVideos();

      //Playlists
      case 1:
        return const Playlists();

      //Downloads
      case 2:
        return const Downloads();

      //Default - None
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      controller: _drawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      drawer: SafeArea(
        child: Column(
          children: [
            //Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Image.asset("assets/img/logo.png", height: 120.0),
              ),
            ),

            //Find Videos
            MainWidgets.menuItem(
              icon: Ionicons.ios_search_outline,
              title: "Find Videos",
              onTap: () {
                setState(() {
                  _navIndex = 0;
                });
              },
            ),

            //Playlists
            MainWidgets.menuItem(
              icon: Ionicons.ios_list_outline,
              title: "Playlists",
              onTap: () {
                setState(() {
                  _navIndex = 1;
                });
              },
            ),

            //Downloads
            MainWidgets.menuItem(
              icon: Ionicons.ios_download_outline,
              title: "Downloads",
              onTap: () {
                setState(() {
                  _navIndex = 2;
                });
              },
            ),

            //Spacer
            const Spacer(),

            //Footer
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("DanFQ © ${DateTime.now().year}"),
            ),
          ],
        ),
      ),
      child: Scaffold(
        appBar: MainWidgets.appBar(
          allowBack: false,
          leading: Buttons.icon(
            icon: Ionicons.ios_menu_outline,
            onTap: () {
              _drawerController.showDrawer();
            },
          ),
          title: const Text("Yoink"),
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }
}
