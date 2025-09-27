import 'package:flutter/material.dart';

Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget child,
  // Color backgroundColor = Colors.white,
  EdgeInsets? insetPadding,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      return Dialog(
        // backgroundColor: backgroundColor,
        insetPadding: insetPadding,
        child: child,
      );
    },
  );
}
