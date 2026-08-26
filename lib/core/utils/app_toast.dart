import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum AppToastType { success, error, info }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
}) {
  final toastType = type == AppToastType.success
      ? ToastificationType.success
      : type == AppToastType.error
          ? ToastificationType.error
          : ToastificationType.info;

  toastification.show(
    context: context,
    title: Text(message),
    autoCloseDuration: const Duration(seconds: 3),
    type: toastType,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.topCenter,
    showProgressBar: false,
  );
}
