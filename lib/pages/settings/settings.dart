import "package:flutter/material.dart";
import "package:flutter_vector_icons/flutter_vector_icons.dart";
import "package:settings_ui/settings_ui.dart";
import "package:yoink/util/themes/controller.dart";
import "package:yoink/util/widgets/main.dart";
import "package:get/get.dart";
import "package:hive/hive.dart";
import "package:yoink/util/data/local.dart";

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ///Current Theme
  bool _currentTheme = ThemeController.current(context: Get.context!);

  // Update the RxString declarations
  final RxString _defaultVideoQuality = RxString(
      Hive.box("settings").get("defaultVideoQuality") ?? "Highest Bitrate");
  final RxString _defaultAudioQuality = RxString(
      Hive.box("settings").get("defaultAudioQuality") ?? "Highest Bitrate");

  // Update the quality selector method to save preferences
  void _showQualitySelector({required bool isVideo}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVideo ? "Default Video Quality" : "Default Audio Quality",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Highest Bitrate"),
              trailing: Obx(() => Radio<String>(
                    value: "Highest Bitrate",
                    groupValue: isVideo
                        ? _defaultVideoQuality.value
                        : _defaultAudioQuality.value,
                    onChanged: (value) {
                      if (isVideo) {
                        _defaultVideoQuality.value = value!;
                        LocalData.updateValue(
                          box: "settings",
                          item: "defaultVideoQuality",
                          value: value,
                        );
                      } else {
                        _defaultAudioQuality.value = value!;
                        LocalData.updateValue(
                          box: "settings",
                          item: "defaultAudioQuality",
                          value: value,
                        );
                      }
                      Get.back();
                    },
                  )),
              onTap: () {
                if (isVideo) {
                  _defaultVideoQuality.value = "Highest Bitrate";
                  LocalData.updateValue(
                    box: "settings",
                    item: "defaultVideoQuality",
                    value: "Highest Bitrate",
                  );
                } else {
                  _defaultAudioQuality.value = "Highest Bitrate";
                  LocalData.updateValue(
                    box: "settings",
                    item: "defaultAudioQuality",
                    value: "Highest Bitrate",
                  );
                }
                Get.back();
              },
            ),
            ListTile(
              title: const Text("Fastest"),
              trailing: Obx(() => Radio<String>(
                    value: "Fastest",
                    groupValue: isVideo
                        ? _defaultVideoQuality.value
                        : _defaultAudioQuality.value,
                    onChanged: (value) {
                      if (isVideo) {
                        _defaultVideoQuality.value = value!;
                        LocalData.updateValue(
                          box: "settings",
                          item: "defaultVideoQuality",
                          value: value,
                        );
                      } else {
                        _defaultAudioQuality.value = value!;
                        LocalData.updateValue(
                          box: "settings",
                          item: "defaultAudioQuality",
                          value: value,
                        );
                      }
                      Get.back();
                    },
                  )),
              onTap: () {
                if (isVideo) {
                  _defaultVideoQuality.value = "Fastest";
                  LocalData.updateValue(
                    box: "settings",
                    item: "defaultVideoQuality",
                    value: "Fastest",
                  );
                } else {
                  _defaultAudioQuality.value = "Fastest";
                  LocalData.updateValue(
                    box: "settings",
                    item: "defaultAudioQuality",
                    value: "Fastest",
                  );
                }
                Get.back();
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

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

            //Quality Options
            SettingsSection(
              title: const Text("Quality Options"),
              tiles: [
                //Default Video Quality
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_videocam_outline),
                  title: const Text("Default Video Quality"),
                  value: Obx(() => Text(_defaultVideoQuality.value)),
                  onPressed: (context) => _showQualitySelector(isVideo: true),
                  description: const Text(
                    "If you're worried about Data Usage, you can set this to Fastest.",
                  ),
                ),

                //Default Audio Quality
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_volume_high_outline),
                  title: const Text("Default Audio Quality"),
                  value: Obx(() => Text(_defaultAudioQuality.value)),
                  onPressed: (context) => _showQualitySelector(isVideo: false),
                  description: const Text(
                    "If you're worried about Data Usage, you can set this to Fastest.",
                  ),
                ),
              ],
            ),

            //Team & Licenses
            SettingsSection(
              title: const Text("Team & Licenses"),
              tiles: [
                //Team
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_people_outline),
                  title: const Text("Team"),
                  onPressed: (context) => Get.toNamed("/team"),
                ),

                //Licenses
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_book_outline),
                  title: const Text("Licenses"),
                  onPressed: (context) => Get.to(
                    () => LicensePage(
                      applicationName: "Yoink",
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          "assets/img/logo.png",
                          height: 120.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
