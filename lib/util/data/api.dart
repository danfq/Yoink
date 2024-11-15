import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/route_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yoink/pages/download/download.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:yoink/util/models/video.dart';

///API
class API {
  ///YouTube Client
  static final yt.YoutubeExplode _youtube = yt.YoutubeExplode();

  ///Search by Query
  static Future<List<Video>> searchByQuery({required String query}) async {
    //Videos
    List<Video> videos = [];

    //Video Search List
    final videoSearchList = await _youtube.search.search(query);

    //Check Search List
    if (videoSearchList.isNotEmpty) {
      //Parse Videos
      for (final videoItem in videoSearchList) {
        //Video
        final video = Video(
          id: videoItem.id.value,
          title: videoItem.title,
          thumb: videoItem.thumbnails.highResUrl,
          channel: videoItem.author,
          duration: videoItem.duration ?? Duration.zero,
          releaseDate: videoItem.uploadDate,
        );

        //Add Valid Videos to List
        if (video.duration != Duration.zero) {
          videos.add(video);
        }
      }
    }

    //Return Videos
    return videos;
  }

  ///Download Playlist
  static Future<void> downloadPlaylist({
    required List<Video> playlist,
    required bool audioOnly,
  }) async {
    //Request Storage Permission - Mobile Only
    if (Platform.isAndroid && Platform.isIOS) {
      //Status
      final storageStatus = await Permission.storage.request();

      //Check Permission
      if (!storageStatus.isGranted) {
        Toast.show(title: "Oops!", message: "Storage Permission is Required");
        return;
      }
    }

    //Get Directory to Save Playlist
    String? dirPath = await FilePicker.platform.getDirectoryPath();

    //Check Directory
    if (dirPath == null) {
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

  ///Download Video
  static Future<File?> downloadVideo({
    required String videoID,
    required bool audioOnly,
  }) async {}
}
