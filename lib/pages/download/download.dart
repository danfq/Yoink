import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:toastification/toastification.dart';
import 'package:yoink/pages/yoink.dart';
import 'package:yoink/util/data/api.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/main.dart';

class DownloadPlaylist extends StatefulWidget {
  const DownloadPlaylist({
    super.key,
    required this.playlist,
    required this.savePath,
    required this.audioOnly,
  });

  final List<Video> playlist;
  final String savePath;
  final bool audioOnly;

  @override
  State<DownloadPlaylist> createState() => _DownloadPlaylistState();
}

class _DownloadPlaylistState extends State<DownloadPlaylist> {
  // Progress variables
  bool isWorking = false;
  bool isComplete = false;
  String currentTask = "Idle";
  int progress = 0;

  /// Total videos
  int totalVideos = 0;

  @override
  void initState() {
    super.initState();
    totalVideos = widget.playlist.length;
  }

  /// Start the download process
  Future<void> _startDownload() async {
    setState(() {
      isWorking = true;
      currentTask = "Initializing...";
    });

    final List<File> downloadedFiles = [];
    try {
      // Step 1: Download Videos
      await _performTask("Downloading Videos", widget.playlist.length,
          (index) async {
        final video = widget.playlist[index];
        final File file =
            await _downloadVideo(video, "${index + 1} - ${video.title}");
        downloadedFiles.add(file);
      });

      // Step 2: Rename Files
      await _performTask("Renaming Videos", downloadedFiles.length,
          (index) async {
        final renamedFile = await _renameFile(
          downloadedFiles[index],
          "${index + 1} - ${widget.playlist[index].title}",
        );
        downloadedFiles[index] = renamedFile;
      });

      // Step 3: ZIP Videos
      await _zipVideos(downloadedFiles);

      // Mark as complete
      setState(() {
        isWorking = false;
        isComplete = true;
      });
      _showToast("Success", "Download Complete!");
    } catch (e) {
      setState(() {
        isWorking = false;
        currentTask = "Idle";
      });
      _showToast("Error", e.toString());
    }
  }

  /// Perform a specific task
  Future<void> _performTask(
      String taskName, int total, Future<void> Function(int) task) async {
    setState(() {
      currentTask = taskName;
      progress = 0;
    });

    for (int i = 0; i < total; i++) {
      await task(i);
      setState(() {
        progress = i + 1;
      });
    }
  }

  /// Download video
  Future<File> _downloadVideo(Video video, String fileName) async {
    final File? file = await API.downloadVideo(
      videoID: video.id,
      audioOnly: widget.audioOnly,
    );

    if (file == null) {
      throw Exception("Failed to download video: ${video.title}");
    }

    final extension = widget.audioOnly ? "mp3" : "mp4";
    final filePath = "${widget.savePath}/$fileName.$extension";
    return file.copy(filePath);
  }

  /// Rename a file (offloaded to Isolate)
  Future<File> _renameFile(File file, String newName) async {
    final String newPath =
        "${widget.savePath}/$newName.${widget.audioOnly ? "mp3" : "mp4"}";

    // Offload renaming to an isolate
    final renamedFile = await compute(_renameFileIsolate, [file.path, newPath]);
    return File(renamedFile);
  }

  static String _renameFileIsolate(List<String> args) {
    final File file = File(args[0]);
    final String newPath = args[1];
    return file.renameSync(newPath).path;
  }

  /// ZIP videos using an isolate
  Future<void> _zipVideos(List<File> files) async {
    setState(() {
      currentTask = "Zipping Files";
      progress = 0;
    });

    final zipPath =
        "${widget.savePath}/playlist_${DateTime.now().millisecondsSinceEpoch}.zip";

    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(
      _zipFilesInIsolate,
      [files.map((e) => e.path).toList(), zipPath, receivePort.sendPort],
    );

    // Wait for completion
    final result = await receivePort.first;
    if (result is String && result == "success") {
      for (final file in files) {
        await file.delete();
      }
    } else {
      throw Exception("Failed to zip files.");
    }
  }

  static void _zipFilesInIsolate(List<dynamic> args) {
    final List<String> filePaths = args[0];
    final String zipPath = args[1];
    final SendPort sendPort = args[2];

    try {
      final archive = Archive();
      for (final filePath in filePaths) {
        final file = File(filePath);
        final fileBytes = file.readAsBytesSync();
        archive.addFile(ArchiveFile(
          file.path.split('/').last,
          fileBytes.length,
          fileBytes,
        ));
      }

      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes!);

      sendPort.send("success");
    } catch (e) {
      sendPort.send(e.toString());
    }
  }

  /// Show toast
  void _showToast(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Toast.show(
        title: title,
        message: message,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: const Text("Download Playlist"),
        allowBack: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isWorking && !isComplete)
              Center(
                child: Buttons.elevatedIcon(
                  text: "Start Download",
                  icon: Ionicons.ios_download_outline,
                  onTap: _startDownload,
                ),
              ),
            if (isWorking)
              Column(
                children: [
                  Text(currentTask),
                  LinearProgressIndicator(
                    value: progress / totalVideos,
                  ),
                  Text("$progress / $totalVideos"),
                ],
              ),
            if (isComplete)
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Ionicons.ios_checkmark_circle,
                      color: Colors.green,
                      size: 64.0,
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      "Download Complete!",
                      style: TextStyle(fontSize: 18.0, color: Colors.green),
                    ),
                    const SizedBox(height: 20.0),
                    Buttons.elevatedIcon(
                      text: "Go Home",
                      icon: Ionicons.ios_home_outline,
                      onTap: () => Get.offAll(() => const Yoink()),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
