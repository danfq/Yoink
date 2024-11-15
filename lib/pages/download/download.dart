import 'dart:io';
import 'dart:async';
import 'dart:isolate'; // Import for Isolate
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/pages/yoink.dart';
import 'package:yoink/util/data/api.dart';
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
  bool isDownloading = false;
  bool isRenaming = false;
  bool isZipping = false;
  bool isComplete = false;
  bool hasError = false;
  int downloadProgress = 0;
  int totalVideos = 0;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();
    totalVideos = widget.playlist.length;
  }

  Future<void> _downloadVideo(Video video, String fileName) async {
    int attempts = 0;
    bool success = false;
    while (attempts < 2 && !success) {
      try {
        final File? file = await API.downloadVideo(
          videoID: video.id,
          audioOnly: widget.audioOnly,
        );
        if (file != null) {
          final fileExtension = widget.audioOnly ? "mp3" : "mp4";
          final filePath = "${widget.savePath}/$fileName.$fileExtension";
          await file.copy(filePath);
          success = true;
        }
      } catch (e) {
        attempts++;
        if (attempts == 2) {
          throw Exception("Download failed for \"${video.title}\".");
        }
      }
    }
  }

  // Modify function signature for Isolate.spawn
  Future<void> _downloadPlaylistInIsolate(
    List<Object> arguments,
  ) async {
    // Unpack arguments
    final List<Video> playlist = arguments[0] as List<Video>;
    final String savePath = arguments[1] as String;
    final bool audioOnly = arguments[2] as bool;
    final SendPort sendPort = arguments[3] as SendPort;

    int downloadProgress = 0;
    int totalVideos = playlist.length;

    for (int i = 0; i < totalVideos; i++) {
      final video = playlist[i];
      final fileName = "${i + 1} - ${video.title}";
      await _downloadVideo(video, fileName);
      downloadProgress = i + 1;
      sendPort.send({"progress": downloadProgress});
    }
    sendPort.send({"status": "complete"});
  }

  // Start download in the isolate
  void _startDownload() async {
    setState(() {
      hasStarted = true;
      isDownloading = true;
    });

    final receivePort = ReceivePort();
    // Pass the SendPort to the isolate
    await Isolate.spawn(
      _downloadPlaylistInIsolate,
      [
        widget.playlist, // List<Video>
        widget.savePath, // String
        widget.audioOnly, // bool
        receivePort.sendPort, // SendPort for communication
      ],
    );

    // Listen for updates from the isolate
    receivePort.listen((message) {
      if (message is Map) {
        if (message.containsKey('progress')) {
          setState(() {
            downloadProgress = message['progress'];
          });
        } else if (message.containsKey('status') &&
            message['status'] == 'complete') {
          setState(() {
            isDownloading = false;
            isComplete = true;
          });
        }
      }
    });
  }

  // Retry Dialog
  void _showRetryDialog(String step) {
    Get.defaultDialog(
      title: "Error during $step",
      content: const Padding(
        padding: EdgeInsets.all(14.0),
        child: Text("Would you like to retry the entire process?"),
      ),
      cancel: Buttons.text(
        text: "No",
        onTap: () => Get.offAll(() => const Yoink()),
      ),
      confirm: Buttons.elevated(text: "Yes", onTap: () => _startDownload),
    );
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
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!hasStarted)
              Center(
                child: Buttons.elevatedIcon(
                  text: "Start Download",
                  icon: Ionicons.ios_download_outline,
                  onTap: _startDownload,
                ),
              ),
            if (hasStarted) ...[
              if (!isComplete)
                _buildStepCard(
                  "Downloading Videos",
                  downloadProgress,
                  totalVideos,
                  isDownloading,
                ),
              if (isRenaming)
                _buildStepCard(
                  "Renaming Videos",
                  downloadProgress,
                  totalVideos,
                  isRenaming,
                ),
              if (isZipping)
                _buildStepCard(
                  "Zipping Videos",
                  downloadProgress,
                  totalVideos,
                  isZipping,
                ),
              if (isComplete) ...[
                const Center(
                  child: Icon(Ionicons.ios_checkbox, color: Colors.green),
                ),
                const SizedBox(height: 20.0),
                const Center(child: Text("Download Complete!")),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isComplete)
              Buttons.elevatedIcon(
                text: "Go Home",
                icon: Ionicons.ios_home_outline,
                onTap: () => Get.offAll(() => const Yoink()),
              ),
            if (hasError)
              Buttons.elevatedIcon(
                text: "Retry?",
                icon: Ionicons.ios_reload_outline,
                onTap: () => _startDownload(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String step, int progress, int total, bool isRunning) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            isRunning
                ? const CircularProgressIndicator()
                : const Icon(
                    Ionicons.ios_checkmark_circle,
                    color: Colors.green,
                  ),
            const SizedBox(width: 20),
            Text("$step: $progress / $total"),
          ],
        ),
      ),
    );
  }
}
