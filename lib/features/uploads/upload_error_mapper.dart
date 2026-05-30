import 'dart:io';

import 'package:ciel_mobile/core/errors/app_exception.dart';

/// Maps a thrown error from the upload pipeline into a short, user-visible
/// message. Anything we don't recognise falls back to a generic line —
/// we never show a raw [Exception.toString] to the user.
String friendlyUploadError(Object error) {
  if (error is SocketException || error is HttpException) {
    return "Couldn't reach PicShare. Check your connection and try again.";
  }
  if (error is StateError) {
    final msg = error.message.toLowerCase();
    if (msg.contains('timeout')) {
      return 'Processing is taking longer than expected. '
          'Try again in a moment.';
    }
    if (msg.contains('failed')) {
      return "We couldn't process that photo. Try a different one.";
    }
  }
  if (error is AppException) {
    final m = error.message.toLowerCase();
    if (m.contains('unauthorized')) {
      return 'Your session expired. Sign in again to share.';
    }
    if (m.contains('upload failed')) {
      return 'Upload failed. Check your connection and try again.';
    }
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}
