import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:yoink/util/widgets/buttons.dart';

///Video Widget
class Video extends StatelessWidget {
  ///ID
  final String id;

  ///Title
  final String title;

  ///Thumbnail URL
  final String thumb;

  ///Channel
  final String channel;

  ///Duration
  final Duration duration;

  ///Release Date
  final DateTime? releaseDate;

  ///On Added
  final Function(Video video)? onAdded;

  ///Remove from List
  final bool? enableRemove;

  ///On Removed
  final VoidCallback? onRemoved;

  ///Show Action Button
  final bool? showActionButton;

  ///Video
  const Video({
    super.key,
    required this.id,
    required this.title,
    required this.thumb,
    required this.channel,
    required this.duration,
    required this.releaseDate,
    this.onAdded,
    this.enableRemove,
    this.onRemoved,
    this.showActionButton = true,
  });

  ///`Video` to JSON Object
  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "title": title,
      "thumb": thumb,
      "channel": channel,
      "duration": duration.inSeconds,
      "release_date": releaseDate?.toIso8601String(),
    };
  }

  ///JSON Object to `Video`
  factory Video.fromJSON(Map<dynamic, dynamic> json) {
    return Video(
      id: json["id"],
      title: json["title"],
      thumb: json["thumb"],
      channel: json["channel"],
      duration: Duration(seconds: json["duration"]),
      releaseDate: DateTime.tryParse(json["release_date"] ?? ""),
    );
  }

  //UI
  @override
  Widget build(BuildContext context) {
    final formattedDuration = "${duration.inHours.toString().padLeft(2, "0")}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, "0")}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, "0")}";

    final formattedRelease = releaseDate != null
        ? "${releaseDate?.day}-${releaseDate?.month}-${releaseDate?.year}"
        : "No date";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        child: Row(
          children: [
            // Thumbnail
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: SizedBox(
                  width: 120,
                  child: Image.network(
                    thumb,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text("$formattedDuration | $formattedRelease"),
                  trailing: showActionButton == true
                      ? Buttons.iconFilled(
                          icon: enableRemove == true
                              ? Ionicons.ios_trash_outline
                              : Ionicons.ios_add_outline,
                          onTap: () => _handleAction(context),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context) {
    if (enableRemove == true) {
      _showRemoveDialog();
    } else {
      _showAddDialog();
    }
  }

  void _showRemoveDialog() {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(20.0),
      title: "Remove Video?",
      content: const Text("Are you sure you want to remove this Video?"),
      cancel: Buttons.text(
        text: "No",
        onTap: () => Get.back(),
      ),
      confirm: Buttons.elevated(
        text: "Yes",
        onTap: () {
          if (onRemoved != null) onRemoved!();
          Get.back();
        },
      ),
    );
  }

  void _showAddDialog() {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(20.0),
      title: "Add Video?",
      content: const Text(
        "Would you like to add this Video to your Download Playlist?",
      ),
      cancel: Buttons.text(
        text: "No",
        onTap: () => Get.back(),
      ),
      confirm: Buttons.elevated(
        text: "Yes",
        onTap: () {
          if (onAdded != null) onAdded!(this);
          Get.back();
        },
      ),
    );
  }
}
