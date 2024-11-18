import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/pages/download/verify.dart';
import 'package:yoink/util/data/api.dart';
import 'package:yoink/util/handlers/toast.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/input.dart';
import 'package:yoink/util/handlers/anim.dart';

class FindVideos extends StatefulWidget {
  const FindVideos({super.key});

  @override
  State<FindVideos> createState() => _FindVideosState();
}

class _FindVideosState extends State<FindVideos> {
  /// Search Controller
  final TextEditingController _searchController = TextEditingController();

  /// Download Playlist
  final ValueNotifier<List<Video>> downloadPlaylist =
      ValueNotifier<List<Video>>([]);

  /// Query
  String query = "";

  @override
  void initState() {
    super.initState();
  }

  // Method to search videos by query
  Future<List<Video>> _searchVideos(String query) async {
    return await API.searchByQuery(query: query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Input Field
                Expanded(
                  child: Input(
                    controller: _searchController,
                    placeholder: "Search for something...",
                  ),
                ),

                // Search Button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Buttons.elevatedIcon(
                    text: "Search",
                    icon: Ionicons.ios_search_outline,
                    onTap: () {
                      setState(() {
                        query = _searchController.text.trim();
                      });
                    },
                  ),
                ),
              ],
            ),

            //Spacing
            const SizedBox(height: 20.0),

            //Results List
            if (query.isEmpty)
              //Nothing Searched Yet
              const Center(
                child: Text(
                  "Search Results Will Appear Here",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
                ),
              )
            else
              FutureBuilder<List<Video>>(
                future: _searchVideos(query),
                builder: (context, snapshot) {
                  // Check Connection State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Loading
                    return Center(
                      child: Column(
                        children: [
                          AnimHandler.asset(animation: "loading"),
                          const Text("Searching..."),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    // Error
                    return Center(
                      child: Text("Error: \"${snapshot.error}\""),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // Empty state
                    return Center(
                      child: AnimHandler.asset(animation: "empty"),
                    );
                  } else {
                    // Videos
                    final videos = snapshot.data!;

                    // Results List
                    return Expanded(
                      child: ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          // Video
                          final video = videos[index];

                          return Video(
                            id: video.id,
                            title: video.title,
                            thumb: video.thumb,
                            channel: video.channel,
                            duration: video.duration,
                            releaseDate: video.releaseDate,
                            onAdded: (video) {
                              // Check if Video is Already Present
                              if (!downloadPlaylist.value.contains(video)) {
                                // Add Video to Playlist without triggering setState
                                downloadPlaylist.value =
                                    List.from(downloadPlaylist.value)
                                      ..add(video);

                                // Notify User
                                Toast.show(
                                  title: "Done!",
                                  message: "\"${video.title}\" Added!",
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),

      // Floating Action Button - Verify Playlist
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: ValueListenableBuilder<List<Video>>(
        valueListenable: downloadPlaylist,
        builder: (context, playlist, child) {
          return playlist.isNotEmpty
              ? FloatingActionButton(
                  backgroundColor: Theme.of(context).dialogBackgroundColor,
                  child: Icon(
                    Ionicons.ios_download_outline,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    // Check Download Playlist
                    if (downloadPlaylist.value.isEmpty) {
                      return;
                    }

                    // Go to VerifyPlaylist
                    Get.to(
                      () => VerifyPlaylist(
                        videos: downloadPlaylist.value,
                        showSave: true,
                      ),
                    );
                  },
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}
