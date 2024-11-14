import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:yoink/util/themes/controller.dart';
import 'package:yoink/util/widgets/main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ///Current Theme
  bool _currentTheme = ThemeController.current(context: Get.context!);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Status Bar & Navigation Bar
    ThemeController.statusAndNavSettings(mode: _currentTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Settings")),
      body: SafeArea(
        child: SettingsList(
          lightTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          darkTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          physics: const BouncingScrollPhysics(),
          sections: [
            //UI
            SettingsSection(
              title: const Text("UI & Visuals"),
              tiles: [
                SettingsTile.switchTile(
                  leading: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Icon(
                      _currentTheme ? Ionicons.ios_moon : Ionicons.ios_sunny,
                    ),
                  ),
                  title: const Text("Theme Mode"),
                  initialValue: _currentTheme,
                  onToggle: (mode) {
                    //Set New Theme
                    ThemeController.setAppearance(
                      context: context,
                      mode: mode,
                    );

                    //Status & Nav
                    ThemeController.statusAndNavSettings(mode: mode);

                    //Update Theme
                    setState(() {
                      _currentTheme = mode;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
