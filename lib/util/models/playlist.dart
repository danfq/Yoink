import 'package:yoink/util/models/video.dart';

///Playlist
class Playlist {
  ///ID
  final String id;

  ///Name
  final String name;

  ///Videos
  final List<Video> videos;

  ///Playlist
  Playlist({required this.id, required this.name, required this.videos});

  ///JSON Object to `Playlist`
  factory Playlist.fromJSON(Map<String, dynamic> json) {
    return Playlist(
      id: json["id"] as String,
      name: json["name"] as String,
      videos: (json["videos"] as List<dynamic>)
          .map((video) => Video.fromJSON(video as Map<String, dynamic>))
          .toList(),
    );
  }

  ///`Playlist` to JSON Object
  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "name": name,
      "videos": videos.map((video) => video.toJSON()).toList(),
    };
  }
}
