import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:yoink/util/data/local.dart';
import 'package:window_size/window_size.dart';

///Main Handler
class MainHandler {
  ///Initialize Services
  ///
  ///- Widgets Binding.
  ///- LocalData (Hive).
  static Future<void> init() async {
    //Widgets Binding
    WidgetsFlutterBinding.ensureInitialized();

    //Change Window Title for Desktop
    if (!Platform.isAndroid && !Platform.isIOS) {
      setWindowTitle("Yoink");
    }

    //Local Data
    await LocalData.init();
  }

  ///Initial Route
  static String initialRoute() {
    //Intro Status
    final bool introStatus = LocalData.boxData(box: "intro")["status"] ?? false;

    //Return Route Based on Intro Status
    return introStatus ? "/" : "/intro";
  }
}
