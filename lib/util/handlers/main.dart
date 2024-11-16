import 'package:flutter/widgets.dart';
import 'package:yoink/util/data/local.dart';

///Main Handler
class MainHandler {
  ///Initialize Services
  ///
  ///- Widgets Binding.
  ///- LocalData (Hive).
  static Future<void> init() async {
    //Widgets Binding
    WidgetsFlutterBinding.ensureInitialized();

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
