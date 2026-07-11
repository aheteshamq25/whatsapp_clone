// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool isPlay = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.isInitialized
                ? _controller.value.aspectRatio
                : 16 / 9,
            child: Stack(
              children: [
                _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : const Center(child: CircularProgressIndicator()),
                IconButton(
                  onPressed: () {
                    if (isPlay) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                    setState(() {
                      isPlay != isPlay;
                    });
                  },
                  icon: Icon(isPlay ? Icons.pause_circle : Icons.play_circle),
                ),
              ],
            ),
          )
        : const CircularProgressIndicator();
  }
}
