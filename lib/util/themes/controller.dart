import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

///Theme Controller
class ThemeController {
  ///Current Theme
  static bool current({required BuildContext context}) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  ///Set Appearance Mode
  static void setAppearance({
    required BuildContext context,
    required bool mode,
  }) {
    mode ? setDark(context: context) : setLight(context: context);
  }

  ///Set Dark Mode
  static void setDark({
    required BuildContext context,
  }) {
    AdaptiveTheme.of(context).setDark();

    statusAndNav(mode: current(context: Get.context!));
  }

  ///Set Light Mode
  static void setLight({
    required BuildContext context,
  }) {
    AdaptiveTheme.of(context).setLight();

    statusAndNav(mode: current(context: Get.context!));
  }

  ///Easy Toggle Mode
  static void easyToggle({
    required BuildContext context,
  }) {
    AdaptiveTheme.of(context).toggleThemeMode();
  }

  ///Status Bar & Navigation Bar
  static void statusAndNav({required bool mode}) {
    if (!mode) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFFFEF7FF),
          statusBarColor: Color(0xFFFFFEFD),
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFF141218),
          statusBarColor: Color(0xFF131313),
        ),
      );
    }
  }

  ///Status Bar & Navigation Bar (Settings)
  static void statusAndNavSettings({required bool mode}) {
    if (!mode) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFFFAFAFA),
          statusBarColor: Color(0xFFFFFEFD),
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFF24242C),
          statusBarColor: Color(0xFF131313),
        ),
      );
    }
  }
}
