import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:toastification/toastification.dart';
import 'package:yoink/pages/intro/intro.dart';
import 'package:yoink/pages/settings/settings.dart';
import 'package:yoink/pages/yoink.dart';
import 'package:yoink/pages/youtube/playlists.dart';
import 'package:yoink/util/handlers/main.dart';
import 'package:yoink/util/themes/themes.dart';

void main() async {
  //Initialize Services
  await MainHandler.init();

  //Initial Route
  final initialRoute = MainHandler.initialRoute();

  //Run App
  runApp(
    ToastificationWrapper(
      child: AdaptiveTheme(
        light: Themes.light,
        dark: Themes.dark,
        initial: AdaptiveThemeMode.system,
        builder: (light, dark) {
          return GetMaterialApp(
            theme: light,
            darkTheme: dark,
            initialRoute: initialRoute,
            getPages: [
              GetPage(name: "/", page: () => const Yoink()),
              GetPage(name: "/intro", page: () => Intro()),
              GetPage(name: "/settings", page: () => const Settings()),
              GetPage(name: "/playlists", page: () => const Playlists()),
            ],
          );
        },
      ),
    ),
  );
}
