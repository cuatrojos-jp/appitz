import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context, 
  String message, {
  Color? color, 
  Color? textColor,
  SnackBarBehavior? behavior,
  Duration? duration,
  }) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor ?? Colors.white),
        ),
      backgroundColor: color,
      behavior: behavior ?? SnackBarBehavior.fixed,
      duration: duration ?? Duration(seconds: 3),
    ),
  );
}