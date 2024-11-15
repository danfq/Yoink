import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:yoink/util/data/local.dart';
import 'package:yoink/util/handlers/anim.dart';

class Intro extends StatelessWidget {
  Intro({super.key});

  //Pages
  final _pages = [
    //Welcome
    PageViewModel(
      image: AnimHandler.asset(animation: "hello"),
      title: "Welcome to Yoink!",
      body: "Your one-stop App for downloading YouTube Videos & Playlists!",
    ),

    //Manage Playlists
    PageViewModel(
      image: AnimHandler.asset(animation: "list"),
      title: "Create Playlists",
      body: "Create Playlists and download them, in any order.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          pages: _pages,
          showNextButton: true,
          showBackButton: true,
          showDoneButton: true,
          showSkipButton: false,
          next: const Text("Next"),
          back: const Text("Back"),
          done: const Text(
            "Done",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onDone: () async {
            //Set Intro as Done
            await LocalData.updateValue(
              box: "intro",
              item: "status",
              value: true,
            );

            //Go Home
            Get.offAndToNamed("/");
          },
        ),
      ),
    );
  }
}
