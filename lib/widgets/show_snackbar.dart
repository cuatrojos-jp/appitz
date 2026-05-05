import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context, 
  String message, {
  Color? color, 
  Color? textColor,
  SnackBarBehavior? behavior,
  }) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor ?? Colors.white),
        ),
      backgroundColor: color,
      behavior: behavior ?? SnackBarBehavior.fixed,
    ),
  );
}