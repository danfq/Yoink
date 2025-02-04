import 'dart:io';
import 'package:flutter/cupertino.dart';

///FFmpeg Handler
class FFmpegHandler {
  ///Download Stream
  static Future<File> downloadVideoWithAudio(
    String hlsUrl,
    String outputFilePath,
  ) async {
    try {
      //FFmpeg Command
      final command = ["ffmpeg", "-i", hlsUrl, "-c", "copy", outputFilePath];

      //Run FFmpeg Command
      final result = await Process.run(command[0], command.sublist(1));

      //Check Status
      if (result.exitCode == 0) {
        //Debug
        debugPrint("[WINDOWS] Stream Downloaded Successfully: $outputFilePath");

        //Return Output File
        return File(outputFilePath);
      } else {
        throw Exception(
          "[WINDOWS] FFmpeg Failed with Code: ${result.exitCode}\n${result.stderr}",
        );
      }
    } catch (error) {
      // Debug
      debugPrint("[WINDOWS] Error Downloading Stream: $error");

      // Exception
      throw Exception("[WINDOWS] Error During Stream Download: $error");
    }
  }

  ///Combine Video & Audio
  static Future<File> combineVideoAndAudio({
    required File videoFile,
    required File audioFile,
    required Directory tempDir,
  }) async {
    try {
      // Check Video & Audio Files
      if (!videoFile.existsSync()) {
        throw Exception(
          "[WINDOWS] Video File does not exist at ${videoFile.path}",
        );
      }
      if (!audioFile.existsSync()) {
        throw Exception(
          "[WINDOWS] Audio File does not exist at ${audioFile.path}",
        );
      }

      // Output File
      final outputFile = File(
        "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_output.mp4",
      );

      final command = [
        "ffmpeg",
        "-i",
        videoFile.path,
        "-i",
        audioFile.path,
        "-c:v",
        "copy",
        "-c:a",
        "aac",
        outputFile.path,
      ];
      final result = await Process.run(command[0], command.sublist(1));

      if (result.exitCode == 0) {
        //Debug
        debugPrint(
            "[WINDOWS] Video and Audio Combined Successfully: ${outputFile.path}");

        //Return Output File
        return outputFile;
      } else {
        throw Exception(
          "[WINDOWS] FFmpeg Failed with Code: ${result.exitCode}\n${result.stderr}",
        );
      }
    } catch (error) {
      //Debug
      debugPrint(error.toString());

      //Exception
      throw Exception("[WINDOWS] Error During Video/Audio Combination: $error");
    }
  }
}
