Map<String, dynamic> updateProfileRequestJson({
  String? displayName,
  String? bio,
  String? avatarKey,
}) {
  return {
    'display_name': ?displayName,
    'bio': ?bio,
    'avatar_key': ?avatarKey,
  };
}

Map<String, dynamic> createPostRequestJson({
  required List<String> mediaIds,
  String? caption,
}) {
  return {
    'media_ids': mediaIds,
    'caption': ?caption,
  };
}

Map<String, dynamic> updatePostRequestJson({String? caption}) {
  return {'caption': ?caption};
}

Map<String, dynamic> createCommentRequestJson({required String body}) {
  return {'body': body};
}

Map<String, dynamic> createStoryRequestJson({
  required String mediaId,
  required String visibility, String? caption,
}) {
  return {
    'media_id': mediaId,
    'caption': ?caption,
    'visibility': visibility,
  };
}

Map<String, dynamic> addStoryReactionRequestJson({required String emoji}) {
  return {'emoji': emoji};
}

Map<String, dynamic> signupRequestJson({
  required String handle,
  required String email,
  required String displayName,
  required String password,
  required String inviteCode,
  String? bio,
  String? avatarKey,
}) {
  return {
    'handle': handle,
    'email': email,
    'display_name': displayName,
    'password': password,
    'invite_code': inviteCode,
    'bio': ?bio,
    'avatar_key': ?avatarKey,
  };
}

Map<String, dynamic> createInviteRequestJson({required int daysValid}) {
  return {'days_valid': daysValid};
}

Map<String, dynamic> deviceRegisterRequestJson({required String fingerprint}) {
  return {'fingerprint': fingerprint};
}
