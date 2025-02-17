import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yoink/pages/download/download.dart';
import 'package:yoink/pages/download/verify.dart';
import 'package:yoink/util/data/local.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:yoink/util/models/playlist.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/input.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

///Playlist Handler
class PlaylistHandler {
  ///YouTube Explode Client
  static final yt.YoutubeExplode _youtube = yt.YoutubeExplode();

  ///Get Playlist by URL
  static Future<yt.Playlist> get({required String playlistURL}) async {
    return await _youtube.playlists.get(playlistURL);
  }

  ///Download Playlist
  static Future<void> download({
    required List<Video> videos,
    required bool audioOnly,
  }) async {
    try {
      //Request Save Location
      final location = await _pickDownloadDirectory();

      //Check Location
      if (location == null) {
        //Notify User
        Toast.show(
          title: "Error",
          message: "No Directory Selected. Download Canceled.",
        );

        //Cancel
        return;
      }

      //Navigate to Download Page Before Starting
      Get.to(
        () => DownloadPlaylist(
          playlist: videos,
          audioOnly: audioOnly,
          savePath: location,
        ),
      );
    } catch (error) {
      Toast.show(title: "Error", message: "Error preparing download: $error");
    }
  }

  /// Save Playlist
  static Future<void> save({required Playlist playlist}) async {
    //Save Playlist
    await LocalData.updateValue(
      box: "playlists",
      item: playlist.id,
      value: playlist.toJSON(),
    );

    //Notify User
    Toast.show(title: "Done!", message: "Playlist Saved Successfully!");
  }

  ///Delete Playlist by `id`
  static Future<void> delete({required String id}) async {
    //Get direct box reference
    final playlists = Hive.box("playlists");

    //Check if Playlist Exists
    if (playlists.containsKey(id)) {
      //Remove Playlist
      await playlists.delete(id);

      //Notify User
      Toast.show(title: "Done!", message: "Playlist Deleted Successfully!");
    } else {
      //Notify User
      Toast.show(
        title: "Error",
        message: "Playlist with ID \"$id\" not found.",
      );
    }
  }

  ///Import Playlist
  static Future<void> import() async {
    try {
      //URL Controller
      final urlController = TextEditingController();

      //Get URL
      final String? playlistURL = await Get.defaultDialog(
        title: "Import Playlist",
        content: Input(
          controller: urlController,
          backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
          placeholder: "Playlist URL",
        ),
        confirm: Buttons.elevated(
          text: "Import",
          onTap: () => Get.back(result: urlController.text),
        ),
        cancel: Buttons.text(
          text: "Cancel",
          onTap: () => Get.back(),
        ),
      );

      //Check for URL
      if (playlistURL == null || playlistURL.isEmpty) {
        return;
      }

      //Show Loading Indicator
      Get.defaultDialog(
        title: "Getting Information...",
        content: const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      //Get Playlist
      final playlist = await get(playlistURL: playlistURL);

      //Get All Videos
      final videos = await _youtube.playlists.getVideos(playlist.id).map(
        (video) {
          //Debug
          debugPrint(
            "[VIDEOS] ID: ${video.id} | Duration: ${video.duration}",
          );

          //Return Video
          return Video(
            id: video.id.value,
            title: video.title,
            thumb: video.thumbnails.highResUrl,
            channel: video.author,
            duration: video.duration ?? Duration.zero,
            releaseDate: video.uploadDate ?? DateTime.now(),
          );
        },
      ).toList();

      //Debug
      debugPrint("[VIDEOS] Playlist Total Videos: ${videos.length}");

      //Close Loading Dialog
      Get.back();

      //Go to Verify Page
      Get.to(
        () => VerifyPlaylist(
          videos: videos,
          showSave: true,
        ),
      );
    } catch (error) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Toast.show(
        title: "Error",
        message: "Failed to import playlist: $error",
      );
    }
  }

  ///Pick Download Directory
  static Future<String?> _pickDownloadDirectory() async {
    //Android
    if (Platform.isAndroid) {
      // Request Permission
      final permissionStatus = await Permission.manageExternalStorage.request();

      //Check Permission
      if (!permissionStatus.isGranted) {
        Toast.show(
          title: "Permission Denied",
          message: "Storage access is required!",
        );
        return null;
      }

      //Default to "Downloads" Directory for Web
      final directory = kIsWeb
          ? Directory("/downloads")
          : await getApplicationDocumentsDirectory();
      return directory.path;
    }

    //iOS
    if (Platform.isIOS) {
      // Request Permission
      final permissionStatus = await Permission.storage.request();

      //Check Permission
      if (!permissionStatus.isGranted) {
        Toast.show(
          title: "Permission Denied",
          message: "Storage access is required!",
        );
        return null;
      }
    }

    //Desktop or Web - Use File Picker
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();

    //Debug
    debugPrint("[DIR] Selected: $selectedDirectory");

    //Return Selected Directory
    return selectedDirectory;
  }
}
