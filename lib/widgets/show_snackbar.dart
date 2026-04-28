import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, {Color? color, SnackBarBehavior? behavior}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: behavior ?? SnackBarBehavior.fixed,
    ),
  );
}