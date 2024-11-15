import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/util/data/api.dart';
import 'package:yoink/util/handlers/anim.dart';
import 'package:yoink/util/models/video.dart';
import 'package:yoink/util/widgets/buttons.dart';
import 'package:yoink/util/widgets/main.dart';

class VerifyPlaylist extends StatefulWidget {
  const VerifyPlaylist({super.key, required this.videos});

  ///Videos
  final List<Video> videos;

  @override
  State<VerifyPlaylist> createState() => _VerifyPlaylistState();
}

class _VerifyPlaylistState extends State<VerifyPlaylist> {
  ///Videos
  final List<Video> _videos = [];

  ///Audio Only
  bool _audioOnly = false;

  @override
  void initState() {
    super.initState();
    _videos.addAll(widget.videos);
  }

  ///Remove Video
  void _removeVideo(int index) {
    setState(() {
      _videos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        centerTitle: false,
        title: const Text("Verify Playlist"),
        onBack: () {
          //Confirmation Dialog
          Get.defaultDialog(
            contentPadding: const EdgeInsets.all(20.0),
            title: "Are you sure?",
            content: const Text(
              "Changes you've made to this Playlist WON'T BE SAVED.",
            ),
            cancel: Buttons.text(
              text: "No",
              onTap: () => Get.back(),
            ),
            confirm: Buttons.elevated(
              text: "Yes",
              onTap: () {
                //Close Dialog
                Get.back();

                //Go Back
                Get.back();
              },
            ),
          );
        },
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Row(
              children: [
                //Checkbox
                Checkbox.adaptive(
                  value: _audioOnly,
                  onChanged: (status) {
                    setState(() {
                      _audioOnly = status ?? false;
                    });
                  },
                ),

                //Label
                const Text("Audio Only"),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: widget.videos.isNotEmpty
            ? ReorderableListView.builder(
                itemCount: _videos.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final video = _videos.removeAt(oldIndex);
                    _videos.insert(newIndex, video);
                  });
                },
                itemBuilder: (context, index) {
                  // Video
                  final video = _videos[index];

                  return Dismissible(
                    key: ValueKey(video.id),
                    direction: DismissDirection.none,
                    background: Container(
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Ionicons.ios_reorder_three),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Video(
                              id: video.id,
                              title: video.title,
                              thumb: video.thumb,
                              channel: video.channel,
                              duration: video.duration,
                              releaseDate: video.releaseDate,
                              enableRemove: true,
                              onRemoved: () {
                                _removeVideo(index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Center(child: AnimHandler.asset(animation: "empty")),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Buttons.elevatedIcon(
          text: "Download Playlist",
          icon: Ionicons.ios_download_outline,
          onTap: () {
            //Confirmation Dialog
            Get.defaultDialog(
              contentPadding: const EdgeInsets.all(20.0),
              title: "Are you sure?",
              content: const Text(
                "From this point on, you won't be able to edit your Playlist.",
                textAlign: TextAlign.center,
              ),
              cancel: Buttons.text(
                text: "No",
                onTap: () => Get.back(),
              ),
              confirm: Buttons.elevated(
                text: "Yes",
                onTap: () async {
                  //Initiate Download Procedure
                  await API.downloadPlaylist(
                    playlist: _videos,
                    audioOnly: _audioOnly,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
