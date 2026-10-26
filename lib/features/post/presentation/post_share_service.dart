import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Presents the platform share sheet for a post without coupling widgets to
/// the platform plugin.
abstract final class PostShareService {
  static Future<void> share(
    Post post, {
    Rect? sharePositionOrigin,
  }) async {
    final author = post.ownerHandle == null ? 'Ciel' : '@${post.ownerHandle}';
    final caption = post.caption?.trim();
    final message = StringBuffer('A photo from $author on Ciel');
    if (caption != null && caption.isNotEmpty) {
      message
        ..write('\n\n')
        ..write(caption);
    }
    message
      ..write('\n\nPost ID: ')
      ..write(post.id);

    await SharePlus.instance.share(
      ShareParams(
        text: message.toString(),
        title: 'Share post',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static Rect? originFrom(BuildContext context) {
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }
}
