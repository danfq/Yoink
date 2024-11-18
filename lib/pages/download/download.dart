import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
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
  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _currentTaskNotifier =
      ValueNotifier<String>("Idle");

  bool isWorking = false;
  bool isComplete = false;

  int totalVideos = 0;

  @override
  void initState() {
    super.initState();
    totalVideos = widget.playlist.length;
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    _currentTaskNotifier.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      isWorking = true;
      isComplete = false;
    });

    try {
      final downloadedFiles = <File>[];

      // Step 1: Download Videos
      await _performTask(
        taskName: "Downloading Videos",
        total: widget.playlist.length,
        action: (index) async {
          final video = widget.playlist[index];
          final file =
              await _downloadVideo(video, "${index + 1} - ${video.title}");
          downloadedFiles.add(file);
        },
      );

      // Step 2: Rename Files
      await _performTask(
        taskName: "Renaming Videos",
        total: downloadedFiles.length,
        action: (index) async {
          final renamedFile = await _renameFile(
            downloadedFiles[index],
            "${index + 1} - ${widget.playlist[index].title}",
          );
          downloadedFiles[index] = renamedFile;
        },
      );

      // Step 3: ZIP Files
      await _zipVideos(downloadedFiles);

      // Mark as complete
      setState(() {
        isComplete = true;
      });
      _showToast("Success", "Download Complete!");
    } catch (e) {
      _showToast("Error", e.toString());
    } finally {
      setState(() {
        isWorking = false;
      });
    }
  }

  Future<void> _performTask({
    required String taskName,
    required int total,
    required Future<void> Function(int) action,
  }) async {
    _currentTaskNotifier.value = taskName;
    _progressNotifier.value = 0;

    for (int i = 0; i < total; i++) {
      await action(i);
      _progressNotifier.value = i + 1;
    }
  }

  Future<File> _downloadVideo(Video video, String fileName) async {
    final file = await API.downloadVideo(
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

  Future<File> _renameFile(File file, String newName) async {
    final String newPath =
        "${widget.savePath}/$newName.${widget.audioOnly ? "mp3" : "mp4"}";
    return compute(_renameFileIsolate, [file.path, newPath]);
  }

  static File _renameFileIsolate(List<String> args) {
    final File file = File(args[0]);
    final String newPath = args[1];
    final renamedFile = file.renameSync(newPath);
    return renamedFile;
  }

  Future<void> _zipVideos(List<File> files) async {
    _currentTaskNotifier.value = "Zipping Files";
    _progressNotifier.value = 0;

    final zipPath =
        "${widget.savePath}/playlist_${DateTime.now().millisecondsSinceEpoch}.zip";

    final receivePort = ReceivePort();
    await Isolate.spawn(
      _zipFilesInIsolate,
      [files.map((e) => e.path).toList(), zipPath, receivePort.sendPort],
    );

    final result = await receivePort.first;
    if (result is! String || result != "success") {
      throw Exception("Failed to zip files.");
    }

    for (final file in files) {
      await file.delete();
    }
  }

  static void _zipFilesInIsolate(List<dynamic> args) {
    final filePaths = args[0] as List<String>;
    final zipPath = args[1] as String;
    final sendPort = args[2] as SendPort;

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

  void _showToast(String title, String message) {
    Toast.show(
      title: title,
      message: message,
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
        child: ValueListenableBuilder<int>(
          valueListenable: _progressNotifier,
          builder: (context, progress, _) {
            return ValueListenableBuilder<String>(
              valueListenable: _currentTaskNotifier,
              builder: (context, currentTask, __) {
                return Column(
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
                              value: progress / totalVideos),
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
                              style: TextStyle(
                                  fontSize: 18.0, color: Colors.green),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
