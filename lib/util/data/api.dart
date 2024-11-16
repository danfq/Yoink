import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/pages/download/download.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yoink/util/handlers/toast.dart'; // Make sure this import is correct
import 'package:yoink/util/models/video.dart'; // Make sure this import is correct
import 'package:archive/archive.dart'; // Add this import
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart'; // Add FFmpeg import

class API {
  // YouTube Client
  static final yt.YoutubeExplode _youtube = yt.YoutubeExplode();

  /// Search by Query
  static Future<List<Video>> searchByQuery({required String query}) async {
    List<Video> videos = [];
    try {
      // Search videos by query
      final videoSearchList = await _youtube.search.search(query);

      // Process search results
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

      // Show result count
      Toast.show(
          title: "Search Results", message: "${videos.length} videos found");
    } catch (e) {
      Toast.show(title: "Error", message: "Error searching: $e");
    }
    return videos;
  }

  // Download Video and Audio
  static Future<File?> downloadVideo({
    required String videoID,
    required bool audioOnly,
  }) async {
    try {
      var ytExplode = yt.YoutubeExplode();
      var video = await ytExplode.videos.get(videoID);

      // Get the manifest for video and audio streams
      var manifest = await ytExplode.videos.streamsClient.getManifest(
        video.id.value,
      );

      // Choose the audio or video stream based on the 'audioOnly' parameter
      //TODO: Fix Quality
      var videoStream = manifest.video.first;
      var audioStreamInfo = manifest.audioOnly.first;

      // Create temporary files for video and audio
      final tempDir = await getTemporaryDirectory();
      final videoFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_video.mp4');
      final audioFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_audio.m4a');

      // If audioOnly is true, only download the audio stream
      if (audioOnly) {
        var audioStreamClient =
            ytExplode.videos.streamsClient.get(audioStreamInfo);

        // Save audio to the created file
        var audioSink = audioFile.openWrite();
        await audioStreamClient.pipe(audioSink);
        await audioSink.close();

        // Return the audio file
        return audioFile;
      } else {
        // If audioOnly is false, download both video and audio streams
        var videoStreamClient = ytExplode.videos.streamsClient.get(videoStream);
        var audioStreamClient =
            ytExplode.videos.streamsClient.get(audioStreamInfo);

        // Save video and audio to the created files
        var videoSink = videoFile.openWrite();
        await videoStreamClient.pipe(videoSink);
        await videoSink.close();

        var audioSink = audioFile.openWrite();
        await audioStreamClient.pipe(audioSink);
        await audioSink.close();

        // Combine video and audio (using FFmpeg for proper merging)
        final outputFile = File(
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_output.mp4');
        await _combineVideoAndAudio(videoFile, audioFile, outputFile);

        // Optionally, move the file to a permanent location if necessary
        // For now, it's in the temporary directory

        // Show success
        Toast.show(title: "Success", message: "Download complete!");

        // Clean up temporary files
        await videoFile.delete();
        await audioFile.delete();

        // Return the final combined file
        return outputFile;
      }
    } catch (e) {
      // Show error message if something goes wrong
      Toast.show(title: "Error", message: "Error: $e");
      return null;
    }
  }

  // Combine Video and Audio into a single file using FFmpeg
  static Future<void> _combineVideoAndAudio(
      File videoFile, File audioFile, File outputFile) async {
    try {
      // Get file paths
      final videoPath = videoFile.path;
      final audioPath = audioFile.path;
      final outputPath = outputFile.path;

      // Check if the video and audio files exist
      if (!await videoFile.exists()) {
        throw Exception("Video file does not exist: $videoPath");
      }
      if (!await audioFile.exists()) {
        throw Exception("Audio file does not exist: $audioPath");
      }

      // Log FFmpeg command for debugging
      print("Combining video and audio using FFmpeg command:");

      // Command to combine video and audio
      final command =
          "-i $videoPath -i $audioPath -c:v mpeg4 -c:a aac $outputPath";

      // Run the FFmpeg command
      final session = await FFmpegKit.execute(command);

      // Check the execution status
      final returnCode = await session.getReturnCode();

      // Capture FFmpeg logs
      final logs = await session.getAllLogs();
      logs.forEach(
        (log) => print(log.getMessage()),
      ); // Print logs for debugging

      if (returnCode!.isValueSuccess()) {
        print("Video and audio combined successfully");
        Toast.show(
            title: "Success",
            message: "Video and audio combined successfully.");
      } else {
        throw Exception(
          "Error combining video and audio: ${returnCode.getValue()}",
        );
      }
    } catch (e) {
      // Capture any errors and throw exception
      print("Error during combination: $e");
      Toast.show(
        title: "Error",
        message: "Error combining video and audio: $e",
      );
      throw Exception("Error combining video and audio: $e");
    }
  }

  // Zip Files
  static Future<File?> zipFiles({
    required List<File> files,
    required String path,
  }) async {
    try {
      // Create a new archive
      Archive archive = Archive();

      // Add each file to the archive
      for (var file in files) {
        // Get the file name and add it to the archive
        final fileName = file.uri.pathSegments.last;
        final fileBytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(fileName, fileBytes.length, fileBytes));
      }

      // Create the zip file path using the provided `path`
      final zipFile = File(path);

      // Write the archive to the zip file
      final zipBytes = ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(zipBytes!);

      // Return the zip file
      return zipFile;
    } catch (e) {
      debugPrint("Error Creating ZIP: $e");
      Toast.show(title: "Error", message: "Error zipping files: $e");
      return null;
    }
  }

  // Download Playlist (if needed)
  static Future<void> downloadPlaylist({
    required List<Video> playlist,
    required bool audioOnly,
  }) async {
    // Request storage permission for Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        Toast.show(
            title: "Permission Denied",
            message: "Storage Permission is Required");
        return;
      }
    }

    // Show folder picker to the user
    String? dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null || dirPath.isEmpty) {
      Toast.show(title: "Oops!", message: "You Must Choose a Directory");
      return;
    }

    //Go to DownloadPlaylist
    Get.offAll(
      () => DownloadPlaylist(
        playlist: playlist,
        savePath: dirPath,
        audioOnly: audioOnly,
      ),
    );
  }
}
