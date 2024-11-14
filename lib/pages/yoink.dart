import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/pages/settings/settings.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/main.dart';

class Yoink extends StatefulWidget {
  const Yoink({super.key});

  @override
  State<Yoink> createState() => _YoinkState();
}

class _YoinkState extends State<Yoink> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        allowBack: false,
        centerTitle: false,
        title: const Text("Yoink"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Buttons.icon(
              icon: Ionicons.ios_settings_outline,
              onTap: () => Get.toNamed("/settings"),
            ),
          ),
        ],
      ),
    );
  }
}
