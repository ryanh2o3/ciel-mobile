import 'package:meta/meta.dart';

@immutable
class SignupRequest {
  const SignupRequest({
    required this.handle,
    required this.email,
    required this.displayName,
    required this.password,
    required this.inviteCode,
    this.bio,
    this.avatarKey,
  });

  final String handle;
  final String email;
  final String displayName;
  final String? bio;
  final String? avatarKey;
  final String password;
  final String inviteCode;
}
