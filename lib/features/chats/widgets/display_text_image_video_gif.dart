// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:whatsapp_clone/commons/enum/message_enum.dart';
import 'package:whatsapp_clone/features/chats/widgets/video_player_item.dart';

class DisplayTextImageVideoGif extends StatelessWidget {
  final String message;
  final MessageEnum type;
  const DisplayTextImageVideoGif({
    Key? key,
    required this.message,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return type == MessageEnum.text
        ? Text(message, style: const TextStyle(fontSize: 16))
        : type == MessageEnum.video
        ? VideoPlayerItem(videoUrl: message)
        : CachedNetworkImage(imageUrl: message);
  }
}
