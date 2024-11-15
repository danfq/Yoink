import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/util/data/api.dart';
import 'package:yoink/util/handlers/anim.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/main.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  ///Download Playlist
  List<Video> downloadPlaylist = [];

  //Query
  String query = "";

  @override
  void initState() {
    super.initState();

    //Query
    query = Get.parameters["query"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: const Text("Search"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Buttons.elevatedIcon(
              text: "Verify Playlist",
              icon: Ionicons.ios_download_outline,
              onTap: () {
                if (downloadPlaylist.isEmpty) {
                  return;
                }

                // Mobile
                if (Platform.isAndroid || Platform.isIOS) {
                  showModalBottomSheet(
                    showDragHandle: true,
                    context: context,
                    builder: (context) {
                      return SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            // Title
                            const Text(
                              "Verify Playlist",
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // List of Videos
                            Expanded(
                              child: ListView.builder(
                                itemCount: downloadPlaylist.length,
                                itemBuilder: (context, index) {
                                  final video = downloadPlaylist[index];

                                  // Return Video
                                  return video;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  // Pass the playlist to the next page
                  Get.toNamed("/verify", parameters: {
                    "list": downloadPlaylist
                        .map((video) => video.toJSON().toString())
                        .toList()
                        .toString(),
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Center(
              child: Text(
                "Results for: \"$query\"",
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Spacing
            const SizedBox(height: 40.0),

            // Results List
            FutureBuilder(
              future: API.searchByQuery(query: query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final videos = snapshot.data;

                  if (videos != null && videos.isNotEmpty) {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];

                          return Video(
                            id: video.id,
                            title: video.title,
                            thumb: video.thumb,
                            channel: video.channel,
                            duration: video.duration,
                            releaseDate: video.releaseDate,
                            onAdded: (video) {
                              if (!downloadPlaylist.contains(video)) {
                                downloadPlaylist.add(video);
                                Toast.show(
                                  title: "Done!",
                                  message: "Video Added to Download Playlist!",
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  } else {
                    return Center(
                      child: AnimHandler.asset(animation: "empty"),
                    );
                  }
                } else {
                  return Center(
                    child: Column(
                      children: [
                        AnimHandler.asset(animation: "loading"),
                        const Text("Loading Results..."),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
