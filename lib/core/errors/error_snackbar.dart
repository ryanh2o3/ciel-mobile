import 'package:ciel_mobile/core/errors/app_failure_mapper.dart';
import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, Object error) {
  final message = mapToFailure(error).userMessage;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
