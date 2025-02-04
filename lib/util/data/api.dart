import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yoink/util/data/local.dart';
import 'package:yoink/util/handlers/ffmpeg.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:path_provider/path_provider.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:yoink/util/models/video.dart';

/// API
class API {
  /// YouTube Explode Client
  static final yt.YoutubeExplode _youtube = yt.YoutubeExplode();

  /// Search by Query
  static Future<List<Video>> searchByQuery({required String query}) async {
    List<Video> videos = [];

    try {
      final videoSearchList = await _youtube.search.search(query);

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
      debugPrint(error.toString());
      Toast.show(title: "Error", message: "Error Searching: $error");
    }
    return videos;
  }

  /// Download Video and Audio
  static Future<File?> downloadVideo({
    required String videoID,
    required bool audioOnly,
  }) async {
    try {
      var ytExplode = yt.YoutubeExplode();
      var video = await ytExplode.videos.get(videoID);
      var manifest =
          await ytExplode.videos.streamsClient.getManifest(video.id.value);

      final defaultVideoQuality =
          LocalData.boxData(box: "settings")["defaultVideoQuality"];
      final defaultAudioQuality =
          LocalData.boxData(box: "settings")["defaultAudioQuality"];

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
            "Audio download failed or file not found: ${audioFile.path}");
      }

      // If audio-only, return here
      if (audioOnly) {
        return audioFile;
      }

      // Download video
      if (videoStream.url.toString().endsWith(".m3u8")) {
        Toast.show(
            title: "Processing HLS Stream",
            message: "This may take a while...");

        // HLS Video File
        final hlsVideoFile =
            await _downloadHLSStream(videoStream.url, videoFile);

        // Combine Video & Audio using FFmpegHandler
        return await FFmpegHandler.combineVideoAndAudio(
          videoFile: hlsVideoFile,
          audioFile: audioFile,
          tempDir: tempDir,
        );
      }

      final videoStreamClient = ytExplode.videos.streamsClient.get(videoStream);
      final videoSink = videoFile.openWrite();
      await videoStreamClient.pipe(videoSink);
      await videoSink.close();

      if (!videoFile.existsSync()) {
        throw Exception(
            "Video download failed or file not found: ${videoFile.path}");
      }

      // Combine video and audio using FFmpegHandler
      return await FFmpegHandler.combineVideoAndAudio(
        videoFile: videoFile,
        audioFile: audioFile,
        tempDir: tempDir,
      );
    } catch (e) {
      Toast.show(title: "Error", message: "Error: $e");
      return null;
    }
  }

  /// Download HLS Stream
  static Future<File> _downloadHLSStream(Uri hlsUrl, File outputFile) async {
    // Windows Only
    if (Platform.isWindows) {
      return await FFmpegHandler.downloadVideoWithAudio(
          hlsUrl.toString(), outputFile.path);
    }

    // Temporary Directory
    final tempDir = await getTemporaryDirectory();
    final tsDir = Directory("${tempDir.path}/hls_segments");
    await tsDir.create();

    // FFmpeg Command & Session
    final command = "-i ${hlsUrl.toString()} -c copy ${outputFile.path}";
    final session = await FFmpegKit.execute(command);

    final returnCode = await session.getReturnCode();
    if (returnCode!.isValueSuccess()) {
      return outputFile;
    } else {
      throw Exception("Error processing HLS stream: $hlsUrl");
    }
  }
}
