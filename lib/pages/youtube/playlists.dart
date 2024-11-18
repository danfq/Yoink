import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/pages/download/download.dart';
import 'package:yoink/pages/download/verify.dart';
import 'package:yoink/util/data/local.dart';
import 'package:yoink/util/handlers/anim.dart';
import 'package:yoink/util/models/playlist.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/widgets/buttons.dart';

class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  final List<Playlist> playlists =
      (LocalData.boxData(box: "playlists").entries.isNotEmpty
          ? (LocalData.boxData(box: "playlists").entries)
              .map(
                (entry) => Playlist(
                  id: entry.key,
                  name: entry.key,
                  videos: (entry.value["videos"] as List<dynamic>?)
                          ?.map((video) =>
                              Video.fromJSON(video as Map<dynamic, dynamic>))
                          .toList() ??
                      [],
                ),
              )
              .toList()
          : []);

  // Track expanded state for each playlist
  final Map<String, bool> expandedState = {};

  @override
  void initState() {
    super.initState();
    // Initialize all playlists as collapsed
    for (var playlist in playlists) {
      expandedState[playlist.id] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return playlists.isNotEmpty
        ? ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              // Playlist
              final Playlist playlist = playlists[index];

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildExpandableTile(playlist),
              );
            },
          )
        : Center(
            child: AnimHandler.asset(animation: "empty"),
          );
  }

  /// Builds an expandable tile for a playlist
  Widget _buildExpandableTile(Playlist playlist) {
    final bool isExpanded = expandedState[playlist.id] ?? false;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: Column(
        children: [
          Row(
            children: [
              //Playlist
              Expanded(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  title: Text(
                    playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.25 : 0.0,
                    child: const Icon(Ionicons.ios_chevron_forward),
                  ),
                  onTap: () {
                    setState(() {
                      expandedState[playlist.id] = !isExpanded;
                    });
                  },
                ),
              ),

              //Remove Playlist
              Buttons.iconFilled(
                icon: Ionicons.ios_trash_outline,
                onTap: () {},
              ),
            ],
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Buttons.elevatedIcon(
                      text: "Download",
                      icon: Ionicons.ios_download_outline,
                      onTap: () {
                        _downloadPlaylist(playlist);
                      }),
                  const SizedBox(height: 10.0),
                  ...playlist.videos.map(
                    (video) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Video(
                            id: video.id,
                            title: video.title,
                            thumb: video.thumb,
                            channel: video.channel,
                            duration: video.duration,
                            releaseDate: video.releaseDate,
                            showActionButton: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  ///Download Playlist
  void _downloadPlaylist(Playlist playlist) {
    Get.to(() => VerifyPlaylist(videos: playlist.videos, showSave: false));
  }
}
