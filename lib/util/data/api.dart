import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/pages/download/download.dart';
import 'package:yoink/pages/download/verify.dart';
import 'package:yoink/util/data/local.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/input.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/models/playlist.dart' as pl;
import 'package:hive/hive.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

///API
class API {
  ///YouTube Explode Client
  static final yt.YoutubeExplode _youtube = yt.YoutubeExplode();

  ///Search by Query
  static Future<List<Video>> searchByQuery({required String query}) async {
    //Videos
    List<Video> videos = [];

    //Attempt to Get Videos by Query
    try {
      //Video Search List
      final videoSearchList = await _youtube.search.search(query);

      //Parse Videos
      for (final videoItem in videoSearchList) {
        final video = Video(
          id: videoItem.id.value,
          title: videoItem.title,
          thumb: videoItem.thumbnails.highResUrl,
          channel: videoItem.author,
          duration: videoItem.duration ?? Duration.zero,
          releaseDate: videoItem.uploadDate,
        );

        if (video.duration != Duration.zero) {
          videos.add(video);
        }
      }
    } catch (error) {
      //Debug
      debugPrint(error.toString());

      Toast.show(title: "Error", message: "Error Searching: $error");
    }
    return videos;
  }

  /// Save Playlist Metadata
  static Future<void> savePlaylist({required pl.Playlist playlist}) async {
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
  static Future<void> deletePlaylist({required String id}) async {
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

  ///Download Playlist
  static Future<void> downloadPlaylist({
    required List<Video> videos,
    required bool audioOnly,
  }) async {
    try {
      // Request Save Location
      final location = await pickDownloadDirectory();

      if (location == null) {
        Toast.show(
          title: "Error",
          message: "No directory selected. Download canceled.",
        );
        return;
      }

      // Navigate to Download Page Before Starting
      Get.to(
        DownloadPlaylist(
          playlist: videos,
          audioOnly: audioOnly,
          savePath: location,
        ),
      );
    } catch (error) {
      Toast.show(title: "Error", message: "Error preparing download: $error");
    }
  }

  ///Import Playlist
  static Future<void> importPlaylist() async {
    try {
      // Show Dialog for URL Input
      final urlController = TextEditingController();

      //Get URL
      final String? playlistUrl = await Get.defaultDialog(
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

      // Check if URL was provided
      if (playlistUrl == null || playlistUrl.isEmpty) {
        return;
      }

      // Show loading indicator
      Get.defaultDialog(
        title: "Getting Information...",
        content: const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Get playlist
      final playlist = await _youtube.playlists.get(playlistUrl);

      // Get all videos
      final videos = await _youtube.playlists
          .getVideos(playlist.id)
          .map((video) => Video(
                id: video.id.value,
                title: video.title,
                thumb: video.thumbnails.highResUrl,
                channel: video.author,
                duration: video.duration ?? Duration.zero,
                releaseDate: video.uploadDate ?? DateTime.now(),
              ))
          .toList();

      // Close loading dialog
      Get.back();

      // Navigate to verify screen
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

  /// Download Video and Audio
  static Future<File?> downloadVideo({
    required String videoID,
    required bool audioOnly,
  }) async {
    try {
      var ytExplode = yt.YoutubeExplode();
      var video = await ytExplode.videos.get(videoID);
      var manifest = await ytExplode.videos.streamsClient.getManifest(
        video.id.value,
      );

      //Get Default Video & Audio Qualities
      final defaultVideoQuality =
          LocalData.boxData(box: "settings")["defaultVideoQuality"];
      final defaultAudioQuality =
          LocalData.boxData(box: "settings")["defaultAudioQuality"];

      //Streams
      var videoStream = defaultVideoQuality == "Highest Bitrate"
          ? manifest.video.withHighestBitrate()
          : manifest.video.first;
      var audioStreamInfo = defaultAudioQuality == "Highest Bitrate"
          ? manifest.audioOnly.withHighestBitrate()
          : manifest.audioOnly.first;

      final tempDir = await getTemporaryDirectory();
      final audioFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_audio.m4a');
      final videoFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_video.mp4');

      // Download audio first
      final audioStreamClient =
          ytExplode.videos.streamsClient.get(audioStreamInfo);
      final audioSink = audioFile.openWrite();
      await audioStreamClient.pipe(audioSink);
      await audioSink.close();

      if (!audioFile.existsSync()) {
        throw Exception(
          "Audio download failed or file not found: ${audioFile.path}",
        );
      }

      // If audio-only, return here
      if (audioOnly) {
        return audioFile;
      }

      // Download video
      if (videoStream.url.toString().endsWith(".m3u8")) {
        Toast.show(
          title: "Processing HLS Stream",
          message: "This may take a while...",
        );

        final hlsVideoFile =
            await _downloadHLSStream(videoStream.url, videoFile);
        return await _combineVideoAndAudio(hlsVideoFile, audioFile, tempDir);
      }

      final videoStreamClient = ytExplode.videos.streamsClient.get(videoStream);
      final videoSink = videoFile.openWrite();
      await videoStreamClient.pipe(videoSink);
      await videoSink.close();

      if (!videoFile.existsSync()) {
        throw Exception(
            "Video download failed or file not found: ${videoFile.path}");
      }

      // Combine video and audio
      return await _combineVideoAndAudio(videoFile, audioFile, tempDir);
    } catch (e) {
      Toast.show(title: "Error", message: "Error: $e");
      return null;
    }
  }

  ///Download HLS Stream
  static Future<File> _downloadHLSStream(Uri hlsUrl, File outputFile) async {
    final tempDir = await getTemporaryDirectory();
    final tsDir = Directory('${tempDir.path}/hls_segments');
    await tsDir.create();

    final command = "-i ${hlsUrl.toString()} -c copy ${outputFile.path}";
    final session = await FFmpegKit.execute(command);

    final returnCode = await session.getReturnCode();
    if (returnCode!.isValueSuccess()) {
      return outputFile;
    } else {
      throw Exception("Error processing HLS stream: $hlsUrl");
    }
  }

  ///Combine Video & Audio
  static Future<File> _combineVideoAndAudio(
      File videoFile, File audioFile, Directory tempDir) async {
    try {
      if (!videoFile.existsSync()) {
        throw Exception("Video file does not exist at ${videoFile.path}");
      }
      if (!audioFile.existsSync()) {
        throw Exception("Audio file does not exist at ${audioFile.path}");
      }

      final outputFile = File(
          "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_output.mp4");

      final command =
          "-i ${videoFile.path} -i ${audioFile.path} -c:v copy -c:a aac ${outputFile.path}";
      final session = await FFmpegKit.execute(command);

      final returnCode = await session.getReturnCode();
      if (returnCode!.isValueSuccess()) {
        return outputFile;
      } else {
        throw Exception("FFmpeg failed with code: $returnCode");
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Error during video/audio combination: $e");
    }
  }

  ///Pick Download Directory
  static Future<String?> pickDownloadDirectory() async {
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

      // Default to downloads directory for web, app documents for mobile
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

    // Desktop or Web - Use File Picker
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();

    //Return Selected Directory
    return selectedDirectory;
  }

  ///Remove Playlist
  static Future<void> removePlaylist({required String id}) async {
    await deletePlaylist(id: id);
  }
}
